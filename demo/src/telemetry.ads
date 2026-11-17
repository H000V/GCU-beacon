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

   ------------------------------------------------------------------
   --  Flight topics (Task 3.5): a small satellite, used by inproc_demo.
   --  In-process only, so no representation clauses and no wire ids.
   ------------------------------------------------------------------

   --  Where the satellite points, in degrees. ~1 kHz from the attitude
   --  sensor. Only the newest matters: subscribers use Best_Effort.
   type Attitude is record
      Sequence : Natural := 0;
      Roll     : Float   := 0.0;
      Pitch    : Float   := 0.0;
      Yaw      : Float   := 0.0;
   end record;

   --  Reaction-wheel torque command from the attitude controller,
   --  ~100 Hz. Each command replaces the last, and the control loop must
   --  never wait on a slow consumer: subscribers use Best_Effort.
   --  For_Attitude is the attitude sample the command was computed from.
   type Wheel_Command is record
      Sequence     : Natural := 0;
      For_Attitude : Natural := 0;
      Torque_Roll  : Float   := 0.0;
      Torque_Pitch : Float   := 0.0;
      Torque_Yaw   : Float   := 0.0;
   end record;

   --  Battery housekeeping, ~5 Hz. Slow, and a missed low-battery
   --  reading matters: subscribers use Reliable.
   subtype Percent is Float range 0.0 .. 100.0;
   type Power_Status is record
      Sequence      : Natural := 0;
      Battery_Volts : Float   := 0.0;
      Charge        : Percent := 0.0;
   end record;

   --  Commands uplinked from the ground. Every one must arrive, in
   --  order: subscribers use Reliable.
   type Flight_Mode is (Nominal, Safe);
   type Ground_Command_Kind is (Ping, Set_Mode);
   type Ground_Command is record
      Sequence : Natural := 0;
      Kind     : Ground_Command_Kind := Ping;
      Mode     : Flight_Mode := Nominal;  --  used when Kind = Set_Mode
   end record;

   package Attitude_Topic is new Beacon.Topic
     (Message_Type => Attitude, Queue_Depth => 32);

   package Wheel_Topic is new Beacon.Topic
     (Message_Type => Wheel_Command, Queue_Depth => 16);

   package Power_Topic is new Beacon.Topic
     (Message_Type => Power_Status, Queue_Depth => 8);

   package Ground_Topic is new Beacon.Topic
     (Message_Type => Ground_Command, Queue_Depth => 8);

   --  Wire topic ids for the network demo. One per instantiation.
   Temperature_Topic_Id : constant := 1;
   Command_Topic_Id     : constant := 2;

end Telemetry;
