--  Telemetry: the message types and topic instantiations shared by every
--  demo program. This file IS the static topic registry (design rule 4):
--  a process that withs it knows every topic and every type at compile time.

with Beacon.Topic;
with System;

package Telemetry is

   type Sensor_Id is range 0 .. 255 with Size => 8;

   --  Wire-ready record: representation clause here means Serialize in
   --  the bridge is an overlay, not a hand-packed buffer.
   type Reading is record
      Sensor      : Sensor_Id;
      Sequence    : Natural;
      Temperature : Float;
   end record
     with Size                 => 72,
          Bit_Order            => System.High_Order_First,
          Scalar_Storage_Order => System.High_Order_First;
   --  Network byte order by declaration, so the codec is an overlay.
   for Reading use record
      Sensor      at 0 range 0 .. 7;
      Sequence    at 1 range 0 .. 31;
      Temperature at 5 range 0 .. 31;
   end record;

   type Command_Kind is (Start, Stop, Reset);
   type Command is record
      Kind   : Command_Kind;
      Target : Sensor_Id;
   end record;

   --  High rate, latest value matters: subscribers use Best_Effort.
   package Temperature_Topic is new Beacon.Topic
     (Message_Type => Reading, Queue_Depth => 32);

   --  Low rate, every message matters: subscribers use Reliable.
   package Command_Topic is new Beacon.Topic
     (Message_Type => Command, Queue_Depth => 8);

   --  Wire topic ids for the network demo. One per instantiation.
   Temperature_Topic_Id : constant := 1;
   Command_Topic_Id     : constant := 2;

end Telemetry;
