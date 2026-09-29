--  Beacon.Wire: frame layout for the network backend.
--
--  Design rule 6: the header is a record with a representation clause.
--  No shifts, no masks. The header is placed over the first
--  Header_Length bytes of a frame by an overlay, and network byte order
--  is obtained with Scalar_Storage_Order, not by hand.
--
--  Frame (DRAFT, signed off at Week 13 review):
--
--     byte  size  field
--     0     2     Magic          16#BEAC#
--     2     2     Topic          Topic_Id_Type, assigned statically per Bridge
--     4     4     Sequence       per-topic, wraps
--     8     2     Length         payload bytes that follow the header
--     10    4     Checksum       over header (with Checksum = 0) + payload
--     14    L     Payload        L = Length, serialized Message_Type
--
--  Bytes exist here and in Beacon.Bridge only. They never reach
--  Beacon.Topic's API (design rule 1).

with Interfaces;
with System;

package Beacon.Wire is

   type Byte is mod 2 ** 8 with Size => 8;
   type Byte_Array is array (Positive range <>) of Byte with Pack;

   Max_Payload   : constant := 1024;
   Header_Length : constant := 14;
   Max_Frame     : constant := Header_Length + Max_Payload;

   Magic_Value : constant := 16#BEAC#;

   type Topic_Id_Type  is range 0 .. 2 ** 16 - 1 with Size => 16;
   type Sequence_Type  is mod 2 ** 32 with Size => 32;
   type Length_Type    is range 0 .. Max_Payload with Size => 16;
   type Checksum_Type  is mod 2 ** 32 with Size => 32;

   type Header is record
      Magic    : Interfaces.Unsigned_16;
      Topic    : Topic_Id_Type;
      Sequence : Sequence_Type;
      Length   : Length_Type;
      Checksum : Checksum_Type;
   end record
     with Size                 => Header_Length * 8,
          Bit_Order            => System.High_Order_First,
          Scalar_Storage_Order => System.High_Order_First;

   for Header use record
      Magic    at 0  range 0 .. 15;
      Topic    at 2  range 0 .. 15;
      Sequence at 4  range 0 .. 31;
      Length   at 8  range 0 .. 15;
      Checksum at 10 range 0 .. 31;
   end record;

   type Decode_Status is
     (Ok,
      Too_Short,        --  fewer than Header_Length bytes
      Bad_Magic,
      Bad_Length,       --  Length field disagrees with bytes available
      Bad_Checksum);

   --  CRC-32 (IEEE 802.3, the zlib one). Fixed; not a Week 13 decision
   --  any more. Test vector: "123456789" -> 16#CBF43926#.
   function Checksum (Data : Byte_Array) return Checksum_Type;

   procedure Encode
     (Topic    : Topic_Id_Type;
      Sequence : Sequence_Type;
      Payload  : Byte_Array;
      Frame    : out Byte_Array;
      Last     : out Natural)
     with Pre  => Payload'Length <= Max_Payload
                  and then Frame'Length >= Max_Frame,
          Post => Last = Frame'First + Header_Length + Payload'Length - 1;

   --  Payload_Last is the last valid index of Payload on Ok. Frame must
   --  be exactly one frame (Header_Length + Length bytes); a datagram
   --  with trailing bytes is Bad_Length.
   procedure Decode
     (Frame        : Byte_Array;
      Topic        : out Topic_Id_Type;
      Sequence     : out Sequence_Type;
      Payload      : out Byte_Array;
      Payload_Last : out Natural;
      Status       : out Decode_Status)
     with Pre => Payload'Length >= Max_Payload;

end Beacon.Wire;
