-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_crc
---- Version: 1.0.0
---- Description:
---- TBD / Nb clock cycles required / ...
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/10/18: initial release
-------------------------------
--TODO: DIRECT VS NON-DIRECT
--TODO: CRC LENGTH not multiple of Byte
--FIXME: REVERSE DATA BYTES not working

-- Online data converters:
-- http://www.asciitohex.com/

-- Online CRC computers: 
-- http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
-- http://www.zorc.breitbandkatze.de/crc.html
-- NB: use nondirect configuration

-- COMMON STANDARDS CONFIGURATIONS:
-- http://reveng.sourceforge.net/crc-catalogue/
-- WARNING: some check values found there are linked to direct and non direct computation / cf: http://srecord.sourceforge.net/crc16-ccitt.html
--------------------
-- Check value: x"313233343536373839" <=> 123456789/ASCII
--------------------
-- CRC-8/DVB-S2
-- Width = 8 bits
-- Truncated polynomial = 0xd5
-- Initial value = 0x00
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x00
-- Check = 0xbc
--------------------
-- CRC-8/ITU/ATM
-- Width = 8 bits
-- Truncated polynomial = 0x07
-- Initial value = 0x00
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x55
-- Check = 0xa1
--------------------
-- CRC-8/LTE
-- Width = 8 bits
-- Truncated polynomial = 0x9b
-- Initial value = 0x00
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x00
-- Check = 0xea
--------------------
-- CRC-16/CCSDS/CCITT-FALSE
-- Width = 16 bits
-- Truncated polynomial = 0x1021
-- Initial value = 0xffff
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x0000
-- Check = 0xe5cc
--------------------
-- CRC-16/LTE
-- Width = 16 bits
-- Truncated polynomial = 0x1021
-- Initial value = 0x0000
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x0000
-- Check = 0x31c3
--------------------
-- CRC-16/CCITT-TRUE/KERMIT
-- Width = 16 bits
-- Truncated polynomial = 0x1021
-- Initial value = 0x0000
-- Input data reflected: true
-- Output CRC reflected: true
-- XOR final = 0x0000
-- Check = 0xd1a2
--------------------
-- CRC-16/UMTS
-- Width = 16 bits
-- Truncated polynomial = 0x8005
-- Initial value = 0x0000
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x0000
-- Check = 0xfee8
--------------------
-- CRC-16/X-25 // KO - TO BE TESTED
-- Width = 16 bits
-- Truncated polynomial = 0x1021
-- Initial value = 0xffff
-- Input data reflected: true
-- Output CRC reflected: true
-- XOR final = 0xffff
-- Check = 0x2e5d
--------------------
-- CRC-32/ADCCP // KO - input inverter to be tested / debugged
-- Width = 32 bits
-- Truncated polynomial = 0x04c11db7
-- Initial value = 0xffffffff
-- Input data reflected: true
-- Output CRC reflected: true
-- XOR final = 0xffffffff
-- Check = 0x22896b0a
----------------
-- CRC-32/BZIP2
-- Width = 32 bits
-- Truncated polynomial = 0x04c11db7
-- Initial value = 0xffffffff
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0xffffffff
-- Check = 0xfc891918
----------------
-- CRC-32/MPEG-2
-- Width = 32 bits
-- Truncated polynomial = 0x04c11db7
-- Initial value = 0xffffffff
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0x00000000
-- Check = 0x373C5870
----------------
-- CRC-32/POSIX
-- Width = 32 bits
-- Truncated polynomial = 0x04c11db7
-- Initial value = 0x00000000
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0xffffffff
-- Check = 0x765e7680
----------------
-- CRC-64/WE
-- Width = 64 bits
-- Truncated polynomial = 0x42f0e1eba9ea3693
-- Initial value = 0xffffffffffffffff
-- Input data reflected: false
-- Output CRC reflected: false
-- XOR final = 0xffffffffffffffff
-- Check = 0xd2c7a4d6f38185a4
----------------
-- CRC-64/XZ // KO - to be tested when reflection OK
-- Width = 64 bits
-- Truncated polynomial = 0x42f0e1eba9ea3693
-- Initial value = 0xffffffffffffffff
-- Input data reflected: true
-- Output CRC reflected: true
-- XOR final = 0xffffffffffffffff
-- Check = 0xecf36dfb73a6edf7
----------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.ccsds_rxtx_functions.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary rxtx crc inputs and outputs
--=============================================================================
entity ccsds_rxtx_crc is
  generic(
    CCSDS_RXTX_CRC_LENGTH: integer := 2; -- in Bytes
    CCSDS_RXTX_CRC_DATA_LENGTH: integer := 2; -- in Bytes
    CCSDS_RXTX_CRC_POLYNOMIAL: std_logic_vector	:= x"1021";
    CCSDS_RXTX_CRC_SEED: std_logic_vector := x"FFFF";
    CCSDS_RXTX_CRC_FINAL_XOR: std_logic_vector := x"0000";
    CCSDS_RXTX_CRC_INPUT_REFLECTED: std_logic := '0';
    CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED: std_logic := '0';
    CCSDS_RXTX_CRC_OUTPUT_REFLECTED: std_logic := '0';
    CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED: std_logic := '0'
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;
    nxt_i: in std_logic;
    busy_o: out std_logic;
    data_i: in std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    data_o: out std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_rxtx_crc;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_rxtx_crc is

-- internal variable signals
    signal crc_memory: std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) := CCSDS_RXTX_CRC_SEED;
    signal crc_data: std_logic_vector((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto 0) := (others => '0');
    signal crc_data_pointer: integer range -2 to ((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1) := -2;
    signal crc_busy: std_logic := '0';

-- components instanciation and mapping
  begin
     busy_o <= crc_busy;
-- presynthesis checks
--TBD/LSB OF POLYNOMIAL CHECK / HAS TO BE '1'
     CHKCRCP0 : if CCSDS_RXTX_CRC_SEED'length /= CCSDS_RXTX_CRC_LENGTH*8 generate
      process
      begin
        report "ERROR: CRC SEED VALUE LENGTH MUST BE EQUAL TO CRC LENGTH" severity failure;
	wait;
      end process;
    end generate CHKCRCP0;
    CHKCRCP1 : if CCSDS_RXTX_CRC_POLYNOMIAL'length /= CCSDS_RXTX_CRC_LENGTH*8 generate
      process
      begin
        report "ERROR: CRC POLYNOMIAL LENGTH MUST BE EQUAL TO CRC LENGTH (SHORTENED VERSION / DON'T PUT MANDATORY MSB '1')" severity failure;
        wait;
      end process;
    end generate CHKCRCP1;
-- internal processing

    --=============================================================================
    -- Begin of crcp
    -- Compute CRC based on input data
    --=============================================================================
    -- read: rst_i, nxt_i
    -- write: data_valid_o, data_o
    -- r/w: 
    CRCP: process (clk_i)
--    variable crc_memory: std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) := CCSDS_RXTX_CRC_SEED;
--    variable crc_data: std_logic_vector((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto 0) := (others => '0');
--    variable crc_data_pointer: integer range -2 to ((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8) := -2;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          crc_busy <= '0';
          data_o <= (others => '0');
          data_valid_o <= '0';
          crc_memory <= CCSDS_RXTX_CRC_SEED;
          crc_data <= (others => '0');
          crc_data_pointer <= -2;
        else
          if (nxt_i = '1') and (crc_data_pointer = -2) then
            data_valid_o <= '0';
            crc_busy <= '1';
            crc_memory <= CCSDS_RXTX_CRC_SEED;
            crc_data_pointer <= (CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1;
            if (CCSDS_RXTX_CRC_INPUT_REFLECTED = '0') then
              if (CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED = '0') then
                crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8) <= data_i;
              else
                for i in CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH-1 downto CCSDS_RXTX_CRC_LENGTH loop
                  crc_data((i+1)*8-1 downto i*8) <= reverse_std_logic_vector(data_i(((i+1-CCSDS_RXTX_CRC_LENGTH)*8-1) downto (i-CCSDS_RXTX_CRC_LENGTH)*8));
                end loop;              
              end if;
            else
              crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8) <= reverse_std_logic_vector(data_i);
            end if;
            crc_data(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) <= (others => '0');
          else
            --nothing to be done
            if (crc_data_pointer = -2) then
              data_valid_o <= '0';
              crc_busy <= '0';
            else
              -- CRC is computed
              if (crc_data_pointer = -1) then
                crc_busy <= '0';
                data_valid_o <= '1';
                crc_data_pointer <= crc_data_pointer - 1;
                if (CCSDS_RXTX_CRC_OUTPUT_REFLECTED = '0') then
                  data_o <= (crc_memory xor CCSDS_RXTX_CRC_FINAL_XOR);
                else
                  data_o <= reverse_std_logic_vector(crc_memory xor CCSDS_RXTX_CRC_FINAL_XOR);
                end if;
              else
                -- Computing CRC
                crc_busy <= '1';
                data_valid_o <= '0';
                crc_data_pointer <= crc_data_pointer - 1;
                -- MSB = 1 / register shifted output bit will be '1'
                if (crc_memory(CCSDS_RXTX_CRC_LENGTH*8-1) = '1') then
                  if (CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED = '0') then
                    crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer)) xor CCSDS_RXTX_CRC_POLYNOMIAL;
                  else
                    crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer)) xor reverse_std_logic_vector(CCSDS_RXTX_CRC_POLYNOMIAL);
                  end if;
                else
                  crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer));
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end process;
end rtl;
