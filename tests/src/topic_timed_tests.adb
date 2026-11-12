--  Tests for Beacon.Topic.Timed, the Receive with a timeout. They are
--  separate from topic_tests because the timeout needs a full runtime:
--  topic_tests uses only what the Jorvik profile allows.

with Ada.Command_Line;
with Ada.Real_Time;  use Ada.Real_Time;
with Ada.Text_IO;    use Ada.Text_IO;
with Beacon;         use Beacon;
with Beacon.Topic.Timed;

procedure Topic_Timed_Tests is

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

   package T is new Beacon.Topic
     (Message_Type => Reading, Queue_Depth => 3, Max_Subscribers => 1);
   package T_Timed is new T.Timed;

   Pub   : T.Publisher;
   Rel   : aliased T.Subscriber (Reliable);
   Msg   : Reading;
   Got   : Boolean;
   Start : Time;

begin
   Put_Line ("Beacon.Topic.Timed tests");

   T.Create_Publisher (Pub);
   T.Create_Subscriber (Rel);

   T_Timed.Receive (Rel, Msg, Time_Span_Zero, Got);
   Check (not Got, "timed receive: empty queue with zero timeout returns False");

   Start := Clock;
   T_Timed.Receive (Rel, Msg, Milliseconds (10), Got);
   Check (not Got, "timed receive: empty queue with 10ms timeout returns False");
   Check (Clock - Start >= Milliseconds (10),
          "timed receive: waited the full timeout before giving up");

   T.Publish (Pub, (Id => 101, Value => 42.0));
   T_Timed.Receive (Rel, Msg, Time_Span_Zero, Got);
   Check (Got and then Msg.Id = 101,
          "timed receive: item ready with zero timeout returns True");

   T.Publish (Pub, (Id => 102, Value => 84.0));
   T_Timed.Receive (Rel, Msg, Milliseconds (50), Got);
   Check (Got and then Msg.Id = 102,
          "timed receive: item ready with positive timeout returns True");

   --  The queue is empty again: the Empty flag behind the Pop barrier
   --  must have followed the last Receive.
   T_Timed.Receive (Rel, Msg, Milliseconds (10), Got);
   Check (not Got and then T.Pending (Rel) = 0,
          "timed receive: times out again once the queue is drained");

   New_Line;
   if Failures = 0 then
      Put_Line ("all passed");
   else
      Put_Line (Natural'Image (Failures) & " failure(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Topic_Timed_Tests;
