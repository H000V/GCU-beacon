--  Beacon.Transport.UDP: multicast datagram transport, desktop only.
--
--  One frame per datagram. Max_Frame (1038 bytes) fits in a single
--  Ethernet MTU, so no fragmentation handling is needed.
--  Static participant configuration (design rule 4): the group and port
--  are given at Open, nothing is discovered.

with GNAT.Sockets;

package Beacon.Transport.UDP is

   type UDP_Transport is limited new Transport with private;

   procedure Open
     (T     : in out UDP_Transport;
      Group : String;                 --  e.g. "239.255.0.1"
      Port  : GNAT.Sockets.Port_Type);

   procedure Close (T : in out UDP_Transport);

   overriding procedure Send
     (T : in out UDP_Transport; Frame : Wire.Byte_Array);

   overriding procedure Receive
     (T       : in out UDP_Transport;
      Frame   : out Wire.Byte_Array;
      Count   : out Natural;
      Timeout : Duration);

private

   type UDP_Transport is limited new Transport with record
      Socket : GNAT.Sockets.Socket_Type := GNAT.Sockets.No_Socket;
      Group  : GNAT.Sockets.Sock_Addr_Type;
   end record;

end Beacon.Transport.UDP;
