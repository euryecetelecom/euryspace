-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_buffer
---- Version: 1.0.0
---- Description:
---- FIFO circular buffer
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/02/27: initial release
---- 2016/10/20: major corrections and optimizations
-------------------------------
--FIXME: 1 WORD not used for storage

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary rxtx buffer inputs and outputs
--=============================================================================
entity ccsds_rxtx_buffer is
  generic(
    CCSDS_RXTX_BUFFER_DATA_BUS_SIZE : integer;
    CCSDS_RXTX_BUFFER_SIZE : integer
  );
  port(
    clk_i: in std_logic;
    rst_i: in std_logic;
    buffer_empty_o: out std_logic;
    buffer_full_o: out std_logic;
    next_data_i: in std_logic;
    data_i: in std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    data_valid_i: in std_logic;
    data_o: out std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_rxtx_buffer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_rxtx_buffer is

-- interconnection signals
  signal buffer_read_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := 0;
  signal buffer_write_pos: integer range 0 to CCSDS_RXTX_BUFFER_SIZE-1 := 0;
  type buffer_array is array (CCSDS_RXTX_BUFFER_SIZE-1 downto 0) of std_logic_vector(CCSDS_RXTX_BUFFER_DATA_BUS_SIZE-1 downto 0);
  signal buffer_data: buffer_array := (others => (others => '0'));
  
-- components instanciation and mapping
  begin

-- internal processing

    --=============================================================================
    -- Begin of bufferpushp
    -- Store valid input data in buffer
    --=============================================================================
    -- read: data_valid_i, rst_i
    -- write: buffer_write_pos, buffer_data, wire_buffer_full
    -- r/w: 
    BUFFERPUSH : process (clk_i)
    begin
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          buffer_write_pos <= 0;
          buffer_full_o <= '0';
        else
          -- check if buffer is full
          if ((buffer_write_pos+1) mod CCSDS_RXTX_BUFFER_SIZE = buffer_read_pos) then
            buffer_full_o <= '1';
          else
            buffer_full_o <= '0';
            if (data_valid_i = '1') then
              -- copy data to buffer mem
              buffer_data(buffer_write_pos) <= data_i;
              buffer_write_pos <= (buffer_write_pos + 1) mod CCSDS_RXTX_BUFFER_SIZE;
            end if;
          end if;
        end if;
      end if;
    end process;
    
    --=============================================================================
    -- Begin of bufferpullp
    -- Read data from buffer
    --=============================================================================
    -- read: wire_buffer_empty, next_data_i, rst_i
    -- write: data_o, buffer_read_pos, data_valid_o, wire_buffer_empty
    -- r/w: 
    BUFFERPULLP : process (clk_i)
    begin
      if rising_edge(clk_i) then
        if (rst_i = '1') then
          buffer_read_pos <= 0;
          data_valid_o <= '0';
          data_o <= (others => '0');
          buffer_empty_o <= '1';
        else
          -- check if buffer is empty
          if (buffer_read_pos = buffer_write_pos) then
            buffer_empty_o <= '1';
            data_valid_o <= '0';
          else
            buffer_empty_o <= '0';
            if (next_data_i = '1') then
              data_valid_o <= '1';
              data_o <= buffer_data(buffer_read_pos);
              buffer_read_pos <= (buffer_read_pos + 1) mod CCSDS_RXTX_BUFFER_SIZE;
            else
              data_valid_o <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;
end rtl;
