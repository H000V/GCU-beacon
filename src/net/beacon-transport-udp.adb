with Ada.Streams;
with Ada.Unchecked_Conversion;

package body Beacon.Transport.UDP is

   use GNAT.Sockets;

   --  The one place bytes change type. Same element size, same layout.
   subtype Frame_Elems is Ada.Streams.Stream_Element_Array
     (1 .. Ada.Streams.Stream_Element_Offset (Wire.Max_Frame));
   subtype Frame_Bytes is Wire.Byte_Array (1 .. Wire.Max_Frame);
   function To_Elems is new Ada.Unchecked_Conversion (Frame_Bytes, Frame_Elems);
   function To_Bytes is new Ada.Unchecked_Conversion (Frame_Elems, Frame_Bytes);

   ----------
   -- Open --
   ----------

   procedure Open
     (T     : in out UDP_Transport;
      Group : String;
      Port  : Port_Type)
   is
      Any : Sock_Addr_Type;
   begin
      T.Group := (Family => Family_Inet, Addr => Inet_Addr (Group), Port => Port);
      Create_Socket (T.Socket, Family_Inet, Socket_Datagram);
      Set_Socket_Option (T.Socket, Socket_Level, (Reuse_Address, True));
      Any := (Family => Family_Inet, Addr => Any_Inet_Addr, Port => Port);
      Bind_Socket (T.Socket, Any);
      Set_Socket_Option
        (T.Socket, IP_Protocol_For_IP_Level,
         (Add_Membership, Inet_Addr (Group), Any_Inet_Addr));
      Set_Socket_Option (T.Socket, IP_Protocol_For_IP_Level, (Multicast_TTL, 1));
      Set_Socket_Option (T.Socket, IP_Protocol_For_IP_Level, (Multicast_Loop, True));
   end Open;

   -----------
   -- Close --
   -----------

   procedure Close (T : in out UDP_Transport) is
   begin
      if T.Socket /= No_Socket then
         Close_Socket (T.Socket);
         T.Socket := No_Socket;
      end if;
   end Close;

   ----------
   -- Send --
   ----------

   overriding procedure Send
     (T : in out UDP_Transport; Frame : Wire.Byte_Array)
   is
      Buf  : Frame_Bytes := [others => 0];
      Last : Ada.Streams.Stream_Element_Offset;
      N    : constant Ada.Streams.Stream_Element_Offset :=
        Ada.Streams.Stream_Element_Offset (Frame'Length);
   begin
      Buf (1 .. Frame'Length) := Frame;
      declare
         E : constant Frame_Elems := To_Elems (Buf);
      begin
         Send_Socket (T.Socket, E (1 .. N), Last, T.Group);
      end;
   end Send;

   -------------
   -- Receive --
   -------------

   overriding procedure Receive
     (T       : in out UDP_Transport;
      Frame   : out Wire.Byte_Array;
      Count   : out Natural;
      Timeout : Duration)
   is
      Sel    : Selector_Type;
      R, W   : Socket_Set_Type;
      Status : Selector_Status;
      E      : Frame_Elems := [others => 0];
      Last   : Ada.Streams.Stream_Element_Offset;
      From   : Sock_Addr_Type;
   begin
      Frame := [others => 0];
      Count := 0;
      Create_Selector (Sel);
      Empty (R); Empty (W);
      Set (R, T.Socket);
      Check_Selector (Sel, R, W, Status, Timeout);
      Close_Selector (Sel);
      if Status /= Completed then
         return;
      end if;
      Receive_Socket (T.Socket, E, Last, From);
      Count := Natural (Last);
      declare
         B : constant Frame_Bytes := To_Bytes (E);
      begin
         Frame (Frame'First .. Frame'First + Count - 1) := B (1 .. Count);
      end;
   end Receive;

end Beacon.Transport.UDP;
