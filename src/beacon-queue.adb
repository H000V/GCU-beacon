package body Beacon.Queue
  with SPARK_Mode => On
is

   function Next (I : Ring_Index) return Ring_Index is
     (Add (I, 1));

   procedure Push (Q : in out Queue_Type; Item : Element_Type) is
   begin
      Q.Buffer (Q.Tail) := Item;
      Q.Tail := Next (Q.Tail);
      Q.Fill := Q.Fill + 1;
      pragma Assert (Invariant (Q));
   end Push;

   procedure Push_Dropping_Oldest
     (Q       : in out Queue_Type;
      Item    : Element_Type;
      Dropped : out Boolean)
   is
      Old_Head : constant Ring_Index := Q.Head with Ghost;
   begin
      Dropped := Is_Full (Q);
      if Dropped then
         --  Full means Tail = Head: the slot written is the oldest one.
         --  Advance Head past it; Fill stays at Depth.
         Q.Head := Next (Q.Head);
         Q.Buffer (Q.Tail) := Item;
         Q.Tail := Next (Q.Tail);

         --  Proof guidance: the live slots, seen from the new Head, are
         --  the old ones shifted by one, then the slot just written.
         pragma Assert
           (for all K in 0 .. Depth - 2 => Add (Q.Head, K) = Add (Old_Head, K + 1));
         pragma Assert (Add (Q.Head, Depth - 1) = Old_Head);
      else
         Push (Q, Item);
      end if;
      pragma Assert (Invariant (Q));
   end Push_Dropping_Oldest;

   procedure Pop (Q : in out Queue_Type; Item : out Element_Type) is
      Old_Head : constant Ring_Index := Q.Head with Ghost;
   begin
      Item := Q.Buffer (Q.Head);
      Q.Head := Next (Q.Head);
      Q.Fill := Q.Fill - 1;

      --  Proof guidance: the remaining slots are the old ones shifted by one.
      pragma Assert
        (for all K in 0 .. Q.Fill - 1 => Add (Q.Head, K) = Add (Old_Head, K + 1));
      pragma Assert (Invariant (Q));
   end Pop;

end Beacon.Queue;
