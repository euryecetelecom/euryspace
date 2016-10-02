-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_buffer
---- Version: 1.0.0
---- Description:
---- Simple FIFO circular buffer
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/02/27: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

-- unitary rxtx buffer
entity ccsds_rxtx_buffer is
  generic(
    CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer := 32;
    CCSDS_RXTX_BUFFER_SIZE : integer range 2 to 100000 := 256
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    buf_empty_o: out std_logic;
    buf_full_o: out std_logic;
    next_data_i: in std_logic;
    data_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    data_valid_i: in std_logic;
    data_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_rxtx_buffer;

architecture rtl of ccsds_rxtx_buffer is
  signal buffer_read_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := CCSDS_RXTX_BUFFER_SIZE-1;
  signal buffer_write_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := 0;
  signal buffer_full: std_logic := '0';
  signal buffer_empty: std_logic := '1';
  type buffer_array is array (CCSDS_RXTX_BUFFER_SIZE-1 downto 0) of std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
  signal buffer_data: buffer_array;

begin

  BUFFERSTATEP : process (clk_i)
--  variable previous_write_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := 0;
  --variable previous_read_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := 0;
  begin
    -- on each clock rising edge
    if rising_edge(clk_i) then
      if (rst_i = '0') then
        buffer_full <= '0';
        buffer_empty <= '1';
      else
        if (buffer_write_pos = buffer_read_pos) then
          buffer_full <= '1';
          buffer_empty <= '0';
        else
          buffer_full <= '0';
        end if;
        if (buffer_full = '0') then
          if (buffer_read_pos+1 = CCSDS_RXTX_BUFFER_SIZE) then
            if (buffer_write_pos = 0) then
              buffer_empty <= '1';
            else
              buffer_empty <= '0';
            end if;
          else
            if (buffer_read_pos+1 = buffer_write_pos) then
              buffer_empty <= '1';
            else
              buffer_empty <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- PUSH - WRITE OPERATIONS
  BUFFERPUSH : process (clk_i)
  variable push_state: std_logic := '0';
  begin
    if rising_edge(clk_i) then
      if (rst_i = '0') then
        push_state := '0';
        buffer_write_pos <= 0;
      else
        -- check if buffer is full
        if (buffer_full = '0') and (data_valid_i = '1') and (push_state = '0') then
          -- copy data to buffer mem
          buffer_data(buffer_write_pos) <= data_i;
          push_state := '1';
          --end of circular buffer is reached
          if (buffer_write_pos+1 = CCSDS_RXTX_BUFFER_SIZE) then
            buffer_write_pos <= 0;
          else
            buffer_write_pos <= buffer_write_pos + 1;
          end if;
        else
          push_state := '0';
        end if;
      end if;
    end if;
  end process;
  
  -- PULL - READ OPERATIONS
  BUFFERPULLP : process (clk_i)
  variable pull_state: std_logic := '0';
  begin
    if rising_edge(clk_i) then
      if (rst_i = '0') then
        pull_state := '0';
        buffer_read_pos <= CCSDS_RXTX_BUFFER_SIZE-1;
      else
        -- check if buffer is empty
        if (buffer_empty = '0') and (next_data_i = '1') and (pull_state = '0') then
          data_valid_o <= '1';
          pull_state := '1';
          if ((buffer_read_pos + 1) = CCSDS_RXTX_BUFFER_SIZE) then
            buffer_read_pos <= 0;
          else
            buffer_read_pos <= buffer_read_pos + 1;
          end if;
        else
          pull_state := '0';
          data_valid_o <= '0';
        end if;
      end if;
    end if;
  end process;
  
  buf_empty_o <= buffer_empty;
  buf_full_o <= buffer_full;
  data_o <= buffer_data(buffer_read_pos);
  clk_o <= clk_i;
  
end rtl;
