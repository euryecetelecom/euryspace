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
---- 2016/10/20: added reverse_std_logic_vector function + rework sim_generate_random_std_logic_vector for > 32 bits vectors
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ccsds_rxtx_functions is
-- synthesable functions
  function reverse_std_logic_vector (input: in std_logic_vector) return std_logic_vector;
-- simulation / testbench only functions
  procedure sim_generate_random_std_logic_vector(vector_size : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector);
end ccsds_rxtx_functions;

package body ccsds_rxtx_functions is

  function reverse_std_logic_vector (input: in std_logic_vector) return std_logic_vector is
  variable result: std_logic_vector(input'RANGE);
  alias output: std_logic_vector(input'REVERSE_RANGE) is input;
  begin
    for i in output'RANGE loop
      result(i) := output(i);
    end loop;
    return result;
  end;
  
  procedure sim_generate_random_std_logic_vector(vector_size : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector) is
    variable rand: real := 0.0;
    variable temp: std_logic_vector(31 downto 0);
  begin
    if (vector_size <= 32) then
      uniform(seed1, seed2, rand);
      rand := rand*(2**(real(vector_size)-1.0));
      result := std_logic_vector(to_unsigned(integer(rand),vector_size));
    else
      uniform(seed1, seed2, rand);
      for i in 0 to vector_size-1 loop
        uniform(seed1, seed2, rand);
        rand := rand*(2**(real(32)-1.0));
        temp := std_logic_vector(to_unsigned(integer(rand),32));
        result(i) := temp(i mod 32);
      end loop;
    end if;
  end sim_generate_random_std_logic_vector;
end ccsds_rxtx_functions;
