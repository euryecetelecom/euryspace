-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_crc
---- Version: 1.0.0
---- Description:
---- CRC computation core
---- Input: 1 clk / nxt_dat_i <= '1' / dat_i <= "CRCCOMPUTEDDATA" / [pad_dat_val_i <= '1' / pad_dat_i <= "PADDINGDATA"]
---- Timing requirements: (CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8+1 clock cycles for valid output CRC
---- Output: dat_val_o <= "1" / dat_o <= "CRCCOMPUTEDDATA" / crc_o <= "CRCCOMPUTED"
---- Ressources requirements: data computed registers + crc registers + padding data registers + busy state registers + data_valid state registers + crc data pointer registers = (CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH*2)*8 + 2 + |log(CCSDS_RXTX_CRC_DATA_LENGTH-1)/log(2)| + 1 registers
--TODO: ressources with inversions
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/10/18: initial release
---- 2016/10/25: external padding data mode
---- 2016/10/30: ressources usage optimization
-------------------------------
--TODO: Implement DIRECT computation?
--TODO: CRC LENGTH not being multiple of Byte

-- CRC reference and explanations:
-- http://www.ross.net/crc/download/crc_v3.txt

-- Online data converters:
-- http://www.asciitohex.com/

-- Online CRC computers:
-- http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
-- http://www.zorc.breitbandkatze.de/crc.html
-- NB: use nondirect configuration

-- COMMON STANDARDS CONFIGURATIONS:
-- http://reveng.sourceforge.net/crc-catalogue/
-- WARNING: some check values found there are linked to direct computation / cf: http://srecord.sourceforge.net/crc16-ccitt.html
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
-- Check = 0x2189
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
-- CRC-16/X-25
-- Width = 16 bits
-- Truncated polynomial = 0x1021
-- Initial value = 0xffff
-- Input data reflected: true
-- Output CRC reflected: true
-- XOR final = 0xffff
-- Check = 0x2e5d
--------------------
-- CRC-32/ADCCP
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
-- CRC-64/XZ
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
    constant CCSDS_RXTX_CRC_DATA_LENGTH: integer := 2; -- Data length - in Bytes
    constant CCSDS_RXTX_CRC_FINAL_XOR: std_logic_vector := x"0000"; -- Final XOR mask (0x0000 <=> No XOR)
    constant CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED: boolean := false; -- Reflect input byte by byte (used by standards)
    constant CCSDS_RXTX_CRC_INPUT_REFLECTED: boolean := false; -- Reflect input on overall data (not currently used by standards) / WARNING - take over input bytes reflected parameter if activated
    constant CCSDS_RXTX_CRC_LENGTH: integer := 2; -- CRC value depth - in Bytes
    constant CCSDS_RXTX_CRC_OUTPUT_REFLECTED: boolean := false; -- Reflect output
    constant CCSDS_RXTX_CRC_POLYNOMIAL: std_logic_vector	:= x"1021"; -- Truncated polynomial / MSB <=> lower polynome (needs to be '1')
    constant CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED: boolean := false; -- Reflect polynomial
    constant CCSDS_RXTX_CRC_SEED: std_logic_vector := x"FFFF" -- Initial value from register
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    nxt_i: in std_logic;
    pad_dat_i: in std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    pad_dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    bus_o: out std_logic;
    crc_o: out std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0);
    dat_o: out std_logic_vector(CCSDS_RXTX_CRC_DATA_LENGTH*8-1 downto 0);
    dat_val_o: out std_logic
  );
  -- implement input/output registers
  attribute useioff: boolean;
  attribute useioff of dat_i: signal is true;
  attribute useioff of pad_dat_i: signal is true;
  attribute useioff of dat_o: signal is true;
  attribute useioff of crc_o: signal is true;
  attribute syn_useioff: boolean;
  attribute syn_useioff of dat_i: signal is true;
  attribute syn_useioff of pad_dat_i: signal is true;
  attribute syn_useioff of dat_o: signal is true;
  attribute syn_useioff of crc_o: signal is true;
end ccsds_rxtx_crc;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_rxtx_crc is

-- internal variable signals
  signal crc_busy: std_logic := '0';
  signal crc_data: std_logic_vector((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto 0) := (others => '0');
  signal crc_memory: std_logic_vector(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) := CCSDS_RXTX_CRC_SEED;

-- components instanciation and mapping
  begin
     bus_o <= crc_busy;
     crc_o <= crc_memory;
     dat_o <= crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8);
-- presynthesis checks
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
        report "ERROR: CRC POLYNOMIAL LENGTH MUST BE EQUAL TO CRC LENGTH (SHORTENED VERSION / DON'T PUT MANDATORY HIGHER POLYNOME '1')" severity failure;
        wait;
      end process;
    end generate CHKCRCP1;
    CHKCRCP2 : if CCSDS_RXTX_CRC_POLYNOMIAL(CCSDS_RXTX_CRC_LENGTH*8-1) = '0' generate
      process
      begin
        report "ERROR: CRC POLYNOMIAL MSB MUST BE EQUAL TO '1': " & std_logic'image(CCSDS_RXTX_CRC_POLYNOMIAL(CCSDS_RXTX_CRC_LENGTH*8-1)) severity failure;
        wait;
      end process;
    end generate CHKCRCP2;
    CHKCRCP3 : if CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED = true and CCSDS_RXTX_CRC_INPUT_REFLECTED = true generate
      process
      begin
        report "ERROR: CRC INPUT DATA REFLECTION CANNOT BE DONE SIMULTANEOUSLY ON OVERALL DATA AND BYTE BY BYTE" severity failure;
        wait;
      end process;
    end generate CHKCRCP3;
-- internal processing

    --=============================================================================
    -- Begin of crcp
    -- Compute CRC based on input data
    --=============================================================================
    -- read: rst_i, nxt_i, pad_dat_i, pad_dat_val_i
    -- write: dat_val_o, crc_busy, crc_memory
    -- r/w: crc_data
    CRCP: process (clk_i)
    variable crc_data_pointer: integer range -2 to ((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1) := -2;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          crc_busy <= '0';
          dat_val_o <= '0';
--          crc_memory <= CCSDS_RXTX_CRC_SEED;
--          crc_data <= (others => '0');
          crc_data_pointer := -2;
        else
          case crc_data_pointer is
            -- no current crc under computation
            when -2 =>
              dat_val_o <= '0';
              -- CRC computation required and 
              if (nxt_i = '1') then
                crc_busy <= '1';
                crc_memory <= CCSDS_RXTX_CRC_SEED;
                crc_data_pointer := (CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1;
                if (CCSDS_RXTX_CRC_INPUT_REFLECTED) then
                  crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8) <= reverse_std_logic_vector(dat_i);
                elsif (CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED) then
                  for data_pointer in CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH-1 downto CCSDS_RXTX_CRC_LENGTH loop
                    crc_data((data_pointer+1)*8-1 downto data_pointer*8) <= reverse_std_logic_vector(dat_i(((data_pointer+1-CCSDS_RXTX_CRC_LENGTH)*8-1) downto (data_pointer-CCSDS_RXTX_CRC_LENGTH)*8));
                  end loop;
                else
                    crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8) <= dat_i;
                end if;
                if (pad_dat_val_i = '1') then
                  if (CCSDS_RXTX_CRC_OUTPUT_REFLECTED) then
                    crc_data(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) <= reverse_std_logic_vector(pad_dat_i);
                  else
                    crc_data(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) <= pad_dat_i;
                  end if;
                else
                  crc_data(CCSDS_RXTX_CRC_LENGTH*8-1 downto 0) <= (others => '0');
                end if;
              else
                -- nothing to be done
                crc_busy <= '0';
              end if;
            -- CRC is computed
            when -1 =>
              crc_busy <= '0';
              dat_val_o <= '1';
              crc_data_pointer := -2;
              if (CCSDS_RXTX_CRC_OUTPUT_REFLECTED) then
                crc_memory <= reverse_std_logic_vector(crc_memory xor CCSDS_RXTX_CRC_FINAL_XOR);
              else
                crc_memory <= (crc_memory xor CCSDS_RXTX_CRC_FINAL_XOR);
              end if;
              if (CCSDS_RXTX_CRC_INPUT_REFLECTED) then
                crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8) <= reverse_std_logic_vector(crc_data((CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH)*8-1 downto CCSDS_RXTX_CRC_LENGTH*8));
              elsif (CCSDS_RXTX_CRC_INPUT_BYTES_REFLECTED) then
                for data_pointer in CCSDS_RXTX_CRC_DATA_LENGTH+CCSDS_RXTX_CRC_LENGTH-1 downto CCSDS_RXTX_CRC_LENGTH loop
                  crc_data(((data_pointer+1)*8-1) downto data_pointer*8) <= reverse_std_logic_vector(crc_data(((data_pointer+1)*8-1) downto data_pointer*8));
                end loop;
              end if;
            -- Computing CRC
            when others => 
              crc_busy <= '1';
              dat_val_o <= '0';
              -- MSB = 1 / register shifted output bit will be '1'
              if (crc_memory(CCSDS_RXTX_CRC_LENGTH*8-1) = '1') then
                if (CCSDS_RXTX_CRC_POLYNOMIAL_REFLECTED) then
                  crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer)) xor reverse_std_logic_vector(CCSDS_RXTX_CRC_POLYNOMIAL);
                else
                  crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer)) xor CCSDS_RXTX_CRC_POLYNOMIAL;
                end if;
              else
                crc_memory <= (std_logic_vector(resize(unsigned(crc_memory),CCSDS_RXTX_CRC_LENGTH*8-1)) & crc_data(crc_data_pointer));
              end if;
              crc_data_pointer := crc_data_pointer - 1;
          end case;
        end if;
      end if;
    end process;
end rtl;
