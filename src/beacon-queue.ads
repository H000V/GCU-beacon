--  Beacon.Queue: bounded FIFO ring buffer. SPARK proof target (Silver).
--
--  This is a plain data structure: no tasking, no protection, no I/O.
--  Beacon.Topic wraps one of these in a protected type. Keeping the
--  ring arithmetic here, outside the protected type, is what makes the
--  proof small and independent of the tasking runtime.
--
--  Design rule 3: Depth is fixed at instantiation. No growth, no heap.
--
--  Note on the proposal's sketch: `type Ring_Index is mod Queue_Depth`
--  is illegal because a modulus must be static and a generic formal
--  object is not. Indices are a Natural subtype with an explicit
--  `mod Depth` on advance instead.

generic
   type Element_Type is private;
   Depth : Positive;
package Beacon.Queue
  with SPARK_Mode => On
is

   type Queue_Type is private;

   Empty_Queue : constant Queue_Type;
   --  The only way to get a well-formed queue. Element slots are left
   --  uninitialized on purpose (Element_Type may have no default); only
   --  slots between Head and Tail are ever read.

   function Count (Q : Queue_Type) return Natural
     with Post => Count'Result <= Depth;

   function Is_Empty (Q : Queue_Type) return Boolean is (Count (Q) = 0);
   function Is_Full  (Q : Queue_Type) return Boolean is (Count (Q) = Depth);

   --  Reliable path. Caller guarantees room.
   procedure Push (Q : in out Queue_Type; Item : Element_Type)
     with Pre  => not Is_Full (Q),
          Post => Count (Q) = Count (Q'Old) + 1;

   --  Best-effort path. If full, the oldest element is overwritten and
   --  Dropped is True. Never fails, never blocks.
   procedure Push_Dropping_Oldest
     (Q       : in out Queue_Type;
      Item    : Element_Type;
      Dropped : out Boolean)
     with Post => Dropped = Is_Full (Q'Old)
                  and then Count (Q) = Natural'Min (Count (Q'Old) + 1, Depth);

   procedure Pop (Q : in out Queue_Type; Item : out Element_Type)
     with Pre  => not Is_Empty (Q),
          Post => Count (Q) = Count (Q'Old) - 1;

private

   subtype Ring_Index is Natural range 0 .. Depth - 1;

   type Element_Array is array (Ring_Index) of Element_Type;

   type Queue_Type is record
      Buffer : Element_Array;
      Head   : Ring_Index := 0;   --  next slot to Pop
      Tail   : Ring_Index := 0;   --  next slot to Push
      Fill   : Natural range 0 .. Depth := 0;
   end record;
   --  Invariant to carry through proof:
   --    Tail = (Head + Fill) mod Depth
   --  Buffer is deliberately not initialized (Element_Type may have no
   --  default). Only slots Head .. Head + Fill - 1 (mod Depth) are ever
   --  read. Expect to need Relaxed_Initialization to convince flow analysis.

   function Count (Q : Queue_Type) return Natural is (Q.Fill);

   pragma Warnings (Off, "component ""Buffer"" of type ""Element_Array"" is uninitialized");
   Empty_Queue : constant Queue_Type := (Buffer => <>, Head => 0, Tail => 0, Fill => 0);
   pragma Warnings (On, "component ""Buffer"" of type ""Element_Array"" is uninitialized");
   --  Buffer is deliberately uninitialized: see the comment above.

end Beacon.Queue;
