--  Unit tests for Beacon.Queue. Owner: core engineer. Green by Week 4.
--  These exercise the exact properties the SPARK proof will later cover:
--  wraparound, fill bounds, and drop-oldest not corrupting order.

with Ada.Command_Line;
with Ada.Text_IO;
with Beacon.Queue;

procedure Queue_Tests is

   Failures : Natural := 0;

   procedure Check (Cond : Boolean; Name : String);
   procedure Check (Cond : Boolean; Name : String) is
      use Ada.Text_IO;
   begin
      if Cond then
         Put_Line ("  ok    " & Name);
      else
         Put_Line ("  FAIL  " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   Depth : constant := 4;
   package Q is new Beacon.Queue (Element_Type => Integer, Depth => Depth);
   use Q;

   Ring    : Queue_Type := Empty_Queue;
   Item    : Integer;
   Dropped : Boolean;

begin
   Ada.Text_IO.Put_Line ("Beacon.Queue tests");

   Check (Is_Empty (Ring) and then Count (Ring) = 0, "starts empty");

   for I in 1 .. Depth loop
      Push (Ring, I);
   end loop;
   Check (Is_Full (Ring) and then Count (Ring) = Depth, "fills to Depth");

   Pop (Ring, Item);
   Check (Item = 1, "FIFO order");
   Push (Ring, 5);
   Check (Is_Full (Ring), "wraps around: full again after pop+push");

   for Expected in 2 .. 5 loop
      Pop (Ring, Item);
      if Item /= Expected then
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("  FAIL  wrap order: got" & Integer'Image (Item)
                               & " expected" & Integer'Image (Expected));
      end if;
   end loop;
   Check (Is_Empty (Ring), "drained after wrap");

   --  Best-effort: drop oldest, keep newest, preserve order of the rest.
   for I in 1 .. Depth loop
      Push_Dropping_Oldest (Ring, I, Dropped);
      Check (not Dropped, "no drop while not full" & Integer'Image (I));
   end loop;
   Push_Dropping_Oldest (Ring, 99, Dropped);
   Check (Dropped and then Count (Ring) = Depth, "drop reported, count stays Depth");
   Pop (Ring, Item);
   Check (Item = 2, "oldest (1) was the one dropped");
   Pop (Ring, Item); Pop (Ring, Item); Pop (Ring, Item);
   Check (Item = 99, "newest survives at the tail");

   Ada.Text_IO.New_Line;
   if Failures = 0 then
      Ada.Text_IO.Put_Line ("all passed");
   else
      Ada.Text_IO.Put_Line (Natural'Image (Failures) & " failure(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Queue_Tests;
