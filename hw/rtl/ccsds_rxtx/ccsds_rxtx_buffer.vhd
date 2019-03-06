-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_buffer
---- Version: 1.0.0
---- Description:
---- FIFO circular buffer
---- Input: 1 clk / [STORE: dat_val_i <= '1' / dat_i <= "STOREDDATA" ] / [READ: nxt_i <= '1']
---- Timing requirements: 1 clock cycle
---- Output: [READ: dat_val_o <= "1" / dat_o <= "STOREDDATA"]
---- Ressources requirements: CCSDS_RXTX_BUFFER_DATA_BUS_SIZE*(CCSDS_RXTX_BUFFER_SIZE+1) + 2*|log(CCSDS_RXTX_BUFFER_SIZE-1)/log(2)| + 2 + 3 + CCSDS_RXTX_BUFFER_DATA_BUS_SIZE registers
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary rxtx buffer inputs and outputs
--=============================================================================
entity ccsds_rxtx_buffer is
  generic(
    constant CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer; -- in bits
    constant CCSDS_RXTX_BUFFER_SIZE : integer
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    dat_nxt_i: in std_logic;
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    buf_emp_o: out std_logic;
    buf_ful_o: out std_logic;
    dat_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_rxtx_buffer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_rxtx_buffer is

-- interconnection signals
  type buffer_array is array (CCSDS_RXTX_BUFFER_SIZE downto 0) of std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
  signal buffer_data: buffer_array := (others => (others => '0'));
  signal buffer_read_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE := 0;
  signal buffer_write_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE := 0;
  
-- components instanciation and mapping
  begin

-- internal processing

    --=============================================================================
    -- Begin of bufferpullp
    -- Read data from buffer
    --=============================================================================
    -- read: nxt_dat_i, rst_i, buffer_write_pos, buffer_data
    -- write: dat_o, dat_val_o, buf_emp_o
    -- r/w: buffer_read_pos
    BUFFERPULLP : process (clk_i)
    begin
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          buf_emp_o <= '1';
          buffer_read_pos <= 0;
          dat_o <= (others => '0');
          dat_val_o <= '0';
        else
          if (buffer_read_pos = buffer_write_pos) then
            buf_emp_o <= '1';
            dat_val_o <= '0';
          else
            buf_emp_o <= '0';
            if (dat_nxt_i = '1') then
              dat_val_o <= '1';
              dat_o <= buffer_data(buffer_read_pos);
              if (buffer_read_pos < CCSDS_RXTX_BUFFER_SIZE) then
                buffer_read_pos <= (buffer_read_pos + 1);
              else
                buffer_read_pos <= 0;
              end if;
            else
              dat_val_o <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;
    --=============================================================================
    -- Begin of bufferpushp
    -- Store valid input data in buffer
    --=============================================================================
    -- read: dat_i, dat_val_i, buffer_read_pos, rst_i
    -- write:  buffer_data, buf_ful_o
    -- r/w: buffer_write_pos
    BUFFERPUSH : process (clk_i)
    begin
      if rising_edge(clk_i) then
        if (rst_i = '1') then
--          buffer_data <= (others => (others => '0'));
          buf_ful_o <= '0';
          buffer_write_pos <= 0;
        else
          if (buffer_write_pos < CCSDS_RXTX_BUFFER_SIZE) then
            if (buffer_read_pos = (buffer_write_pos+1)) then
              buf_ful_o <= '1';
            else
              buf_ful_o <= '0';
              if (dat_val_i = '1') then
                buffer_data(buffer_write_pos) <= dat_i;
                buffer_write_pos <= (buffer_write_pos + 1);
              end if;
            end if;
          else
            if (buffer_read_pos = 0) then
              buf_ful_o <= '1';
            else
              buf_ful_o <= '0';
              if (dat_val_i = '1') then
                buffer_data(buffer_write_pos) <= dat_i;
                buffer_write_pos <= 0;
              end if;
            end if;
          end if;
        end if;
      end if;
    end process;
end rtl;
