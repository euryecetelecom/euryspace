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

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ccsds_rxtx_types.all;

package ccsds_rxtx_functions is
-- synthetizable functions
  function convert_boolean_to_std_logic(input: in boolean) return std_logic;
  function convert_std_logic_vector_array_to_std_logic_vector(std_logic_vector_array_in: in std_logic_vector_array; current_row: in integer) return std_logic_vector;
  function reverse_std_logic_vector (input: in std_logic_vector) return std_logic_vector;
-- simulation / testbench only functions
  function convert_std_logic_vector_to_hexa_ascii(input: in std_logic_vector) return string;
  procedure sim_generate_random_std_logic_vector(vector_size : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector);
end ccsds_rxtx_functions;

package body ccsds_rxtx_functions is

  function convert_boolean_to_std_logic(input: in boolean) return std_logic is
  begin
    if (input = true) then
      return '1';
    else
      return '0';
    end if;
  end convert_boolean_to_std_logic;

  function convert_std_logic_vector_array_to_std_logic_vector(std_logic_vector_array_in: in std_logic_vector_array; current_row: in integer) return std_logic_vector is
  variable result: std_logic_vector(std_logic_vector_array_in'range(2));
  begin
    for i in std_logic_vector_array_in'range(2) loop
      result(i) := std_logic_vector_array_in(current_row, i);
--      report "Read: " & std_logic'image(std_logic_vector_array_in(current_row, i)) severity note;
    end loop;
    return result;
  end;
  
  function reverse_std_logic_vector (input: in std_logic_vector) return std_logic_vector is
  variable result: std_logic_vector(input'range);
  alias output: std_logic_vector(input'REVERSE_RANGE) is input;
  begin
    for vector_pointer in output'range loop
      result(vector_pointer) := output(vector_pointer);
    end loop;
    return result;
  end;

  function convert_std_logic_vector_to_hexa_ascii(input: in std_logic_vector) return string is
  constant words_number: integer := input'length/4;
  variable result: string(words_number-1 downto 0);
  variable word: std_logic_vector(3 downto 0);
  begin
    for vector_word_pointer in words_number-1 downto 0 loop
      word := input((vector_word_pointer+1)*4-1 downto vector_word_pointer*4);
      case word is
        when "0000" =>
          result(vector_word_pointer) := '0';
        when "0001" =>
          result(vector_word_pointer) := '1';
        when "0010" =>
          result(vector_word_pointer) := '2';
        when "0011" =>
          result(vector_word_pointer) := '3';
        when "0100" =>
          result(vector_word_pointer) := '4';
        when "0101" =>
          result(vector_word_pointer) := '5';
        when "0110" =>
          result(vector_word_pointer) := '6';
        when "0111" =>
          result(vector_word_pointer) := '7';
        when "1000" =>
          result(vector_word_pointer) := '8';
        when "1001" =>
          result(vector_word_pointer) := '9';
        when "1010" =>
          result(vector_word_pointer) := 'a';
        when "1011" =>
          result(vector_word_pointer) := 'b';
        when "1100" =>
          result(vector_word_pointer) := 'c';
        when "1101" =>
          result(vector_word_pointer) := 'd';
        when "1110" =>
          result(vector_word_pointer) := 'e';
        when "1111" =>
          result(vector_word_pointer) := 'f';
        when others =>
          result(vector_word_pointer) := '?';
      end case;
--    report "Converted " & integer'image(to_integer(resize(unsigned(word),16))) & " to " & result(vector_word_pointer) severity note;
    end loop;
    return result;
  end;

  procedure sim_generate_random_std_logic_vector(vector_size : in integer; seed1 : inout positive; seed2 : inout positive; result : out std_logic_vector) is
    variable rand: real := 0.0;
    variable temp: std_logic_vector(31 downto 0);
  begin
    if (vector_size < 32) then
      uniform(seed1, seed2, rand);
      rand := rand*(2**(real(vector_size))-1.0);
      result := std_logic_vector(to_unsigned(integer(rand),vector_size));
    else
      uniform(seed1, seed2, rand);
      for vector_pointer in 0 to vector_size-1 loop
        uniform(seed1, seed2, rand);
        rand := rand*(2**(real(31))-1.0);
        temp := std_logic_vector(to_unsigned(integer(rand),32));
        result(vector_pointer) := temp(0);
      end loop;
    end if;
  end sim_generate_random_std_logic_vector;
end ccsds_rxtx_functions;
