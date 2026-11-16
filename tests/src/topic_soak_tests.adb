--  Multi-task sustained soak test for Beacon.Topic (Task 3.3). Owner:
--  validation engineer.
--
--  Task 3.2 covers Beacon.Queue in a single task. This suite puts the
--  protected wrapper in Beacon.Topic under real contention: one publisher
--  task, several subscriber tasks and a monitor task per scenario, with
--  two scenarios running at the same time in the second phase.
--
--  Scenarios (each one is a fresh instantiation of Beacon.Topic):
--
--    paced      1 kHz Publish for N seconds (default 10). Four consumers:
--               a fast and a stalling Reliable subscriber, a fast and a
--               stalling Best_Effort subscriber. The Reliable stall is
--               shorter than the queue can absorb at 1 kHz, the
--               Best_Effort stall is longer, so it must drop.
--    flood      Unpaced Publish, M messages (default 1,000,000), same four
--               consumers. The stalling Reliable subscriber fills its
--               queue, so Publish must block and resume.
--    try_flood  Unpaced Try_Publish, M messages, one stalling Reliable
--               and one fast Best_Effort subscriber. Refusals are counted.
--
--  Phase 1 runs paced alone, so its timing figures are clean. Phase 2
--  runs flood and try_flood at the same time (two publisher tasks).
--
--  Checked for every subscriber, after the run:
--
--    S1  Dropped (Reliable) = 0. Always (design rule 2).
--    S2  Reliable: every sequence number arrives, once, in order. In
--        try_flood the only gaps are the messages Try_Publish reported
--        as refused, and the gap total equals the refusal count.
--    S3  Best_Effort: arrivals are strictly increasing, the gap total
--        equals Dropped, and Received + Dropped = Published.
--    S4  No message is corrupted (each one carries a checksum of its
--        sequence number).
--    S5  Every subscriber receives the end marker and ends with an empty
--        queue. A watchdog fails the run if anything deadlocks.
--    S6  Coverage: the run really reached the paths under test (the
--        Reliable queue was seen full, Best_Effort dropped, Try_Publish
--        was refused, paced published exactly Rate x Seconds).
--    S7  Memory: resident set size does not grow during the paced soak
--        (Linux only, read from /proc/self/statm; reported n/a elsewhere).
--
--  Timing (publisher release lateness, publish-to-receive latency, CPU
--  use) is reported but not gated: a desktop OS gives no deadline
--  guarantee, and a timing gate would make CI flaky.
--
--     topic_soak_tests [paced_seconds [flood_messages]]

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Execution_Time;
with Ada.Real_Time;  use Ada.Real_Time;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Beacon;         use Beacon;
with Beacon.Topic;
with GNAT.OS_Lib;
with Interfaces;     use Interfaces;

procedure Topic_Soak_Tests is

   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   use type Ada.Execution_Time.CPU_Time;

   Default_Seconds : constant := 10;
   Default_Flood   : constant := 1_000_000;
   Rate_Hz         : constant := 1_000;
   Depth           : constant := 8;
   Page_Bytes      : constant := 4_096;   --  x86-64 Linux page size
   Max_RSS_Growth  : constant := 1_048_576;

   Period : constant Time_Span := Microseconds (1_000_000 / Rate_Hz);

   ---------------------------------------------------------------------
   --  Messages
   ---------------------------------------------------------------------

   type Sample is record
      Seq   : Natural;       --  1-based publish order; the end marker is last
      Check : Unsigned_32;   --  Signature (Seq): catches a torn or stale copy
      Sent  : Time;
      Last  : Boolean;
   end record;

   function Signature (Seq : Natural) return Unsigned_32 is
     ((Unsigned_32 (Seq) * 2_654_435_761) xor 16#5A5A_5A5A#);

   function Make (Seq : Natural; Last : Boolean := False) return Sample is
     ((Seq => Seq, Check => Signature (Seq), Sent => Clock, Last => Last));

   ---------------------------------------------------------------------
   --  Timing statistics (fixed size, no heap)
   ---------------------------------------------------------------------

   --  Bucket K counts values below 2**K microseconds (and at least
   --  2**(K-1)). Percentiles are reported as that upper bound.
   type Histogram is array (0 .. 31) of Natural;

   type Stats is record
      N    : Natural  := 0;
      Sum  : Duration := 0.0;
      Max  : Duration := 0.0;
      Hist : Histogram := [others => 0];
   end record;

   procedure Add (S : in out Stats; D : Time_Span);
   procedure Add (S : in out Stats; D : Time_Span) is
      V  : constant Duration := Duration'Max (0.0, To_Duration (D));
      Us : constant Long_Long_Integer := Long_Long_Integer (Float (V) * 1.0e6);
      K  : Natural := 0;
   begin
      while K < Histogram'Last and then 2 ** K <= Us loop
         K := K + 1;
      end loop;
      S.N := S.N + 1;
      S.Sum := S.Sum + V;
      S.Max := Duration'Max (S.Max, V);
      S.Hist (K) := S.Hist (K) + 1;
   end Add;

   function Img (N : Long_Long_Integer) return String is
     (Ada.Strings.Fixed.Trim (N'Image, Ada.Strings.Left));

   function Img (N : Natural) return String is (Img (Long_Long_Integer (N)));

   function Us (D : Duration) return String is
     (Img (Long_Long_Integer (Float (D) * 1.0e6)) & " us");

   --  Upper bound of the bucket holding the P-th percentile.
   function Percentile_Bound (S : Stats; P : Float) return String;
   function Percentile_Bound (S : Stats; P : Float) return String is
      Needed : constant Natural := Natural (Float'Ceiling (Float (S.N) * P));
      Cum    : Natural := 0;
   begin
      for K in Histogram'Range loop
         Cum := Cum + S.Hist (K);
         if Cum >= Needed then
            return "<" & Img (Long_Long_Integer'(2 ** K)) & " us";
         end if;
      end loop;
      return "n/a";
   end Percentile_Bound;

   function Summary (S : Stats) return String is
     (if S.N = 0 then "n/a"
      else "mean " & Us (S.Sum / S.N) & ", p99 " & Percentile_Bound (S, 0.99)
           & ", max " & Us (S.Max));

   ---------------------------------------------------------------------
   --  Process memory (Linux only)
   ---------------------------------------------------------------------

   --  Resident set size in bytes, or -1 where /proc is not available.
   function Resident_Bytes return Long_Long_Integer;
   function Resident_Bytes return Long_Long_Integer is
      use Ada.Text_IO;
      F    : File_Type;
      Line : String (1 .. 256);
      Last : Natural;
      Sp   : Natural;
   begin
      Open (F, In_File, "/proc/self/statm");
      Get_Line (F, Line, Last);
      Close (F);
      --  Fields: size resident shared text lib data dt (in pages).
      Sp := Ada.Strings.Fixed.Index (Line (1 .. Last), " ");
      return Long_Long_Integer'Value
        (Line (Sp + 1 .. Ada.Strings.Fixed.Index (Line (Sp + 1 .. Last), " ") - 1))
        * Page_Bytes;
   exception
      when others =>
         if Is_Open (F) then
            Close (F);
         end if;
         return -1;
   end Resident_Bytes;

   ---------------------------------------------------------------------
   --  Console lock: two scenarios report at the same time in phase 2.
   ---------------------------------------------------------------------

   protected Console is
      entry Acquire;
      procedure Release;
   private
      Busy : Boolean := False;
   end Console;

   protected body Console is
      entry Acquire when not Busy is
      begin
         Busy := True;
      end Acquire;

      procedure Release is
      begin
         Busy := False;
      end Release;
   end Console;

   ---------------------------------------------------------------------
   --  Watchdog: a deadlock must fail the run, not hang CI.
   ---------------------------------------------------------------------

   task Watchdog is
      entry Arm (Limit : Duration);
      entry Disarm;
   end Watchdog;

   task body Watchdog is
      Deadline : Duration := 0.0;
   begin
      select
         accept Arm (Limit : Duration) do
            Deadline := Limit;
         end Arm;
      or
         terminate;
      end select;
      select
         accept Disarm;
      or
         delay Deadline;
         Put_Line ("  FAIL  watchdog: not finished after" & Integer (Deadline)'Image
                   & " s (deadlock or livelock suspected)");
         GNAT.OS_Lib.OS_Exit (1);
      end select;
   end Watchdog;

   ---------------------------------------------------------------------
   --  One scenario
   ---------------------------------------------------------------------

   type Scenario_Kind is (Paced, Flood, Try_Flood);
   type Role is (Rel_Fast, Rel_Stall, BE_Fast, BE_Stall);

   procedure Run_Scenario
     (Kind     : Scenario_Kind;
      Seconds  : Positive;
      Messages : Positive;
      Failures : out Natural);

   procedure Run_Scenario
     (Kind     : Scenario_Kind;
      Seconds  : Positive;
      Messages : Positive;
      Failures : out Natural)
   is
      package T is new Beacon.Topic
        (Message_Type => Sample, Queue_Depth => Depth, Max_Subscribers => 4);

      function Is_Active (R : Role) return Boolean is
        (Kind /= Try_Flood or else R in Rel_Stall | BE_Fast);

      function Is_Reliable (R : Role) return Boolean is (R in Rel_Fast | Rel_Stall);

      --  How often a stalling consumer pauses (in messages) and for how
      --  long. Paced: the Reliable stall (5 ms) fits in Depth periods
      --  (8 ms), the Best_Effort stall (20 ms) does not.
      function Stall_Every (R : Role) return Natural is
        (if R not in Rel_Stall | BE_Stall then 0
         elsif Kind = Paced then 100
         else 5_000);

      function Stall_For (R : Role) return Duration is
        (if Kind /= Paced then 0.001
         elsif R = Rel_Stall then 0.005
         else 0.020);

      type Sub_Result is record
         Received  : Natural  := 0;
         Missing   : Natural  := 0;   --  total size of sequence gaps
         Disorder  : Natural  := 0;   --  arrivals not after the previous one
         Corrupt   : Natural  := 0;
         Saw_Full  : Natural  := 0;   --  queue seen at Depth after a stall
         Dropped   : Natural  := 0;
         Pending   : Natural  := 0;   --  left in the queue at the end
         Sentinel  : Boolean  := False;
         Crashed   : Boolean  := False;
         Latency   : Stats;
         CPU       : Duration := 0.0;
      end record;

      Results : array (Role) of Sub_Result;

      --  Written by the producer and monitor; read after they terminate.
      Published   : Natural  := 0;
      Refused     : Natural  := 0;
      Overruns    : Natural  := 0;
      Lateness    : Stats;
      Prod_CPU    : Duration := 0.0;
      Mon_CPU     : Duration := 0.0;
      Prod_Crash  : Boolean  := False;
      Started     : Time     := Clock;
      Finished    : Time     := Clock;
      Max_Pending : array (Role) of Natural := [others => 0];
      RSS_First   : Long_Long_Integer := -1;
      RSS_Max     : Long_Long_Integer := -1;
      Done        : Boolean := False with Atomic;

      Pub     : T.Publisher;
      Rel_F_S : aliased T.Subscriber (Reliable);
      Rel_S_S : aliased T.Subscriber (Reliable);
      BE_F_S  : aliased T.Subscriber (Best_Effort);
      BE_S_S  : aliased T.Subscriber (Best_Effort);

      type Sub_Ptr is access all T.Subscriber;
      Subs : constant array (Role) of Sub_Ptr :=
        [Rel_Fast  => Rel_F_S'Unchecked_Access,
         Rel_Stall => Rel_S_S'Unchecked_Access,
         BE_Fast   => BE_F_S'Unchecked_Access,
         BE_Stall  => BE_S_S'Unchecked_Access];

      Count : Natural := 0;   --  local failure counter

      procedure Check (Cond : Boolean; Name : String);
      procedure Check (Cond : Boolean; Name : String) is
      begin
         if Cond then
            Put_Line ("  ok    " & Name);
         else
            Put_Line ("  FAIL  " & Name);
            Count := Count + 1;
         end if;
      end Check;

      procedure Report;
      procedure Report is
         Wall  : constant Duration := To_Duration (Finished - Started);
         CPU   : Duration := Prod_CPU + Mon_CPU;
         Label : constant String :=
           (case Kind is
              when Paced     => "paced: Publish at" & Rate_Hz'Image & " Hz for"
                                & Seconds'Image & " s",
              when Flood     => "flood: unpaced Publish," & Messages'Image & " messages",
              when Try_Flood => "try_flood: unpaced Try_Publish," & Messages'Image
                                & " messages");
      begin
         for R in Role loop
            CPU := CPU + Results (R).CPU;
         end loop;

         Put_Line ("");
         Put_Line ("[" & Label & "]");
         Put_Line ("  published " & Img (Published)
                   & (if Kind = Try_Flood then ", refused " & Img (Refused) else "")
                   & ", wall " & Us (Wall)
                   & ", CPU " & Us (CPU)
                   & (if Wall > 0.0
                      then " (" & Img (Long_Long_Integer (100.0 * Float (CPU) / Float (Wall)))
                           & "% of one core)"
                      else ""));
         if Kind = Paced then
            Put_Line ("  release lateness: " & Summary (Lateness)
                      & ", overruns (> 1 period) " & Img (Overruns));
            Put_Line ("  resident memory: "
                      & (if RSS_First < 0 then "n/a on this OS"
                         else Img (RSS_First / 1024) & " KiB after warm-up, max "
                              & Img (RSS_Max / 1024) & " KiB"));
         end if;

         for R in Role loop
            if Is_Active (R) then
               declare
                  X : Sub_Result renames Results (R);
               begin
                  Put_Line ("  " & R'Image & ": recv " & Img (X.Received)
                            & ", dropped " & Img (X.Dropped)
                            & ", missing " & Img (X.Missing)
                            & ", max pending " & Img (Max_Pending (R))
                            & ", seen full " & Img (X.Saw_Full));
                  Put_Line ("      latency " & Summary (X.Latency));
               end;
            end if;
         end loop;

         --  Correctness checks (S1-S5).
         Check (not Prod_Crash, "publisher task ran to completion");
         for R in Role loop
            if Is_Active (R) then
               declare
                  X    : Sub_Result renames Results (R);
                  Name : constant String := R'Image & ": ";
                  Gaps : constant Natural := (if Kind = Try_Flood then Refused else 0);
               begin
                  Check (not X.Crashed and then X.Sentinel,
                         Name & "received the end marker");
                  Check (X.Corrupt = 0, Name & "no corrupted message");
                  Check (X.Disorder = 0, Name & "arrivals strictly in publish order");
                  Check (X.Pending = 0, Name & "queue empty at the end");
                  if Is_Reliable (R) then
                     Check (X.Dropped = 0, Name & "Dropped (Reliable) = 0");
                     Check (X.Missing = Gaps,
                            Name & (if Kind = Try_Flood
                                    then "gaps equal Try_Publish refusals"
                                    else "every message delivered"));
                     Check (X.Received = Published + 1 - Gaps,
                            Name & "received count matches");
                  else
                     Check (X.Missing = X.Dropped, Name & "gaps equal Dropped");
                     Check (X.Received + X.Dropped = Published + 1,
                            Name & "Received + Dropped = Published");
                  end if;
               end;
            end if;
         end loop;

         --  Coverage (S6) and memory (S7).
         case Kind is
            when Paced =>
               Check (Published = Seconds * Rate_Hz,
                      "coverage: published exactly Rate x Seconds");
               Check (Results (BE_Stall).Dropped > 0,
                      "coverage: stalling Best_Effort subscriber dropped");
               if RSS_First >= 0 then
                  Check (RSS_Max - RSS_First <= Max_RSS_Growth,
                         "memory: resident set grew by at most 1 MiB during the soak");
               end if;
            when Flood =>
               Check (Results (Rel_Stall).Saw_Full > 0,
                      "coverage: Reliable queue seen full (Publish blocked)");
               Check (Results (BE_Stall).Dropped > 0,
                      "coverage: stalling Best_Effort subscriber dropped");
            when Try_Flood =>
               Check (Refused > 0, "coverage: Try_Publish was refused");
         end case;
      end Report;

   begin
      T.Create_Publisher (Pub);
      for R in Role loop
         if Is_Active (R) then
            T.Create_Subscriber (Subs (R).all);
         end if;
      end loop;

      declare
         task Producer;
         task Monitor;

         task type Consumer (R : Role);

         task body Producer is
            CPU0      : constant Ada.Execution_Time.CPU_Time := Ada.Execution_Time.Clock;
            Next      : Time := Clock + Milliseconds (20);
            Stop_At   : constant Time := Next + Ada.Real_Time.Seconds (Seconds);
            Late      : Time_Span;
            Delivered : Boolean;
         begin
            Started := Clock;
            case Kind is
               when Paced =>
                  loop
                     delay until Next;
                     exit when Next >= Stop_At;
                     Late := Clock - Next;
                     Add (Lateness, Late);
                     if Late > Period then
                        Overruns := Overruns + 1;
                     end if;
                     Published := Published + 1;
                     T.Publish (Pub, Make (Published));
                     Next := Next + Period;
                  end loop;
               when Flood =>
                  for I in 1 .. Messages loop
                     Published := I;
                     T.Publish (Pub, Make (I));
                  end loop;
               when Try_Flood =>
                  for I in 1 .. Messages loop
                     Published := I;
                     T.Try_Publish (Pub, Make (I), Delivered);
                     if not Delivered then
                        Refused := Refused + 1;
                     end if;
                  end loop;
            end case;
            --  The end marker is the newest message, so even a Best_Effort
            --  queue keeps it. Blocking Publish makes sure Reliable gets it.
            T.Publish (Pub, Make (Published + 1, Last => True));
            Finished := Clock;
            Prod_CPU := To_Duration (Ada.Execution_Time.Clock - CPU0);
            Done := True;
         exception
            when E : others =>
               Prod_Crash := True;
               Done := True;
               Put_Line ("  publisher crashed: " & Ada.Exceptions.Exception_Information (E));
         end Producer;

         task body Consumer is
            CPU0 : constant Ada.Execution_Time.CPU_Time := Ada.Execution_Time.Clock;
            S    : T.Subscriber renames Subs (R).all;
            X    : Sub_Result;
            Msg  : Sample;
            Prev : Natural := 0;
         begin
            if Is_Active (R) then
               loop
                  T.Receive (S, Msg);
                  Add (X.Latency, Clock - Msg.Sent);
                  X.Received := X.Received + 1;
                  if Msg.Check /= Signature (Msg.Seq) then
                     X.Corrupt := X.Corrupt + 1;
                  end if;
                  if Msg.Seq <= Prev then
                     X.Disorder := X.Disorder + 1;
                  else
                     X.Missing := X.Missing + (Msg.Seq - Prev - 1);
                     Prev := Msg.Seq;
                  end if;
                  exit when Msg.Last;

                  if Stall_Every (R) > 0 and then X.Received mod Stall_Every (R) = 0 then
                     delay Stall_For (R);
                     if T.Pending (S) = Depth then
                        X.Saw_Full := X.Saw_Full + 1;
                     end if;
                  end if;
               end loop;
               X.Sentinel := True;
               X.Dropped := T.Dropped (S);
               X.Pending := T.Pending (S);
               X.CPU := To_Duration (Ada.Execution_Time.Clock - CPU0);
            end if;
            Results (R) := X;
         exception
            when E : others =>
               Results (R).Crashed := True;
               Put_Line ("  " & R'Image & " crashed: "
                         & Ada.Exceptions.Exception_Information (E));
         end Consumer;

         task body Monitor is
            CPU0    : constant Ada.Execution_Time.CPU_Time := Ada.Execution_Time.Clock;
            Start   : constant Time := Clock;
            Next    : Time := Start;
            Warm_Up : constant Time := Start + Ada.Real_Time.Seconds (1);
            Ticks   : Natural := 0;
            RSS     : Long_Long_Integer;
         begin
            while not Done loop
               for R in Role loop
                  if Is_Active (R) then
                     Max_Pending (R) := Natural'Max (Max_Pending (R), T.Pending (Subs (R).all));
                  end if;
               end loop;
               --  Resident memory once a second after a 1 s warm-up.
               if Kind = Paced and then Next >= Warm_Up and then Ticks mod 10 = 0 then
                  RSS := Resident_Bytes;
                  if RSS >= 0 then
                     if RSS_First < 0 then
                        RSS_First := RSS;
                     end if;
                     RSS_Max := Long_Long_Integer'Max (RSS_Max, RSS);
                  end if;
               end if;
               Ticks := Ticks + 1;
               Next := Next + Milliseconds (100);
               delay until Next;
            end loop;
            Mon_CPU := To_Duration (Ada.Execution_Time.Clock - CPU0);
         end Monitor;

         C1 : Consumer (Rel_Fast);
         C2 : Consumer (Rel_Stall);
         C3 : Consumer (BE_Fast);
         C4 : Consumer (BE_Stall);
         pragma Unreferenced (C1, C2, C3, C4);
      begin
         null;   --  wait here until every task of the scenario terminates
      end;

      Console.Acquire;
      Report;
      Console.Release;
      Failures := Count;
   end Run_Scenario;

   ---------------------------------------------------------------------

   Seconds   : Positive := Default_Seconds;
   Messages  : Positive := Default_Flood;
   Paced_F   : Natural := 1;
   Flood_F   : Natural := 1;
   Try_F     : Natural := 1;

   use Ada.Command_Line;

begin
   if Argument_Count >= 1 then
      Seconds := Positive'Value (Argument (1));
   end if;
   if Argument_Count >= 2 then
      Messages := Positive'Value (Argument (2));
   end if;

   Put_Line ("Beacon.Topic soak tests: queue depth" & Depth'Image & ", paced"
             & Seconds'Image & " s, flood" & Messages'Image & " messages");

   --  Generous: about 20x the expected run time on a laptop.
   Watchdog.Arm (Duration (120 + Seconds * 2 + Messages / 10_000));

   Run_Scenario (Paced, Seconds, Messages, Paced_F);

   declare
      task Flood_Runner;
      task Try_Runner;

      task body Flood_Runner is
      begin
         Run_Scenario (Flood, Seconds, Messages, Flood_F);
      exception
         when E : others =>
            Put_Line ("  flood scenario crashed: " & Ada.Exceptions.Exception_Information (E));
      end Flood_Runner;

      task body Try_Runner is
      begin
         Run_Scenario (Try_Flood, Seconds, Messages, Try_F);
      exception
         when E : others =>
            Put_Line ("  try_flood scenario crashed: "
                      & Ada.Exceptions.Exception_Information (E));
      end Try_Runner;
   begin
      null;
   end;

   Watchdog.Disarm;

   Put_Line ("");
   if Paced_F + Flood_F + Try_F = 0 then
      Put_Line ("all passed");
   else
      Put_Line (Img (Paced_F + Flood_F + Try_F) & " failure(s)");
      Set_Exit_Status (Failure);
   end if;
end Topic_Soak_Tests;
