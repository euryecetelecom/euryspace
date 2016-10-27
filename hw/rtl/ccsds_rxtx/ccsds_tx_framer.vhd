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
---- 2016/10/24: multiple footers generation to ensure higher speed than input max data rate (CCSDS_TX_FRAMER_DATA_BUS_SIZE*CLK_FREQ bits/sec)
-------------------------------
--HEADER (6 up to 70 bytes) / before data / independent
--TRANSFER FRAME DATA FIELD => Variable
--TRAILER (2 up to 6 bytes) / after data / f(data, header)
--  constant TX_DATALINK_CCSDS_HEADERS_JAM_PAYLOAD: std_logic_vector(10 downto 0) := "11000000011"; 	-- JAM PAYLOAD (SPECIFIC WORD / 11 BITS)

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx framer inputs and outputs
--=============================================================================
entity ccsds_tx_framer is
  generic(
    CCSDS_TX_FRAMER_DATA_BUS_SIZE: integer; -- in bits
    CCSDS_TX_FRAMER_DATA_LENGTH: integer; -- in Bytes
    CCSDS_TX_FRAMER_FOOTER_LENGTH: integer; -- in Bytes
    CCSDS_TX_FRAMER_HEADER_LENGTH: integer -- in Bytes
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
    dat_val_o: out std_logic;
    nxt_dat_o: out std_logic
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
      bus_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_HEADER_LENGTH*8-1 downto 0);
      dat_val_o: out std_logic
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
      bus_o: out std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_FOOTER_DATA_LENGTH*8-1 downto 0);
      dat_o: out std_logic_vector((CCSDS_TX_FOOTER_LENGTH+CCSDS_TX_FOOTER_DATA_LENGTH)*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;

-- internal constants
  constant CCSDS_TX_FRAMER_FOOTER_NUMBER : integer := integer(ceil(real((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+1)*8)/real(CCSDS_TX_FRAMER_DATA_LENGTH*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)));

-- internal variable signals
  type frame_array is array (CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0) of std_logic_vector((CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0);
  type data_header_array is array (CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0) of std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0);

  signal wire_header_data: std_logic_vector(CCSDS_TX_FRAMER_HEADER_LENGTH*8-1 downto 0);
  signal wire_footer_data_i: data_header_array;
  signal wire_footer_data_o: frame_array;
  signal wire_header_data_valid: std_logic;
  signal wire_footer_data_valid: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0);
  signal wire_header_next: std_logic := '0';
  signal wire_header_busy: std_logic;
  signal wire_footer_next: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0) := (others => '0');
  signal wire_footer_busy: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0);

  signal next_processing_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;
  signal next_valid_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;

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
      bus_o => wire_header_busy,
      dat_o => wire_header_data,
      dat_val_o => wire_header_data_valid
    );

  FOOTERGEN:
    for i in 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 generate
      tx_footer_x : ccsds_tx_footer
      generic map(
        CCSDS_TX_FOOTER_DATA_LENGTH => CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH,
        CCSDS_TX_FOOTER_LENGTH => CCSDS_TX_FRAMER_FOOTER_LENGTH
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        nxt_i => wire_footer_next(i),
        bus_o => wire_footer_busy(i),
        dat_i => wire_footer_data_i(i),
        dat_o => wire_footer_data_o(i),
        dat_val_o => wire_footer_data_valid(i)
      );
    end generate FOOTERGEN;

-- presynthesis checks
    CHKFRAMERP0 : if ((CCSDS_TX_FRAMER_DATA_LENGTH*8) mod CCSDS_TX_FRAMER_DATA_BUS_SIZE /= 0) generate
      process
      begin
        report "ERROR: FRAMER DATA LENGTH SHOULD BE A MULTIPLE OF FRAMER DATA BUS SIZE" severity failure;
        wait;
      end process;
    end generate CHKFRAMERP0;
    CHKFRAMERP1 : if ((CCSDS_TX_FRAMER_DATA_LENGTH) = 0) generate
      process
      begin
        report "ERROR: FRAMER DATA LENGTH CANNOT BE 0" severity failure;
        wait;
      end process;
    end generate CHKFRAMERP1;
    
-- internal processing

    --=============================================================================
    -- Begin of framergeneratep
    -- Generate next_frame, copy it to current frame(i), start footer computation and output valid frame
    --=============================================================================
    -- read: dat_val_i, rst_i, wire_data_header, wire_header_data_valid, wire_footer_data, wire_footer_data_valid
    -- write: current_frame, nxt_dat_o, wire_header_next, wire_footer_next, nxt_dat_o
    -- r/w: next_processing_frame_pointer, next_valid_frame_pointer
    FRAMERGENERATEP: process (clk_i)
    variable footer_processing: std_logic := '0';
--    variable next_processing_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;
--    variable next_valid_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;
    variable next_frame: std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0);
    variable next_frame_write_pos: integer range 0 to CCSDS_TX_FRAMER_DATA_LENGTH*8-1 := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          wire_header_next <= '1';
          footer_processing := '0';
          wire_footer_next <= (others => '0');
          next_processing_frame_pointer <= 0;
          next_valid_frame_pointer <= 0;
          next_frame := (others => '0');
          next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
          wire_footer_data_i <= (others => (others => '0'));
          nxt_dat_o <= '1';
        else
          if (dat_val_i = '1') then
            next_frame(next_frame_write_pos downto next_frame_write_pos-CCSDS_TX_FRAMER_DATA_BUS_SIZE+1) := dat_i;
            if (next_frame_write_pos = CCSDS_TX_FRAMER_DATA_BUS_SIZE-1) then
              wire_footer_data_i(next_processing_frame_pointer) <= next_frame;
              footer_processing := '1';
              wire_header_next <= '1';
              wire_footer_next(next_processing_frame_pointer) <= '1';
              next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8-1;
              if (next_processing_frame_pointer < (CCSDS_TX_FRAMER_FOOTER_NUMBER-1)) then
                next_processing_frame_pointer <= (next_processing_frame_pointer + 1);
              else
                next_processing_frame_pointer <= 0;
              end if;
            else
              wire_header_next <= '0';
              next_frame_write_pos := next_frame_write_pos-CCSDS_TX_FRAMER_DATA_BUS_SIZE;
            end if;
          else
          --TODO: FRAME STUFFING HERE
            wire_header_next <= '0';
          end if;
          if(wire_header_data_valid = '1') then
            next_frame((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto CCSDS_TX_FRAMER_DATA_LENGTH*8) := wire_header_data;
          end if;
          if (footer_processing = '1') then
            if (next_processing_frame_pointer > 0) then
              wire_footer_next(next_processing_frame_pointer-1) <= '0';
            else
              wire_footer_next(CCSDS_TX_FRAMER_FOOTER_NUMBER-1) <= '0';
            end if;
            footer_processing := '0';
          end if;
          if (wire_footer_data_valid(next_valid_frame_pointer) = '1') then
            dat_o <= wire_footer_data_o(next_valid_frame_pointer);
            dat_val_o <= '1';
            if (next_valid_frame_pointer < (CCSDS_TX_FRAMER_FOOTER_NUMBER-1)) then
              next_valid_frame_pointer <= (next_valid_frame_pointer + 1);
            else
              next_valid_frame_pointer <= 0;
            end if;
          else
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
