package body Proof_Depth
  with SPARK_Mode => Off  --  hides the value from the prover on purpose
is

   function Arbitrary return Positive is (8);

end Proof_Depth;
