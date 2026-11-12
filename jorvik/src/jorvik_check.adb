--  Runs Beacon.Topic under pragma Profile (Jorvik) with the zero-heap
--  restrictions of jorvik.adc. Exits non-zero on any failure.

with Ada.Command_Line;
with Ada.Text_IO;   use Ada.Text_IO;
with Jorvik_Topics; use Jorvik_Topics;

procedure Jorvik_Check is

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

   Msg       : Reading;
   Got       : Boolean;
   Delivered : Boolean;

begin
   Put_Line ("Beacon.Topic under the Jorvik profile");

   Topic.Create_Publisher (Pub);
   Topic.Create_Subscriber (Rel);
   Topic.Create_Subscriber (Best);

   --  Blocking Publish and Receive go through the two entries.
   Topic.Publish (Pub, (Id => 1, Value => 1.5));
   Topic.Receive (Rel, Msg);
   Check (Msg.Id = 1, "reliable: entry Push then entry Pop");
   Topic.Receive (Best, Msg);
   Check (Msg.Id = 1, "best-effort: entry Push then entry Pop");

   --  Fill both queues, then overflow without blocking.
   for I in 1 .. Depth loop
      Topic.Publish (Pub, (Id => I, Value => 0.0));
   end loop;
   Topic.Try_Publish (Pub, (Id => 99, Value => 0.0), Delivered);
   Check (not Delivered and then Topic.Dropped (Rel) = 0,
          "reliable full: refused, nothing dropped");
   Check (Topic.Dropped (Best) = 1, "best-effort full: one drop counted");

   --  Drain. The Pop barrier must stay open until the queue is empty.
   for Expected in 1 .. Depth loop
      Topic.Receive (Rel, Msg);
      Check (Msg.Id = Expected, "reliable: in order," & Integer'Image (Expected));
   end loop;
   Topic.Try_Receive (Rel, Msg, Got);
   Check (not Got, "reliable: empty after the drain");

   --  The Push barrier must be open again after the drain.
   Topic.Publish (Pub, (Id => 7, Value => 0.0));
   Topic.Receive (Rel, Msg);
   Check (Msg.Id = 7, "reliable: Push barrier reopened after the drain");

   New_Line;
   if Failures = 0 then
      Put_Line ("all passed");
   else
      Put_Line (Natural'Image (Failures) & " failure(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Jorvik_Check;
