-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_framer
---- Version: 1.0.0
---- Description:
---- TBD
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/02/27: initial release
---- 2016/10/20: rework
-------------------------------
--HEADER (6 up to 70 bytes) / before data / independant
--TRANSFER FRAME DATA FIELD => Variable
--TRAILER (2 up to 6 bytes) / after data / f(data, header)

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx framer inputs and outputs
--=============================================================================
entity ccsds_tx_framer is
  generic(
    CCSDS_TX_FRAMER_HEADER_LENGTH: integer; -- in Bytes
    CCSDS_TX_FRAMER_DATA_LENGTH: integer; -- in Bytes
    CCSDS_TX_FRAMER_FOOTER_LENGTH: integer; -- in Bytes
    CCSDS_TX_FRAMER_DATA_BUS_SIZE: integer -- in bits
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    next_data_o: out std_logic;
    data_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
    data_valid_i: in std_logic;
    data_o: out std_logic_vector((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_tx_framer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_framer is
  component ccsds_tx_header is
    generic(
      CCSDS_TX_HEADER_LENGTH: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      nxt_i: in std_logic;
      busy_o: out std_logic;
      data_o: out std_logic_vector(CCSDS_TX_HEADER_LENGTH*8-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;
  component ccsds_tx_footer is
    generic(
      CCSDS_TX_FOOTER_DATA_LENGTH : integer;
      CCSDS_TX_FOOTER_LENGTH: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      nxt_i: in std_logic;
      busy_o: out std_logic;
      data_i: in std_logic_vector(CCSDS_TX_FOOTER_DATA_LENGTH*8-1 downto 0);
      data_o: out std_logic_vector(CCSDS_TX_FOOTER_LENGTH*8-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

-- internal variable signals
  signal wire_header_data: std_logic_vector(CCSDS_TX_FRAMER_HEADER_LENGTH*8-1 downto 0);
  signal wire_footer_data: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_LENGTH*8-1 downto 0);
  signal wire_header_data_valid: std_logic;
  signal wire_footer_data_valid: std_logic;
  signal wire_header_next: std_logic := '1';
  signal wire_header_busy: std_logic;
  signal wire_footer_next: std_logic := '0';
  signal wire_footer_busy: std_logic;
  signal wire_frame_done: std_logic := '1';
  signal wire_header_done: std_logic := '0';
  signal current_header: std_logic_vector(CCSDS_TX_FRAMER_HEADER_LENGTH*8-1 downto 0);
  signal current_frame: std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0) := (others => '0');
  signal current_frame_ready: std_logic := '0';

-- components instanciation and mapping
  begin
  tx_header_0: ccsds_tx_header
    generic map(
      CCSDS_TX_HEADER_LENGTH => CCSDS_TX_FRAMER_HEADER_LENGTH
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      nxt_i => wire_header_next,
      busy_o => wire_header_busy,
      data_o => wire_header_data,
      data_valid_o => wire_header_data_valid
    );

  tx_footer_0: ccsds_tx_footer
    generic map(
      CCSDS_TX_FOOTER_DATA_LENGTH => CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH,
      CCSDS_TX_FOOTER_LENGTH => CCSDS_TX_FRAMER_FOOTER_LENGTH
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      nxt_i => wire_footer_next,
      busy_o => wire_footer_busy,
      data_i => current_frame,
      data_o => wire_footer_data,
      data_valid_o => wire_footer_data_valid
    );

    clk_o <= clk_i;

-- presynthesis checks
    CHKFRAMERP0 : if CCSDS_TX_FRAMER_DATA_LENGTH*8 mod CCSDS_TX_FRAMER_DATA_BUS_SIZE /= 0 generate
      process
      begin
        report "ERROR: FRAMER DATA SIZE SHOULD BE A MULTIPLE OF FRAMER DATA BUS SIZE" severity failure;
	wait;
      end process;
    end generate CHKFRAMERP0;
    
-- internal processing

    --=============================================================================
    -- Begin of framergenp
    -- Generate valid frames with headers and footers
    --=============================================================================
    -- read: current_frame_ready, rst_in wire_footer_data_valid, wire_header_data_valid, wire_header_data, wire_footer_data, wire_footer_busy
    -- write: wire_header_next, wire_footer_next, wire_frame_done, data_valid_o, data_o
    -- r/w: wire_header_done
    FRAMERGENP: process (clk_i)
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          wire_header_next <= '1';
          wire_footer_next <= '0';
          wire_frame_done <= '1';
          wire_header_done <= '0';
          data_valid_o <= '0';
          data_o <= (others => '0');
          current_header <= (others => '0');
        else
          if (wire_header_done = '1') then
            if (wire_footer_data_valid = '1') then
              data_o((CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto CCSDS_TX_FRAMER_FOOTER_LENGTH*8) <= current_frame;
              data_o(CCSDS_TX_FRAMER_FOOTER_LENGTH*8-1 downto 0) <= wire_footer_data;
              data_valid_o <= '1';
              wire_frame_done <= '1';
              wire_header_done <= '0';
              wire_header_next <= '1';
            else
              data_valid_o <= '0';
              if (current_frame_ready = '1') then
                if (wire_footer_busy = '0') then
                  wire_footer_next <= '1';
                  wire_frame_done <= '0';
                else
                  wire_footer_next <= '0';
                end if;
              else
                wire_footer_next <= '0';
              end if;
            end if;
          else
            data_valid_o <= '0';
            wire_header_next <= '0';
            if (wire_header_data_valid = '1') then
              wire_header_done <= '1';
              current_header <= wire_header_data;
            end if;
          end if;
        end if;
      end if;
    end process;

    --=============================================================================
    -- Begin of framecopyp
    -- Generate next_frame and copy it to current frame when current frame has been done
    --=============================================================================
    -- read: wire_header_done, wire_frame_done, data_valid_i, rst_i, wire_data_header
    -- write: current_frame, current_frame_ready, next_data_o
    -- r/w: 
    FRAMECOPYP: process (clk_i)
    variable next_frame: std_logic_vector(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0);
    variable next_frame_ready: std_logic := '0';
    variable next_frame_write_pos: integer range 0 to CCSDS_TX_FRAMER_DATA_LENGTH*8-1 := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
  --Generate next frame, wait for current frame transmitted frame and copy to current
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          next_frame_ready := '0';
          next_frame := (others => '0');
          next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
          current_frame <= (others => '0');
          current_frame_ready <= '0';
          next_data_o <= '0';
        else
          if (next_frame_ready = '1') then
            if (wire_frame_done = '1') and (wire_header_done = '1') then
              current_frame((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto CCSDS_TX_FRAMER_DATA_LENGTH*8) <= current_header;
              current_frame(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0) <= next_frame;
              next_frame_ready := '0';
              current_frame_ready <= '1';
              next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
            else
              current_frame_ready <= '0';
            end if;
          else
            current_frame_ready <= '0';
            if (data_valid_i = '1') then
              next_frame(next_frame_write_pos downto next_frame_write_pos-CCSDS_TX_FRAMER_DATA_BUS_SIZE+1) := data_i;
              if (next_frame_write_pos = CCSDS_TX_FRAMER_DATA_BUS_SIZE-1) then
                next_frame_ready := '1';
                next_data_o <= '0';
                next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
              else
                next_frame_write_pos := next_frame_write_pos-CCSDS_TX_FRAMER_DATA_BUS_SIZE;
                next_data_o <= '1';
              end if;
            else 
              next_data_o <= '1';
            end if;
          end if;
        end if;
      end if;
    end process;
end structure;
