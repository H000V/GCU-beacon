--  Arbitrary has no postcondition and its body is hidden from the
--  prover, so all GNATprove knows about the result is that it is
--  Positive. An instance using it as Depth is proved for every Depth,
--  from 1 to Positive'Last.

package Proof_Depth
  with SPARK_Mode => On
is

   function Arbitrary return Positive
     with Global => null;

end Proof_Depth;
