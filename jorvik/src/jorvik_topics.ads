--  A Beacon.Topic instance with one subscriber of each mode, declared at
--  library level as the Jorvik profile requires (no local protected
--  objects). Compiling this unit is what checks the generic.

with Beacon;
with Beacon.Topic;

package Jorvik_Topics is

   type Reading is record
      Id    : Natural;
      Value : Float;
   end record;

   Depth : constant := 4;

   package Topic is new Beacon.Topic
     (Message_Type => Reading, Queue_Depth => Depth, Max_Subscribers => 2);

   Pub  : Topic.Publisher;
   Rel  : aliased Topic.Subscriber (Beacon.Reliable);
   Best : aliased Topic.Subscriber (Beacon.Best_Effort);

end Jorvik_Topics;
