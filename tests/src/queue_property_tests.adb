--  Property-based tests for Beacon.Queue (Task 3.2). Owner: validation
--  engineer.
--
--  GNATprove proves the ring has no runtime errors, keeps its invariant
--  and honours the Count contracts (Task 3.1). It does not prove FIFO
--  order. This suite checks that, and the rest of the queue's observable
--  behaviour, against a reference model over long random operation
--  sequences:
--
--    P1  FIFO: every Pop returns exactly the element the model says is
--        oldest (sequence number and payload).
--    P2  Drop-oldest: Push_Dropping_Oldest reports Dropped exactly when
--        the queue was full, and the element lost is the oldest one.
--    P3  Head/tail consistency: Invariant (Tail = Head + Fill mod Depth)
--        holds after every operation. The Type_Invariant on the full
--        view is also checked at every call boundary (-gnata).
--    P4  Fill level: Count, Is_Empty and Is_Full agree with the model.
--    P5  Accounting: Pushed = Popped + Dropped + Count, at every step.
--    P6  Contracts: Push on a full queue and Pop on an empty one raise
--        Assertion_Error and leave the queue unchanged.
--
--  The model is a plain array that shifts on every pop. It shares no
--  code or index arithmetic with the ring, so a wrap-around bug in the
--  ring cannot be mirrored in the model.
--
--  Inputs are pseudo-random but reproducible. Each depth uses its own
--  seed derived from the base seed, and a failure prints the seed, the
--  depth and the step, plus the operations leading up to it.
--
--     queue_property_tests [seed [ops_per_depth]]
--
--  Defaults: seed 20261108, 1_000_000 operations per depth.

with Ada.Assertions;
with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;
with Beacon.Queue;

procedure Queue_Property_Tests is

   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;

   Default_Seed : constant := 20_261_108;
   Default_Ops  : constant := 1_000_000;

   --  Depth 1 is the degenerate ring (Head = Tail always); 2 and 3 are
   --  the smallest real wraps; powers of two and their neighbours catch
   --  off-by-one errors that a mask-based implementation would hide.
   Depths : constant array (Positive range <>) of Positive :=
     [1, 2, 3, 4, 5, 7, 8, 9, 16, 31, 64, 100];

   type Rand is range 0 .. 2**30 - 1;
   package Random is new Ada.Numerics.Discrete_Random (Rand);

   type Element is record
      Seq     : Natural;   --  push order, 1-based
      Payload : Integer;   --  random, so a stale slot is not mistaken for a fresh one
   end record;

   Total_Failures : Natural := 0;
   Seed           : Integer := Default_Seed;
   Ops_Per_Depth  : Natural := Default_Ops;

   ---------------------------------------------------------------------

   generic
      Depth : Positive;
      Seed  : Integer;
      Ops   : Natural;
   procedure Run_Depth;

   procedure Run_Depth is

      package Q is new Beacon.Queue (Element_Type => Element, Depth => Depth);
      use Q;

      --  Reference model: front is Model (1), no ring arithmetic.
      Model      : array (1 .. Depth) of Element;
      Model_Fill : Natural range 0 .. Depth := 0;

      procedure Model_Push (E : Element);
      procedure Model_Push (E : Element) is
      begin
         Model_Fill := Model_Fill + 1;
         Model (Model_Fill) := E;
      end Model_Push;

      procedure Model_Pop (E : out Element);
      procedure Model_Pop (E : out Element) is
      begin
         E := Model (1);
         Model (1 .. Model_Fill - 1) := Model (2 .. Model_Fill);
         Model_Fill := Model_Fill - 1;
      end Model_Pop;

      type Op_Kind is (Push_Op, Push_Drop_Op, Pop_Op, Push_Full_Guard, Pop_Empty_Guard);

      --  The last few operations, printed on failure.
      Trace_Len : constant := 12;
      type Trace_Entry is record
         Step : Natural := 0;
         Kind : Op_Kind := Push_Op;
         Fill : Natural := 0;
      end record;
      Trace : array (0 .. Trace_Len - 1) of Trace_Entry;

      --  Phases bias the generator towards filling, draining or neither,
      --  so every run spends time at both boundaries and wraps many times.
      type Phase is (Filling, Draining, Balanced);
      Push_Percent : constant array (Phase) of Rand :=
        [Filling => 80, Draining => 20, Balanced => 50];

      Gen          : Random.Generator;
      Ring         : Queue_Type := Empty_Queue;
      Current      : Phase := Balanced;
      Phase_Left   : Natural := 0;
      Next_Seq     : Natural := 0;
      Pushed       : Natural := 0;
      Popped       : Natural := 0;
      Drops        : Natural := 0;
      Last_Popped  : Natural := 0;
      Times_Full   : Natural := 0;
      Times_Empty  : Natural := 0;
      Guards       : Natural := 0;
      Failed       : Boolean := False;

      function Roll (Bound : Rand) return Rand is (Random.Random (Gen) mod Bound);

      procedure Fail (Step : Natural; What : String);
      procedure Fail (Step : Natural; What : String) is
      begin
         Failed := True;
         Total_Failures := Total_Failures + 1;
         Put_Line ("  FAIL  depth" & Depth'Image & ", seed" & Seed'Image
                   & ", step" & Step'Image & ": " & What);
         Put_Line ("        recent operations (oldest first):");
         for I in 1 .. Trace_Len loop
            declare
               T : Trace_Entry renames Trace ((Step + I) mod Trace_Len);
            begin
               if T.Step > 0 or else I = Trace_Len then
                  Put_Line ("          step" & T.Step'Image & "  " & T.Kind'Image
                            & "  fill before" & T.Fill'Image);
               end if;
            end;
         end loop;
      end Fail;

      procedure Check (Step : Natural; Cond : Boolean; What : String);
      procedure Check (Step : Natural; Cond : Boolean; What : String) is
      begin
         if not Cond and then not Failed then
            Fail (Step, What);
         end if;
      end Check;

      function Fresh return Element;
      function Fresh return Element is
      begin
         Next_Seq := Next_Seq + 1;
         return (Seq => Next_Seq, Payload => Integer (Random.Random (Gen)));
      end Fresh;

      function Choose return Op_Kind;
      function Choose return Op_Kind is
         Wants_Push : constant Boolean := Roll (100) < Push_Percent (Current);
      begin
         if Wants_Push then
            if Model_Fill = Depth then
               return (if Roll (100) < 85 then Push_Drop_Op else Push_Full_Guard);
            else
               return (if Roll (2) = 0 then Push_Op else Push_Drop_Op);
            end if;
         elsif Model_Fill = 0 then
            return (if Roll (100) < 15 then Pop_Empty_Guard else Push_Op);
         else
            return Pop_Op;
         end if;
      end Choose;

      procedure Step_Once (Step : Positive);
      procedure Step_Once (Step : Positive) is
         Kind    : Op_Kind;
         Before  : constant Natural := Model_Fill;
         E, Got  : Element;
         Dropped : Boolean;
      begin
         if Phase_Left = 0 then
            Current    := Phase'Val (Roll (3));
            Phase_Left := Natural (Roll (Rand (4 * Depth + 4))) + 1;
         end if;
         Phase_Left := Phase_Left - 1;

         Kind := Choose;
         Trace (Step mod Trace_Len) := (Step => Step, Kind => Kind, Fill => Before);

         case Kind is
            when Push_Op =>
               E := Fresh;
               Push (Ring, E);
               Model_Push (E);
               Pushed := Pushed + 1;

            when Push_Drop_Op =>
               E := Fresh;
               Push_Dropping_Oldest (Ring, E, Dropped);
               Check (Step, Dropped = (Before = Depth), "P2 Dropped flag disagrees with model");
               if Before = Depth then
                  Model_Pop (Got);       --  the element the queue should have lost
                  Check (Step, Got.Seq > Last_Popped, "P2 dropped element older than one popped");
                  Last_Popped := Got.Seq;
                  Drops := Drops + 1;
               end if;
               Model_Push (E);
               Pushed := Pushed + 1;

            when Pop_Op =>
               Pop (Ring, Got);
               Model_Pop (E);
               Check (Step, Got = E,
                      "P1 popped seq" & Got.Seq'Image & ", expected" & E.Seq'Image);
               Check (Step, Got.Seq > Last_Popped, "P1 sequence numbers not increasing");
               Last_Popped := Got.Seq;
               Popped := Popped + 1;

            when Push_Full_Guard =>
               Guards := Guards + 1;
               begin
                  Push (Ring, (Seq => 0, Payload => 0));
                  Check (Step, False, "P6 Push on a full queue was accepted");
               exception
                  when Ada.Assertions.Assertion_Error => null;
               end;

            when Pop_Empty_Guard =>
               Guards := Guards + 1;
               begin
                  Pop (Ring, Got);
                  Check (Step, False, "P6 Pop on an empty queue was accepted");
               exception
                  when Ada.Assertions.Assertion_Error => null;
               end;
         end case;

         Check (Step, Invariant (Ring), "P3 ring invariant broken");
         Check (Step, Count (Ring) = Model_Fill,
                "P4 Count" & Count (Ring)'Image & ", model" & Model_Fill'Image);
         Check (Step, Is_Empty (Ring) = (Model_Fill = 0), "P4 Is_Empty disagrees with model");
         Check (Step, Is_Full (Ring) = (Model_Fill = Depth), "P4 Is_Full disagrees with model");
         Check (Step, Pushed = Popped + Drops + Count (Ring), "P5 accounting does not balance");

         if Model_Fill = Depth then
            Times_Full := Times_Full + 1;
         elsif Model_Fill = 0 then
            Times_Empty := Times_Empty + 1;
         end if;
      end Step_Once;

      Got, E : Element;

   begin
      Random.Reset (Gen, Seed);

      for Step in 1 .. Ops loop
         begin
            Step_Once (Step);
         exception
            --  A failed Type_Invariant or postcondition lands here. Report
            --  it with the seed and step instead of aborting the suite.
            when X : others =>
               Fail (Step, "unexpected exception: " & Ada.Exceptions.Exception_Information (X));
         end;
         exit when Failed;
      end loop;

      --  Drain what is left; it must come out in model order.
      while not Failed and then not Is_Empty (Ring) loop
         Pop (Ring, Got);
         Model_Pop (E);
         Check (Ops, Got = E, "P1 final drain out of order");
         Popped := Popped + 1;
      end loop;
      Check (Ops, Model_Fill = 0, "P4 model not empty after drain");
      Check (Ops, Pushed = Popped + Drops, "P5 accounting does not balance after drain");

      --  Coverage: a run that never reached both boundaries or never
      --  wrapped has not tested what it claims to.
      if Ops >= 1_000 then
         Check (Ops, Times_Full > 0 and then Times_Empty > 0, "coverage: a boundary was never hit");
         Check (Ops, Drops > 0, "coverage: no drop-oldest path taken");
         Check (Ops, Pushed > 2 * Depth, "coverage: ring never wrapped");
      end if;

      if not Failed then
         Put_Line ("  ok    depth" & Depth'Image & ":" & Ops'Image & " ops," & Pushed'Image
                   & " pushed," & Popped'Image & " popped," & Drops'Image & " dropped,"
                   & Times_Full'Image & " full," & Times_Empty'Image & " empty,"
                   & Guards'Image & " guards");
      end if;
   end Run_Depth;

   ---------------------------------------------------------------------

   use Ada.Command_Line;

begin
   if Argument_Count >= 1 then
      Seed := Integer'Value (Argument (1));
   end if;
   if Argument_Count >= 2 then
      Ops_Per_Depth := Natural'Value (Argument (2));
   end if;

   Put_Line ("Beacon.Queue property tests (seed" & Seed'Image
             & "," & Ops_Per_Depth'Image & " ops per depth)");

   for I in Depths'Range loop
      declare
         procedure Run is new Run_Depth
           (Depth => Depths (I), Seed => Seed + I, Ops => Ops_Per_Depth);
      begin
         Run;
      end;
   end loop;

   Ada.Text_IO.New_Line;
   if Total_Failures = 0 then
      Put_Line ("all passed");
   else
      Put_Line (Natural'Image (Total_Failures) & " failure(s)");
      Set_Exit_Status (Failure);
   end if;
end Queue_Property_Tests;
