--  Beacon.Queue: bounded FIFO ring buffer. Proved with GNATprove:
--  absence of runtime errors for every Depth, the ring invariant, and the
--  Count contracts. Run it with prove/prove.gpr (see that file).
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
--  object is not. Indices are a Natural subtype advanced with Add (in
--  the private part), which wraps without overflowing.

generic
   type Element_Type is private;
   Depth : Positive;
package Beacon.Queue
  with SPARK_Mode => On
is

   --  Carries the type invariant Tail = (Head + Fill) mod Depth. SPARK
   --  only accepts Type_Invariant on the full view, so it is in the
   --  private part.
   type Queue_Type is private;

   --  The ring buffer invariant, Tail = (Head + Fill) mod Depth. Visible
   --  so callers and verification suites can check consistency.
   function Invariant (Q : Queue_Type) return Boolean;

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
                  and then Count (Q) = (if Dropped then Depth else Count (Q'Old) + 1);

   procedure Pop (Q : in out Queue_Type; Item : out Element_Type)
     with Pre  => not Is_Empty (Q),
          Post => Count (Q) = Count (Q'Old) - 1;

private

   subtype Ring_Index is Natural range 0 .. Depth - 1;

   --  (I + K) mod Depth, written so that nothing overflows even when
   --  Depth is close to Positive'Last.
   function Add (I : Ring_Index; K : Natural) return Ring_Index is
     (if K < Depth - I then I + K else K - (Depth - I))
     with Pre => K <= Depth;

   --  Relaxed_Initialization: Element_Type may have no default value, so
   --  Buffer starts uninitialized. The type invariant below states which
   --  slots are initialized: exactly the Fill slots starting at Head,
   --  which are the only ones ever read.
   type Element_Array is array (Ring_Index) of Element_Type
     with Relaxed_Initialization;

   type Queue_Type is record
      Buffer : Element_Array;
      Head   : Ring_Index := 0;   --  next slot to Pop
      Tail   : Ring_Index := 0;   --  next slot to Push
      Fill   : Natural range 0 .. Depth := 0;
   end record
     with Type_Invariant =>
       Tail = Add (Head, Fill)
       and then (for all K in 0 .. Fill - 1 => Buffer (Add (Head, K))'Initialized);
   --  The invariant is written on the components because SPARK does not
   --  let it call Invariant, a boundary function of its own type.

   function Count (Q : Queue_Type) return Natural is (Q.Fill);

   function Invariant (Q : Queue_Type) return Boolean is
     (Q.Tail = Add (Q.Head, Q.Fill));

   pragma Warnings (Off, "component ""Buffer"" of type ""Element_Array"" is uninitialized");
   Empty_Queue : constant Queue_Type := (Buffer => <>, Head => 0, Tail => 0, Fill => 0);
   pragma Warnings (On, "component ""Buffer"" of type ""Element_Array"" is uninitialized");

end Beacon.Queue;
