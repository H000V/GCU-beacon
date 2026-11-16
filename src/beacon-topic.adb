package body Beacon.Topic is

   -------------------
   -- Bounded_Queue --
   -------------------

   protected body Bounded_Queue is

      --  Call after every change to Q, so the barriers stay correct.
      procedure Refresh_Flags;
      procedure Refresh_Flags is
      begin
         Full  := Ring.Is_Full (Q);
         Empty := Ring.Is_Empty (Q);
      end Refresh_Flags;

      entry Push (Msg : Message_Type)
        when Mode = Best_Effort or else not Full
      is
         Dropped : Boolean;
      begin
         if Mode = Best_Effort then
            Ring.Push_Dropping_Oldest (Q, Msg, Dropped);
            if Dropped then
               Drops := (if Drops = Natural'Last then Drops else Drops + 1);
            end if;
         else
            Ring.Push (Q, Msg);
         end if;
         Refresh_Flags;
      end Push;

      procedure Try_Push (Msg : Message_Type; Accepted : out Boolean) is
         Dropped : Boolean;
      begin
         if Mode = Best_Effort then
            Ring.Push_Dropping_Oldest (Q, Msg, Dropped);
            if Dropped then
               Drops := (if Drops = Natural'Last then Drops else Drops + 1);
            end if;
            Accepted := True;
         elsif Ring.Is_Full (Q) then
            Accepted := False;
         else
            Ring.Push (Q, Msg);
            Accepted := True;
         end if;
         Refresh_Flags;
      end Try_Push;

      entry Pop (Msg : out Message_Type) when not Empty is
      begin
         Ring.Pop (Q, Msg);
         Refresh_Flags;
      end Pop;

      procedure Try_Pop (Msg : out Message_Type; Success : out Boolean) is
      begin
         Success := not Ring.Is_Empty (Q);
         if Success then
            Ring.Pop (Q, Msg);
            Refresh_Flags;
         end if;
      end Try_Pop;

      function Count return Natural is (Ring.Count (Q));
      function Drop_Count return Natural is (Drops);

   end Bounded_Queue;

   --------------
   -- Registry --
   --------------

   --  Static table, filled at startup. Not protected on purpose: see spec.
   type Subscriber_Access is access all Subscriber;
   type Registry_Array is array (1 .. Max_Subscribers) of Subscriber_Access;

   Registry        : Registry_Array := [others => null];
   Registered      : Natural := 0;
   Publisher_Taken : Boolean := False;

   --  Set by the publisher's task, read by whoever registers. Atomic so
   --  that read is defined; see the spec for what the lock does not cover.
   Locked : Boolean := False with Atomic;

   --  Called before the fan-out, so a registration that races the first
   --  Publish is more likely to see the lock. Writes once, not per message.
   procedure Lock;
   procedure Lock is
   begin
      if not Locked then
         Locked := True;
      end if;
   end Lock;

   ---------------
   -- Publisher --
   ---------------

   function Has_Publisher return Boolean is (Publisher_Taken);
   function Is_Created (P : Publisher) return Boolean is (P.Created);
   function Is_Locked return Boolean is (Locked);

   procedure Create_Publisher (P : in out Publisher) is
   begin
      Publisher_Taken := True;
      P.Created := True;
   end Create_Publisher;

   procedure Publish (P : Publisher; Msg : Message_Type) is
      pragma Unreferenced (P);  --  the precondition is the whole use
   begin
      Lock;
      for I in 1 .. Registered loop
         Registry (I).Queue.Push (Msg);
      end loop;
   end Publish;

   procedure Try_Publish
     (P         : Publisher;
      Msg       : Message_Type;
      Delivered : out Boolean)
   is
      pragma Unreferenced (P);
      Accepted : Boolean;
   begin
      Lock;
      Delivered := True;
      for I in 1 .. Registered loop
         Registry (I).Queue.Try_Push (Msg, Accepted);
         Delivered := Delivered and Accepted;
      end loop;
   end Try_Publish;

   ----------------
   -- Subscriber --
   ----------------

   function Subscriber_Count return Natural is (Registered);
   function Is_Registered (S : Subscriber) return Boolean is (S.Registered);

   procedure Create_Subscriber (S : aliased in out Subscriber) is
   begin
      Registered := Registered + 1;
      Registry (Registered) := S'Unchecked_Access;
      S.Registered := True;
   end Create_Subscriber;

   procedure Delete_Subscriber (S : aliased in out Subscriber) is
      Target : constant Subscriber_Access := S'Unchecked_Access;
   begin
      for I in 1 .. Registered loop
         if Registry (I) = Target then
            --  Close the gap and keep registration order (the spec
            --  promises fan-out in registration order).
            Registry (I .. Registered - 1) := Registry (I + 1 .. Registered);
            Registry (Registered) := null;
            Registered := Registered - 1;
            S.Registered := False;
            return;
         end if;
      end loop;
      --  Not reached: Is_Registered (S) means S is in the table.
   end Delete_Subscriber;

   procedure Receive (S : in out Subscriber; Msg : out Message_Type) is
   begin
      S.Queue.Pop (Msg);
   end Receive;

   procedure Try_Receive
     (S       : in out Subscriber;
      Msg     : out Message_Type;
      Success : out Boolean) is
   begin
      S.Queue.Try_Pop (Msg, Success);
   end Try_Receive;

   function Pending (S : Subscriber) return Natural is (S.Queue.Count);
   function Dropped (S : Subscriber) return Natural is (S.Queue.Drop_Count);

end Beacon.Topic;
