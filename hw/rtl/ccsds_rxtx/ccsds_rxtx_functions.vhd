-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_functions
---- Version: 1.0.0
---- Description:
---- TO BE DONE
-------------------------------
---- Author(s):
---- Guillaume Rembert
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2015/12/28: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ccsds_rxtx_functions is
-- simulation : testbench only functions
  procedure simGetRandomBitVector(vectorSize : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector);
-- synthetizable functions
end ccsds_rxtx_functions;

package body ccsds_rxtx_functions is
  procedure simGetRandomBitVector(vectorSize : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector) is
    variable rand : real := 0.0;
  begin
--    report "DEBUG: Seeds values => seed1 = " & positive'image(seed1) & " seed2 = " &  positive'image(seed2) severity warning;
    uniform(seed1, seed2, rand);
--    report "DEBUG: Random value => rand = " & real'image(rand) severity warning;
--    report "DEBUG: Seeds values => seed1 = " & positive'image(seed1) & " seed2 = " &  positive'image(seed2) severity warning;
    rand := rand*(2**(real(vectorSize)-1.0));
--    report "DEBUG: Random value => rand = " & real'image(rand) severity warning;
    result := std_logic_vector(to_unsigned(integer(rand),vectorSize));
  end simGetRandomBitVector;
end ccsds_rxtx_functions;
