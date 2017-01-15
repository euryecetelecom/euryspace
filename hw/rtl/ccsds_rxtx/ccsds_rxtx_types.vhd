-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_types
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
---- 2017/01/15: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

package ccsds_rxtx_types is
     type std_logic_vector_array is array (natural range <>, natural range <>) of std_logic;
     type boolean_array is array (natural range <>) of boolean;
end ccsds_rxtx_types;
