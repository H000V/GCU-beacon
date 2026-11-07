pragma SPARK_Mode (On);

--  The Beacon.Queue instance GNATprove analyzes.
--
--  Library level on purpose: SPARK only accepts a Type_Invariant on a
--  type declared in a library-level package. Integer has no default
--  value, which is the hard case for the deliberately uninitialized
--  Buffer.

with Beacon.Queue;
with Proof_Depth;

package Integer_Queue is new Beacon.Queue
  (Element_Type => Integer, Depth => Proof_Depth.Arbitrary);
