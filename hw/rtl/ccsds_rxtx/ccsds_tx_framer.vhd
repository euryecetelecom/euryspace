-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_framer
---- Version: 1.0.0
---- Description:
---- Implementation of standard CCSDS 132.0-B-2
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
---- 2016/10/31: ressources optimization
---- 2016/11/03: add only idle data insertion
-------------------------------
--TODO: trailer as option
--HEADER (6 up to 70 bytes) / before data / f(idle)
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
    constant CCSDS_TX_FRAMER_DATA_BUS_SIZE: integer; -- in bits
    constant CCSDS_TX_FRAMER_DATA_LENGTH: integer; -- in Bytes
    constant CCSDS_TX_FRAMER_FOOTER_LENGTH: integer; -- in Bytes
    constant CCSDS_TX_FRAMER_HEADER_LENGTH: integer; -- in Bytes
    constant CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO: integer := 8 -- activated max framer parallelism speed ratio / 1 = full speed / 2 = wishbone bus max speed / ... / 32 = external serial data
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_framer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_framer is
  component ccsds_tx_header is
    generic(
      constant CCSDS_TX_HEADER_LENGTH: integer
    );
    port(
      clk_i: in std_logic;
      idl_i: in std_logic;
      nxt_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_HEADER_LENGTH*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_footer is
    generic(
      constant CCSDS_TX_FOOTER_DATA_LENGTH : integer;
      constant CCSDS_TX_FOOTER_LENGTH: integer
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
  constant CCSDS_TX_FRAMER_FOOTER_NUMBER : integer := CCSDS_TX_FRAMER_DATA_BUS_SIZE*((CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH)*8+1)/(CCSDS_TX_FRAMER_DATA_LENGTH*8*CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO)+1; -- 8*(HEAD+DATA+FOOT+1) clks / crc ; BUS bits / parallelism * clk ; DATA*8 bits / footer
  constant CCSDS_TX_FRAMER_OID_PATTERN: std_logic_vector(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0) := (others => '1'); -- Only Idle Data Pattern transmitted (jam payload for frame stuffing)

-- internal variable signals 
  type frame_array is array (CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0) of std_logic_vector((CCSDS_TX_FRAMER_FOOTER_LENGTH+CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0);
  signal wire_header_data: std_logic_vector(CCSDS_TX_FRAMER_HEADER_LENGTH*8-1 downto 0);
  signal wire_footer_data_o: frame_array;
  signal wire_header_data_valid: std_logic;
  signal wire_footer_data_valid: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0);
  signal wire_header_next: std_logic := '0';
  signal wire_header_idle: std_logic := '0';
  signal wire_footer_next: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0) := (others => '0');
  signal wire_footer_busy: std_logic_vector(CCSDS_TX_FRAMER_FOOTER_NUMBER-1 downto 0);

  signal reg_next_frame: std_logic_vector(CCSDS_TX_FRAMER_DATA_LENGTH*8-CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
  signal reg_current_frame: std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
  signal reg_processing_frame: std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto 0);
  signal next_processing_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;

-- components instanciation and mapping
  begin
  tx_header_0: ccsds_tx_header
    generic map(
      CCSDS_TX_HEADER_LENGTH => CCSDS_TX_FRAMER_HEADER_LENGTH
    )
    port map(
      clk_i => clk_i,
      idl_i => wire_header_idle,
      nxt_i => wire_header_next,
      rst_i => rst_i,
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
        dat_i => reg_processing_frame,
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
    CHKFRAMERP2 : if ((CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO) = 0) generate
      process
      begin
        report "ERROR: PARALLELISM MAX RATIO CANNOT BE 0" severity failure;
        wait;
      end process;
    end generate CHKFRAMERP2;
    
-- internal processing

    --=============================================================================
    -- Begin of frameroutputp
    -- Generate valid frame output on footer data_valid signal
    --=============================================================================
    -- read: rst_i, wire_footer_data, wire_footer_data_valid
    -- write: dat_o, dat_val_o
    -- r/w: next_valid_frame_pointer
    FRAMEROUTPUTP: process (clk_i)
    variable next_valid_frame_pointer : integer range 0 to CCSDS_TX_FRAMER_FOOTER_NUMBER-1 := 0;
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          next_valid_frame_pointer := 0;
          dat_o <= (others => '0');
          dat_val_o <= '0';
        -- generating valid frames output
        else
          dat_o <= wire_footer_data_o(next_valid_frame_pointer);
          if (wire_footer_data_valid(next_valid_frame_pointer) = '1') then
            dat_val_o <= '1';
            if (next_valid_frame_pointer < (CCSDS_TX_FRAMER_FOOTER_NUMBER-1)) then
              next_valid_frame_pointer := (next_valid_frame_pointer + 1);
            else
              next_valid_frame_pointer := 0;
            end if;
          else
            dat_o <= (others => '0');
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
    --=============================================================================
    -- Begin of framerprocessp
    -- Start footer computation on valid header signal
    --=============================================================================
    -- read: wire_header_data, wire_header_data_valid
    -- write: next_processing_frame_pointer, reg_processing_frame, wire_footer_next
    -- r/w: 
    FRAMERPROCESSP: process (clk_i)
    variable reg_next_processing_frame: std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH)*8-1 downto 0);
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          next_processing_frame_pointer <= 0;
          wire_footer_next <= (others => '0');
        else
          if(wire_header_data_valid = '1') then
            reg_processing_frame((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH)*8-1 downto CCSDS_TX_FRAMER_DATA_LENGTH*8) <= wire_header_data;
            -- idle data to be used
            if (wire_header_data(10 downto 0) = "11111111110") then
              reg_processing_frame(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0) <= CCSDS_TX_FRAMER_OID_PATTERN;
              reg_next_processing_frame := reg_current_frame;
            -- current data to be used
            else
              -- continuous data flow header is one clk in advance
              if (CCSDS_TX_FRAMER_DATA_LENGTH*8 = CCSDS_TX_FRAMER_DATA_BUS_SIZE) and (CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO = 1) then
                reg_processing_frame(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0) <= reg_next_processing_frame;
                reg_next_processing_frame := reg_current_frame;
              -- header is synchronous with data
              else
                reg_processing_frame(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto 0) <= reg_current_frame;
              end if;
            end if;
            wire_footer_next(next_processing_frame_pointer) <= '1';
            if (next_processing_frame_pointer = CCSDS_TX_FRAMER_FOOTER_NUMBER-1) then
              next_processing_frame_pointer <= 0;
            else
              next_processing_frame_pointer <= (next_processing_frame_pointer + 1);
            end if;
          end if;
          if (next_processing_frame_pointer = 0) then
            wire_footer_next(CCSDS_TX_FRAMER_FOOTER_NUMBER-1) <= '0';
          else
            wire_footer_next(next_processing_frame_pointer-1) <= '0';
          end if;
        end if;
      end if;
    end process;
    --=============================================================================
    -- Begin of framergeneratep
    -- Generate next_frame, start next header generation
    --=============================================================================
    -- read: dat_val_i, rst_i
    -- write: wire_header_next, reg_current_frame, reg_next_frame
    -- r/w: 
    FRAMERGENERATEP: process (clk_i)
    variable next_frame_write_pos: integer range 0 to (CCSDS_TX_FRAMER_DATA_LENGTH*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1 := (CCSDS_TX_FRAMER_DATA_LENGTH*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1;
    variable frame_output_counter: integer range 0 to (CCSDS_TX_FRAMER_DATA_LENGTH*CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1 := 0;
    variable current_frame_ready: std_logic := '0';
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          current_frame_ready := '0';
          wire_header_next <= '0';
          next_frame_write_pos := (CCSDS_TX_FRAMER_DATA_LENGTH*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1;
          frame_output_counter := 0;
        else
          -- valid data is presented
          if (dat_val_i = '1') then
            -- next frame is full
            if (next_frame_write_pos = 0) then
              reg_current_frame(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0) <= dat_i;
              reg_current_frame(CCSDS_TX_FRAMER_DATA_LENGTH*8-1 downto CCSDS_TX_FRAMER_DATA_BUS_SIZE) <= reg_next_frame;
              -- time to start frame computation
              if (frame_output_counter = 0) then
                frame_output_counter := (CCSDS_TX_FRAMER_DATA_LENGTH*8*CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1;
                wire_header_next <= '1';
                wire_header_idle <= '0';
              -- signal a frame ready for computation
              else
                wire_header_next <= '0';
                frame_output_counter := frame_output_counter - 1;
                current_frame_ready := '1';
              end if;
              next_frame_write_pos := CCSDS_TX_FRAMER_DATA_LENGTH*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE-1;
            -- filling next frame
            else
              reg_next_frame(next_frame_write_pos*CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto (next_frame_write_pos-1)*CCSDS_TX_FRAMER_DATA_BUS_SIZE) <= dat_i;
              next_frame_write_pos := next_frame_write_pos-1;
              -- time to start frame computation
              if (frame_output_counter = 0) then
                frame_output_counter := (CCSDS_TX_FRAMER_DATA_LENGTH*CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1;
                -- no frame is ready
                if (current_frame_ready = '0') then
                  wire_header_next <= '1';
                  wire_header_idle <= '1';
                -- a frame is ready
                else
                  wire_header_next <= '1';
                  wire_header_idle <= '0';
                  current_frame_ready := '0';
                end if;
              else
                frame_output_counter := frame_output_counter - 1;
                wire_header_next <= '0';
              end if;
            end if;
          -- no valid data
          else
            -- time to start frame computation
            if (frame_output_counter = 0) then
              frame_output_counter := (CCSDS_TX_FRAMER_DATA_LENGTH*CCSDS_TX_FRAMER_PARALLELISM_MAX_RATIO*8/CCSDS_TX_FRAMER_DATA_BUS_SIZE)-1;
              if (current_frame_ready = '0') then
                wire_header_next <= '1';
                wire_header_idle <= '1';
              else
                wire_header_next <= '1';
                wire_header_idle <= '0';
                current_frame_ready := '0';
              end if;
            else
              wire_header_next <= '0';
              frame_output_counter := frame_output_counter - 1;
            end if;
          end if;
        end if;
      end if;
    end process;
end structure;
