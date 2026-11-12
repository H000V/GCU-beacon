package body Beacon.Topic.Timed is

   use Ada.Real_Time;

   procedure Receive
     (S       : in out Subscriber;
      Msg     : out Message_Type;
      Timeout : Ada.Real_Time.Time_Span;
      Success : out Boolean) is
   begin
      if Timeout <= Time_Span_Zero then
         S.Queue.Try_Pop (Msg, Success);
      else
         select
            S.Queue.Pop (Msg);
            Success := True;
         or
            delay until Clock + Timeout;
            Success := False;
         end select;
      end if;
   end Receive;

end Beacon.Topic.Timed;
