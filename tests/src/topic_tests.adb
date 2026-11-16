--  Tests for Beacon.Topic. Owner: validation engineer. Green by Week 8.
--  The Week 8 review question, verbatim: fill a reliable queue past
--  capacity and verify the documented behavior actually occurs.

with Ada.Assertions;
with Ada.Command_Line;
with Ada.Real_Time;  use Ada.Real_Time;
with Ada.Text_IO;    use Ada.Text_IO;
with Beacon;         use Beacon;
with Beacon.Topic;

procedure Topic_Tests is

   Failures : Natural := 0;

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

   type Reading is record
      Id    : Natural;
      Value : Float;
   end record;

   Depth : constant := 3;
   package T is new Beacon.Topic
     (Message_Type => Reading, Queue_Depth => Depth, Max_Subscribers => 2);

   Pub       : T.Publisher;
   Rel       : aliased T.Subscriber (Reliable);
   Best      : aliased T.Subscriber (Best_Effort);
   Msg       : Reading;
   Got       : Boolean;
   Delivered : Boolean;

   --  Subscriber lifecycle and registry lockdown (Task 3.7). The lock is
   --  permanent per instantiation, so these use their own instances.
   procedure Lifecycle_Tests;
   procedure Lifecycle_Tests is
      package L is new Beacon.Topic
        (Message_Type => Reading, Queue_Depth => Depth, Max_Subscribers => 3);

      L_Pub : L.Publisher;
      A     : aliased L.Subscriber (Reliable);
      B     : aliased L.Subscriber (Best_Effort);
      C     : aliased L.Subscriber (Reliable);
      D     : aliased L.Subscriber (Best_Effort);
      M     : Reading;
      Raised : Boolean;
   begin
      Check (not L.Is_Locked, "lock: a new topic is unlocked");

      L.Create_Subscriber (A);
      L.Create_Subscriber (B);
      L.Create_Subscriber (C);
      Check (L.Subscriber_Count = 3, "lifecycle: registry full (3 of 3)");

      L.Delete_Subscriber (B);
      Check (L.Subscriber_Count = 2 and then not L.Is_Registered (B),
             "lifecycle: delete removes the subscriber");
      Check (L.Is_Registered (A) and then L.Is_Registered (C),
             "lifecycle: delete leaves the others registered");

      --  The registry was full, so this only succeeds if the slot was freed.
      L.Create_Subscriber (D);
      Check (L.Subscriber_Count = 3 and then L.Is_Registered (D),
             "lifecycle: the freed slot is reused");

      --  A deleted subscriber can register again.
      L.Delete_Subscriber (D);
      L.Create_Subscriber (B);
      Check (L.Is_Registered (B) and then not L.Is_Registered (D),
             "lifecycle: a deleted subscriber can register again");

      --  Deleting an unregistered subscriber fails its precondition.
      Raised := False;
      begin
         L.Delete_Subscriber (D);
      exception
         when Ada.Assertions.Assertion_Error => Raised := True;
      end;
      Check (Raised, "lifecycle: deleting an unregistered subscriber is refused");

      --  Free a slot, so the checks below fail only because of the lock.
      L.Delete_Subscriber (B);
      L.Create_Publisher (L_Pub);
      Check (not L.Is_Locked, "lock: Create_Publisher does not lock");

      L.Publish (L_Pub, (Id => 5, Value => 0.0));
      Check (L.Is_Locked, "lock: the first Publish locks the registry");
      Check (L.Pending (A) = 1 and then L.Pending (C) = 1
               and then L.Pending (B) = 0,
             "lifecycle: registered subscribers get the message, deleted do not");
      L.Receive (A, M);
      L.Receive (C, M);

      Raised := False;
      begin
         L.Create_Subscriber (B);
      exception
         when Ada.Assertions.Assertion_Error => Raised := True;
      end;
      Check (Raised and then not L.Is_Registered (B)
               and then L.Subscriber_Count = 2,
             "lock: Create_Subscriber after the first Publish is refused");

      Raised := False;
      begin
         L.Delete_Subscriber (A);
      exception
         when Ada.Assertions.Assertion_Error => Raised := True;
      end;
      Check (Raised and then L.Is_Registered (A)
               and then L.Subscriber_Count = 2,
             "lock: Delete_Subscriber after the first Publish is refused");
   end Lifecycle_Tests;

   procedure Try_Publish_Lock_Test;
   procedure Try_Publish_Lock_Test is
      package L is new Beacon.Topic
        (Message_Type => Reading, Queue_Depth => Depth, Max_Subscribers => 2);
      L_Pub : L.Publisher;
      A     : aliased L.Subscriber (Best_Effort);
      Ok    : Boolean;
   begin
      L.Create_Subscriber (A);
      L.Create_Publisher (L_Pub);
      L.Try_Publish (L_Pub, (Id => 1, Value => 0.0), Ok);
      Check (Ok and then L.Is_Locked, "lock: the first Try_Publish locks the registry");
   end Try_Publish_Lock_Test;

begin
   Put_Line ("Beacon.Topic tests");

   Lifecycle_Tests;
   Try_Publish_Lock_Test;

   T.Create_Publisher (Pub);
   T.Create_Subscriber (Rel);
   T.Create_Subscriber (Best);
   Check (T.Subscriber_Count = 2, "two subscribers registered");

   --  Fan-out: one publish, both receive the same typed value.
   T.Publish (Pub, (Id => 1, Value => 1.5));
   T.Receive (Rel, Msg);
   Check (Msg.Id = 1, "reliable subscriber receives typed value");
   T.Receive (Best, Msg);
   Check (Msg.Value = 1.5, "best-effort subscriber receives typed value");

   --  Fill both to capacity without draining.
   for I in 1 .. Depth loop
      T.Publish (Pub, (Id => I, Value => 0.0));
   end loop;
   Check (T.Pending (Rel) = Depth and then T.Pending (Best) = Depth,
          "both queues full");

   --  Overflow: Try_Publish must NOT block, must report the reliable
   --  refusal, and the best-effort side must drop its oldest.
   T.Try_Publish (Pub, (Id => 99, Value => 0.0), Delivered);
   Check (not Delivered, "reliable full: Try_Publish reports not delivered");
   Check (T.Pending (Rel) = Depth and then T.Dropped (Rel) = 0,
          "reliable: nothing dropped, nothing added");
   Check (T.Dropped (Best) = 1, "best-effort: exactly one drop counted");
   T.Receive (Best, Msg);
   Check (Msg.Id = 2, "best-effort: oldest (1) gone, 2 is now first");

   --  Reliable never lost anything: drain and check order.
   for Expected in 1 .. Depth loop
      T.Receive (Rel, Msg);
      if Msg.Id /= Expected then
         Failures := Failures + 1;
         Put_Line ("  FAIL  reliable order");
      end if;
   end loop;
   T.Try_Receive (Rel, Msg, Got);
   Check (not Got, "reliable drained, Try_Receive says empty");

   --  ========================================================================
   --  Task 2.4: Multi-Task Blocking-Publish Test
   --  ========================================================================
   --  A separate publisher task calls Publish on a full Reliable queue.
   --  It must block (not drop, not overwrite), and it must resume as soon
   --  as the subscriber drains one slot. Atomic flags let the main task see
   --  where the publisher is without touching the queue.

   Check (T.Pending (Rel) = 0, "blocking publish: reliable queue starts empty");

   --  1. Single blocked Publish, released by one Receive.
   for I in 1 .. Depth loop
      T.Publish (Pub, (Id => 300 + I, Value => 0.0));
   end loop;
   Check (T.Pending (Rel) = Depth, "blocking publish: reliable queue is full");

   declare
      Started  : Boolean := False with Atomic;
      Finished : Boolean := False with Atomic;

      task Blocked_Publisher;
      task body Blocked_Publisher is
      begin
         Started := True;
         T.Publish (Pub, (Id => 400, Value => 4.0));  --  must block here
         Finished := True;
      end Blocked_Publisher;

      Deadline : Time;
   begin
      --  Wait for the task to reach Publish, then give it time to finish
      --  if it (wrongly) does not block.
      Deadline := Clock + Seconds (1);
      while not Started and then Clock < Deadline loop
         delay 0.001;
      end loop;
      delay 0.1;

      Check (Started, "blocking publish: publisher task started");
      Check (not Finished,
             "blocking publish: Publish blocks while reliable queue is full");
      Check (T.Pending (Rel) = Depth and then T.Dropped (Rel) = 0,
             "blocking publish: full queue untouched while publisher waits");

      --  Free exactly one slot.
      T.Receive (Rel, Msg);
      Check (Msg.Id = 301, "blocking publish: drained the oldest message");

      Deadline := Clock + Seconds (2);
      while not Finished and then Clock < Deadline loop
         delay 0.001;
      end loop;
      Check (Finished, "blocking publish: publisher resumes after one drain");

      if not Finished then
         abort Blocked_Publisher;  --  keep the suite from hanging on failure
      end if;
   end;

   Check (T.Pending (Rel) = Depth,
          "blocking publish: released message filled the freed slot");
   for Expected in 302 .. 303 loop
      T.Receive (Rel, Msg);
      Check (Msg.Id = Expected, "blocking publish: order kept," & Expected'Image);
   end loop;
   T.Receive (Rel, Msg);
   Check (Msg.Id = 400, "blocking publish: blocked message delivered last");
   Check (T.Dropped (Rel) = 0, "blocking publish: reliable dropped nothing");

   --  2. Burst: the publisher sends far more than the queue holds while the
   --  main task drains slowly. Publish must block and resume many times,
   --  and every message must arrive exactly once, in order.
   declare
      Burst : constant := 4 * Depth;
      Base  : constant := 500;

      Sent : Natural := 0 with Atomic;

      task Burst_Publisher;
      task body Burst_Publisher is
      begin
         for I in 1 .. Burst loop
            T.Publish (Pub, (Id => Base + I, Value => Float (I)));
            Sent := Sent + 1;
         end loop;
      end Burst_Publisher;

      In_Order : Boolean := True;
      Received : Natural := 0;
      Deadline : Time;
   begin
      --  Let the publisher run ahead: it can get exactly Depth in.
      delay 0.1;
      Check (T.Pending (Rel) = Depth and then Sent = Depth,
             "burst: publisher stopped at queue capacity");

      --  Poll with Try_Receive and a deadline, so a stuck publisher
      --  fails the test instead of hanging it.
      for I in 1 .. Burst loop
         Deadline := Clock + Seconds (2);
         loop
            T.Try_Receive (Rel, Msg, Got);
            exit when Got or else Clock >= Deadline;
            delay 0.001;
         end loop;
         exit when not Got;
         Received := Received + 1;
         if Msg.Id /= Base + I then
            In_Order := False;
         end if;
         delay 0.002;  --  slow consumer keeps the queue near full
      end loop;

      Check (Received = Burst, "burst: every message received");
      Check (In_Order, "burst: messages arrive in publish order");
      Check (Sent = Burst, "burst: publisher completed all publishes");

      if Sent /= Burst then
         abort Burst_Publisher;
      end if;
   end;

   Check (T.Pending (Rel) = 0, "burst: reliable queue drained");
   Check (T.Dropped (Rel) = 0, "burst: reliable dropped nothing under contention");

   --  Load test (sustained overflow, many tasks, Dropped (Rel) = 0 at
   --  the end): see topic_soak_tests.adb (Task 3.3).

   New_Line;
   if Failures = 0 then
      Put_Line ("all passed");
   else
      Put_Line (Natural'Image (Failures) & " failure(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Topic_Tests;
