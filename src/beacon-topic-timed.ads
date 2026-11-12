--  Beacon.Topic.Timed: Receive with a timeout, for full runtimes only.
--
--     package Telemetry_Topic is new Beacon.Topic (...);
--     package Telemetry_Timed is new Telemetry_Topic.Timed;
--
--  The timeout is a timed entry call (a select statement with a delay),
--  which the Jorvik and Ravenscar profiles forbid. Keeping it in this
--  child package lets the parent, Beacon.Topic, compile under Jorvik.
--  Do not instantiate this package in a Jorvik build.

with Ada.Real_Time;

generic
package Beacon.Topic.Timed is

   --  Blocks until a message is available or Timeout elapses.
   --  Success is True if a message was retrieved, False on timeout.
   --  A zero or negative Timeout polls once and never blocks.
   procedure Receive
     (S       : in out Subscriber;
      Msg     : out Message_Type;
      Timeout : Ada.Real_Time.Time_Span;
      Success : out Boolean)
     with Pre => Is_Registered (S);

end Beacon.Topic.Timed;
