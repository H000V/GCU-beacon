--  Beacon.Transport: how a frame leaves and enters the process.
--
--  Beacon.Bridge talks to this interface. The only implementation in
--  scope is UDP multicast (Beacon.Transport.UDP). A loopback in-memory
--  transport is a good first thing to write for tests.

with Beacon.Wire;

package Beacon.Transport is

   type Transport is limited interface;

   procedure Send
     (T : in out Transport; Frame : Wire.Byte_Array) is abstract;

   --  Blocks up to Timeout. Count = 0 on timeout.
   procedure Receive
     (T       : in out Transport;
      Frame   : out Wire.Byte_Array;
      Count   : out Natural;
      Timeout : Duration) is abstract;

end Beacon.Transport;
