--  In-process flight telemetry demo (Task 3.5): the acceptance test for
--  semester one. A small satellite runs for two seconds, all in one
--  process, all through Beacon.Topic:
--
--    Attitude_Sensor   publishes Attitude       ~1 kHz  -> Attitude_Topic
--    Controller        reads Attitude, publishes Wheel_Command ~100 Hz
--                      (the control loop)              -> Wheel_Topic
--    Power_Monitor     publishes Power_Status   ~5 Hz   -> Power_Topic
--    Ground_Station    uplinks Ground_Command   ~10 Hz  -> Ground_Topic
--                      (one of them puts the satellite in Safe mode)
--    Main              the downlink: logs every topic at ~100 Hz
--
--  Delivery modes:
--    Best_Effort  Attitude, Wheel: only the newest value matters, and a
--                 slow reader must never hold up a fast writer.
--    Reliable     Power, Ground: every message, in order, none dropped.
--
--  What it must show (each line is a check, exit status non-zero if any
--  fails, so CI can run it):
--    Reliable topics: Dropped = 0, every message received, in order.
--    Best_Effort topics: drops under load, last value is the newest.
--    Control loop: kept its rate, acted on fresh attitude, obeyed the
--    Safe mode command from the ground (zero torque afterwards).

with Ada.Command_Line;
with Ada.Float_Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Real_Time;   use Ada.Real_Time;
with Ada.Strings;     use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;     use Ada.Text_IO;
with Beacon;          use Beacon;
with Telemetry;       use Telemetry;

procedure Inproc_Demo is

   Run_For  : constant Time_Span := Milliseconds (2000);
   Deadline : constant Time := Clock + Run_For;

   Safe_Mode_At : constant := 10;  --  ground command number that sends Safe

   --  Subscribers. All registered by Main before any task publishes:
   --  the first Publish locks the registry (Task 3.7).
   Log_Attitude  : aliased Attitude_Topic.Subscriber (Best_Effort);
   Log_Wheel     : aliased Wheel_Topic.Subscriber (Best_Effort);
   Log_Power     : aliased Power_Topic.Subscriber (Reliable);
   Log_Ground    : aliased Ground_Topic.Subscriber (Reliable);
   Ctl_Attitude  : aliased Attitude_Topic.Subscriber (Best_Effort);
   Ctl_Ground    : aliased Ground_Topic.Subscriber (Reliable);

   --  What the tasks did, for the checks at the end.
   Attitude_Sent     : Natural := 0 with Atomic;
   Wheel_Sent        : Natural := 0 with Atomic;
   Power_Sent        : Natural := 0 with Atomic;
   Ground_Sent       : Natural := 0 with Atomic;
   Ctl_Cycles        : Natural := 0 with Atomic;
   Ctl_Ground_Seen   : Natural := 0 with Atomic;
   Ctl_Ground_Order  : Boolean := True with Atomic;
   Ctl_Mode          : Flight_Mode := Nominal with Atomic;

   --  Tasks activate before Main's first statement, so each one waits on
   --  Go until every subscriber above is registered.

   task Attitude_Sensor is
      entry Go;
   end Attitude_Sensor;
   task body Attitude_Sensor is
      Pub  : Attitude_Topic.Publisher;
      Seq  : Natural := 0;
      Next : Time;
   begin
      accept Go;
      Attitude_Topic.Create_Publisher (Pub);
      Next := Clock;
      while Clock < Deadline loop
         Seq := Seq + 1;
         --  A slow tumble the controller has to fight.
         Attitude_Topic.Publish
           (Pub, (Sequence => Seq,
                  Roll     => 5.0 * Sin (Float (Seq) / 150.0),
                  Pitch    => 3.0 * Cos (Float (Seq) / 230.0),
                  Yaw      => 1.0 * Sin (Float (Seq) / 400.0)));
         Attitude_Sent := Seq;
         Next := Next + Milliseconds (1);
         delay until Next;
      end loop;
   end Attitude_Sensor;

   --  The control loop: every 10 ms, take the newest attitude, apply a
   --  proportional controller, publish wheel torques. Best_Effort on both
   --  sides, so nothing here can block on a slow reader.
   task Controller is
      entry Go;
   end Controller;
   task body Controller is
      Gain : constant Float := 0.02;  --  torque per degree

      Pub    : Wheel_Topic.Publisher;
      Att    : Attitude;
      Newest : Attitude;
      Have   : Boolean := False;
      Cmd    : Ground_Command;
      Got    : Boolean;
      Seq    : Natural := 0;
      Next   : Time;

      procedure Read_Ground;
      procedure Read_Ground is
      begin
         loop
            Ground_Topic.Try_Receive (Ctl_Ground, Cmd, Got);
            exit when not Got;
            Ctl_Ground_Seen := Ctl_Ground_Seen + 1;
            if Cmd.Sequence /= Ctl_Ground_Seen then
               Ctl_Ground_Order := False;
            end if;
            if Cmd.Kind = Set_Mode then
               Ctl_Mode := Cmd.Mode;
            end if;
         end loop;
      end Read_Ground;

   begin
      accept Go;
      Wheel_Topic.Create_Publisher (Pub);
      Next := Clock;
      --  Runs a little past Deadline so it sees the last ground command.
      while Clock < Deadline + Milliseconds (30) loop
         Read_Ground;

         --  Drain the attitude queue, keep only the newest sample.
         loop
            Attitude_Topic.Try_Receive (Ctl_Attitude, Att, Got);
            exit when not Got;
            Newest := Att;
            Have := True;
         end loop;

         if Have then
            Seq := Seq + 1;
            if Ctl_Mode = Safe then
               --  Safe mode: stop actuating, hold the wheels.
               Wheel_Topic.Publish
                 (Pub, (Sequence => Seq, For_Attitude => Newest.Sequence,
                        others   => 0.0));
            else
               Wheel_Topic.Publish
                 (Pub, (Sequence     => Seq,
                        For_Attitude => Newest.Sequence,
                        Torque_Roll  => -Gain * Newest.Roll,
                        Torque_Pitch => -Gain * Newest.Pitch,
                        Torque_Yaw   => -Gain * Newest.Yaw));
            end if;
            Wheel_Sent := Seq;
         end if;

         Ctl_Cycles := Ctl_Cycles + 1;
         Next := Next + Milliseconds (10);
         delay until Next;
      end loop;
      Read_Ground;
   end Controller;

   task Power_Monitor is
      entry Go;
   end Power_Monitor;
   task body Power_Monitor is
      Pub  : Power_Topic.Publisher;
      Seq  : Natural := 0;
      Next : Time;
   begin
      accept Go;
      Power_Topic.Create_Publisher (Pub);
      Next := Clock;
      while Clock < Deadline loop
         Seq := Seq + 1;
         --  Battery slowly discharging.
         Power_Topic.Publish
           (Pub, (Sequence      => Seq,
                  Battery_Volts => 8.4 - 0.01 * Float (Seq),
                  Charge        => Float'Max (0.0, 95.0 - 0.5 * Float (Seq))));
         Power_Sent := Seq;
         Next := Next + Milliseconds (200);
         delay until Next;
      end loop;
   end Power_Monitor;

   task Ground_Station is
      entry Go;
   end Ground_Station;
   task body Ground_Station is
      Pub  : Ground_Topic.Publisher;
      Seq  : Natural := 0;
      Next : Time;
   begin
      accept Go;
      Ground_Topic.Create_Publisher (Pub);
      Next := Clock;
      while Clock < Deadline loop
         Seq := Seq + 1;
         if Seq = Safe_Mode_At then
            Ground_Topic.Publish
              (Pub, (Sequence => Seq, Kind => Set_Mode, Mode => Safe));
         else
            Ground_Topic.Publish (Pub, (Sequence => Seq, others => <>));
         end if;
         Ground_Sent := Seq;
         Next := Next + Milliseconds (100);
         delay until Next;
      end loop;
   end Ground_Station;

   ----------------
   -- Downlink log --
   ----------------

   Attitude_Seen : Natural := 0;
   Wheel_Seen    : Natural := 0;
   Power_Seen    : Natural := 0;
   Ground_Seen   : Natural := 0;
   Power_Order   : Boolean := True;
   Ground_Order  : Boolean := True;
   Last_Attitude : Attitude;
   Last_Wheel    : Wheel_Command;
   Last_Power    : Power_Status;

   procedure Drain_All;
   procedure Drain_All is
      A   : Attitude;
      W   : Wheel_Command;
      P   : Power_Status;
      G   : Ground_Command;
      Got : Boolean;
   begin
      loop
         Attitude_Topic.Try_Receive (Log_Attitude, A, Got);
         exit when not Got;
         Last_Attitude := A;
         Attitude_Seen := Attitude_Seen + 1;
      end loop;
      loop
         Wheel_Topic.Try_Receive (Log_Wheel, W, Got);
         exit when not Got;
         Last_Wheel := W;
         Wheel_Seen := Wheel_Seen + 1;
      end loop;
      loop
         Power_Topic.Try_Receive (Log_Power, P, Got);
         exit when not Got;
         Power_Seen := Power_Seen + 1;
         Power_Order := Power_Order and then P.Sequence = Power_Seen;
         Last_Power := P;
      end loop;
      loop
         Ground_Topic.Try_Receive (Log_Ground, G, Got);
         exit when not Got;
         Ground_Seen := Ground_Seen + 1;
         Ground_Order := Ground_Order and then G.Sequence = Ground_Seen;
      end loop;
   end Drain_All;

   --  Slow downlink on purpose: takes one attitude and one wheel sample
   --  per 10 ms tick, so the Best_Effort queues overflow and drop.
   procedure Sample_Slowly;
   procedure Sample_Slowly is
      A   : Attitude;
      W   : Wheel_Command;
      Got : Boolean;
   begin
      Attitude_Topic.Try_Receive (Log_Attitude, A, Got);
      if Got then
         Last_Attitude := A;
         Attitude_Seen := Attitude_Seen + 1;
      end if;
      Wheel_Topic.Try_Receive (Log_Wheel, W, Got);
      if Got then
         Last_Wheel := W;
         Wheel_Seen := Wheel_Seen + 1;
      end if;
   end Sample_Slowly;

   --------------
   -- Reporting --
   --------------

   Failures : Natural := 0;

   function Img (N : Natural) return String;
   function Img (N : Natural) return String is
     (Ada.Strings.Fixed.Trim (N'Image, Left));

   function Col (S : String; Width : Positive) return String;
   function Col (S : String; Width : Positive) return String is
     (Ada.Strings.Fixed.Head (S, Width));

   function Fixed (X : Float) return String;
   function Fixed (X : Float) return String is
      Buf : String (1 .. 12);
   begin
      Ada.Float_Text_IO.Put (Buf, X, Aft => 2, Exp => 0);
      return Ada.Strings.Fixed.Trim (Buf, Left);
   end Fixed;

   procedure Row (Topic, Mode, Rate : String; Sent, Seen, Dropped : Natural);
   procedure Row (Topic, Mode, Rate : String; Sent, Seen, Dropped : Natural) is
   begin
      Put_Line ("  " & Col (Topic, 10) & Col (Mode, 13) & Col (Rate, 8)
                & Col (Img (Sent), 11) & Col (Img (Seen), 10) & Img (Dropped));
   end Row;

   procedure Check (Cond : Boolean; Name : String);
   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Put_Line ("  ok    " & Name);
      else
         Put_Line ("  FAIL  " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

begin
   Attitude_Topic.Create_Subscriber (Log_Attitude);
   Attitude_Topic.Create_Subscriber (Ctl_Attitude);
   Wheel_Topic.Create_Subscriber (Log_Wheel);
   Power_Topic.Create_Subscriber (Log_Power);
   Ground_Topic.Create_Subscriber (Log_Ground);
   Ground_Topic.Create_Subscriber (Ctl_Ground);

   Attitude_Sensor.Go;
   Controller.Go;
   Power_Monitor.Go;
   Ground_Station.Go;

   Put_Line ("Beacon in-process flight telemetry demo (2 s)");

   --  Downlink at ~100 Hz while the satellite runs. Reliable topics are
   --  drained fully each tick (their writers must not stay blocked).
   while Clock < Deadline loop
      Sample_Slowly;
      declare
         P   : Power_Status;
         G   : Ground_Command;
         Got : Boolean;
      begin
         loop
            Power_Topic.Try_Receive (Log_Power, P, Got);
            exit when not Got;
            Power_Seen := Power_Seen + 1;
            Power_Order := Power_Order and then P.Sequence = Power_Seen;
            Last_Power := P;
         end loop;
         loop
            Ground_Topic.Try_Receive (Log_Ground, G, Got);
            exit when not Got;
            Ground_Seen := Ground_Seen + 1;
            Ground_Order := Ground_Order and then G.Sequence = Ground_Seen;
         end loop;
      end;
      delay 0.01;
   end loop;

   --  Wait for every task to stop publishing, then take what is left.
   declare
      Give_Up : constant Time := Clock + Seconds (2);
   begin
      while Clock < Give_Up
        and then not (Attitude_Sensor'Terminated and then Controller'Terminated
                      and then Power_Monitor'Terminated
                      and then Ground_Station'Terminated)
      loop
         Drain_All;
         delay 0.001;
      end loop;
   end;
   Drain_All;

   New_Line;
   Put_Line ("  " & Col ("topic", 10) & Col ("mode", 13) & Col ("rate", 8)
             & Col ("published", 11) & Col ("received", 10) & "dropped");
   Row ("attitude", "best-effort", "1 kHz", Attitude_Sent, Attitude_Seen,
        Attitude_Topic.Dropped (Log_Attitude));
   Row ("wheel", "best-effort", "100 Hz", Wheel_Sent, Wheel_Seen,
        Wheel_Topic.Dropped (Log_Wheel));
   Row ("power", "reliable", "5 Hz", Power_Sent, Power_Seen,
        Power_Topic.Dropped (Log_Power));
   Row ("ground", "reliable", "10 Hz", Ground_Sent, Ground_Seen,
        Ground_Topic.Dropped (Log_Ground));
   New_Line;
   Put_Line ("  controller: " & Img (Ctl_Cycles) & " cycles, mode "
             & Ctl_Mode'Image & ", last wheel command used attitude #"
             & Img (Last_Wheel.For_Attitude) & " of " & Img (Attitude_Sent));
   Put_Line ("  battery:    " & Img (Last_Power.Sequence) & " readings, last "
             & Fixed (Last_Power.Battery_Volts) & " V, "
             & Fixed (Last_Power.Charge) & "% charge");
   New_Line;

   --  Reliable topics: nothing lost, nothing reordered.
   Check (Power_Topic.Dropped (Log_Power) = 0 and then Power_Seen = Power_Sent
          and then Power_Order,
          "power (reliable): every reading received, in order, none dropped");
   Check (Ground_Topic.Dropped (Log_Ground) = 0 and then Ground_Seen = Ground_Sent
          and then Ground_Order,
          "ground (reliable): every command logged, in order, none dropped");
   Check (Ground_Topic.Dropped (Ctl_Ground) = 0
          and then Ctl_Ground_Seen = Ground_Sent and then Ctl_Ground_Order,
          "ground (reliable): controller got every command, in order");

   --  Best_Effort topics: overflow, but the newest value survives.
   Check (Attitude_Topic.Dropped (Log_Attitude) > 0,
          "attitude (best-effort): slow downlink overflowed and dropped");
   Check (Last_Attitude.Sequence = Attitude_Sent,
          "attitude (best-effort): last value received is the newest");
   Check (Last_Wheel.Sequence = Wheel_Sent,
          "wheel (best-effort): last command received is the newest");

   --  The control loop.
   Check (Ctl_Cycles >= 150,
          "controller: kept its 100 Hz rate (>= 150 of ~200 cycles)");
   Check (Attitude_Sent - Last_Wheel.For_Attitude <= 20,
          "controller: acted on fresh attitude (within 20 ms of newest)");
   Check (Ground_Sent >= Safe_Mode_At and then Ctl_Mode = Safe,
          "controller: obeyed Safe mode command from the ground");
   Check (Last_Wheel.Torque_Roll = 0.0 and then Last_Wheel.Torque_Pitch = 0.0
          and then Last_Wheel.Torque_Yaw = 0.0,
          "controller: zero wheel torque in Safe mode");

   New_Line;
   if Failures = 0 then
      Put_Line ("inproc_demo ok");
   else
      Put_Line ("inproc_demo:" & Failures'Image & " check(s) failed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Inproc_Demo;
