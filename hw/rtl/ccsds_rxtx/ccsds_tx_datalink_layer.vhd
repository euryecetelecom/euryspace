-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_datalink_layer
---- Version: 1.0.0
---- Description:
---- TM (TeleMetry) Space Data Link Protocol
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
-- Entity declaration for ccsds_tx / unitary tx datalink layer inputs and outputs
--=============================================================================
entity ccsds_tx_datalink_layer is
  generic (
    constant CCSDS_TX_DATALINK_ASM_LENGTH: integer := 4; -- Attached Synchronization Marker length / in Bytes
    constant CCSDS_TX_DATALINK_CODER_CONVOLUTIONNAL_RATE_OUTPUT: integer := 2; -- Convolutional coder output rate per input bit (bits)
    constant CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_ENABLED: boolean := false; -- Enable differential coder
    constant CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_BITS_PER_CODEWORD: integer; -- Number of bits per codeword from differential coder
    constant CCSDS_TX_DATALINK_DATA_BUS_SIZE: integer; -- in bits
    constant CCSDS_TX_DATALINK_DATA_LENGTH: integer := 12; -- datagram data size (Bytes) / (has to be a multiple of CCSDS_TX_DATALINK_DATA_BUS_SIZE)
    constant CCSDS_TX_DATALINK_FOOTER_LENGTH: integer := 2; -- datagram footer length (Bytes)
    constant CCSDS_TX_DATALINK_HEADER_LENGTH: integer := 6 -- datagram header length (Bytes)
  );
  port(
    -- inputs
    clk_bit_i: in std_logic;
    clk_dat_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
    dat_nxt_o: out std_logic;
    dat_val_o: out std_logic;
    idl_o: out std_logic
  );
end ccsds_tx_datalink_layer;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_datalink_layer is
  component ccsds_tx_framer is
    generic(
      CCSDS_TX_FRAMER_DATA_BUS_SIZE : integer;
      CCSDS_TX_FRAMER_DATA_LENGTH : integer;
      CCSDS_TX_FRAMER_FOOTER_LENGTH : integer;
      CCSDS_TX_FRAMER_HEADER_LENGTH : integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      dat_o: out std_logic_vector((CCSDS_TX_FRAMER_DATA_LENGTH+CCSDS_TX_FRAMER_HEADER_LENGTH+CCSDS_TX_FRAMER_FOOTER_LENGTH)*8-1 downto 0);
      dat_val_o: out std_logic;
      dat_nxt_o: out std_logic;
      idl_o: out std_logic
    );
  end component;
  component ccsds_tx_coder is
    generic(
      CCSDS_TX_CODER_DIFFERENTIAL_BITS_PER_CODEWORD: integer;
      CCSDS_TX_CODER_DIFFERENTIAL_ENABLED: boolean;
      CCSDS_TX_CODER_DATA_BUS_SIZE: integer;
      CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT: integer;
      CCSDS_TX_CODER_ASM_LENGTH: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector((CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8)*CCSDS_TX_DATALINK_CODER_CONVOLUTIONNAL_RATE_OUTPUT-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;

-- internal constants
  constant FRAME_OUTPUT_SIZE: integer := (CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH+CCSDS_TX_DATALINK_ASM_LENGTH)*8*CCSDS_TX_DATALINK_CODER_CONVOLUTIONNAL_RATE_OUTPUT;
  constant FRAME_OUTPUT_WORDS: integer := FRAME_OUTPUT_SIZE/CCSDS_TX_DATALINK_DATA_BUS_SIZE;
  constant TRIGGER_COUNTER_CLOCK_DURATION: integer := 8;

-- internal registers
  signal current_frame: std_logic_vector(FRAME_OUTPUT_SIZE-1 downto 0) := (others => '0');
  signal new_frame: std_logic := '0';

-- interconnection signals
  signal wire_framer_data: std_logic_vector((CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8-1 downto 0);
  signal wire_framer_data_valid: std_logic;
  signal wire_coder_data: std_logic_vector(FRAME_OUTPUT_SIZE-1 downto 0);
  signal wire_coder_data_valid: std_logic;

-- components instanciation and mapping
  begin

  tx_datalink_framer_0: ccsds_tx_framer
    generic map(
      CCSDS_TX_FRAMER_HEADER_LENGTH => CCSDS_TX_DATALINK_HEADER_LENGTH,
      CCSDS_TX_FRAMER_DATA_LENGTH => CCSDS_TX_DATALINK_DATA_LENGTH,
      CCSDS_TX_FRAMER_FOOTER_LENGTH => CCSDS_TX_DATALINK_FOOTER_LENGTH,
      CCSDS_TX_FRAMER_DATA_BUS_SIZE => CCSDS_TX_DATALINK_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_dat_i,
      rst_i => rst_i,
      dat_val_i => dat_val_i,
      dat_i => dat_i,
      dat_val_o => wire_framer_data_valid,
      dat_nxt_o => dat_nxt_o,
      dat_o => wire_framer_data,
      idl_o => idl_o
    );
  tx_datalink_coder_0: ccsds_tx_coder
    generic map(
      CCSDS_TX_CODER_ASM_LENGTH => CCSDS_TX_DATALINK_ASM_LENGTH,
      CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT => CCSDS_TX_DATALINK_CODER_CONVOLUTIONNAL_RATE_OUTPUT,
      CCSDS_TX_CODER_DATA_BUS_SIZE => (CCSDS_TX_DATALINK_DATA_LENGTH+CCSDS_TX_DATALINK_HEADER_LENGTH+CCSDS_TX_DATALINK_FOOTER_LENGTH)*8,
      CCSDS_TX_CODER_DIFFERENTIAL_BITS_PER_CODEWORD => CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_BITS_PER_CODEWORD,
      CCSDS_TX_CODER_DIFFERENTIAL_ENABLED => CCSDS_TX_DATALINK_CODER_DIFFERENTIAL_ENABLED
    )
    port map(
      clk_i => clk_dat_i,
      dat_i => wire_framer_data,
      dat_val_i => wire_framer_data_valid,
      rst_i => rst_i,
      dat_val_o => wire_coder_data_valid,
      dat_o => wire_coder_data
    );
-- presynthesis checks
-- internal processing

    --=============================================================================
    -- Begin of bitsvalidp
    -- Catch and signal to bitsoutputp valid bits to be outputed
    --=============================================================================
    -- read: rst_i, wire_coder_data, wire_coder_data_valid
    -- write: current_frame, new_frame
    -- r/w: 
    BITSVALIDP: process (clk_dat_i)
    variable trigger_counter_clock_cycles: integer range 0 to TRIGGER_COUNTER_CLOCK_DURATION := 0;
    begin
      -- on each clock rising edge
      if rising_edge(clk_dat_i) then
        -- reset signal received
        if (rst_i = '1') then
          new_frame <= '0';
          trigger_counter_clock_cycles := 0;
        else
          if (wire_coder_data_valid = '1') then
            current_frame <= wire_coder_data;
            new_frame <= '1';
            trigger_counter_clock_cycles := 0;
          else
            if (trigger_counter_clock_cycles = TRIGGER_COUNTER_CLOCK_DURATION) then
              new_frame <= '0';
            else
              trigger_counter_clock_cycles := trigger_counter_clock_cycles + 1;
            end if;
          end if;
        end if;
      end if;
    end process;


    --=============================================================================
    -- Begin of bitsoutputp
    -- Generate bits output word by word based on coder output
    --=============================================================================
    -- read: rst_i, current_frame, new_frame
    -- write: dat_o, dat_val_o
    -- r/w: 
    BITSOUTPUTP: process (clk_bit_i)
    variable next_word_pointer : integer range 0 to FRAME_OUTPUT_WORDS := FRAME_OUTPUT_WORDS - 1;
    begin
      -- on each clock rising edge
      if rising_edge(clk_bit_i) then
        -- reset signal received
        if (rst_i = '1') then
          next_word_pointer := FRAME_OUTPUT_WORDS - 1;
          dat_o <= (others => '0');
          dat_val_o <= '0';
        else
          -- generating valid bits output words
          if (next_word_pointer = FRAME_OUTPUT_WORDS - 1) then
            if (new_frame = '1') then
--              current_frame := wire_coder_data(FRAME_OUTPUT_SIZE-CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto 0);
--              dat_o <= wire_coder_data(FRAME_OUTPUT_SIZE-1 downto FRAME_OUTPUT_SIZE-CCSDS_TX_DATALINK_DATA_BUS_SIZE);
              dat_o <= current_frame(FRAME_OUTPUT_SIZE-1 downto FRAME_OUTPUT_SIZE-CCSDS_TX_DATALINK_DATA_BUS_SIZE);
              next_word_pointer := FRAME_OUTPUT_WORDS - 2;
              dat_val_o <= '1';
            else
              dat_val_o <= '0';
            end if;
          else
            dat_o <= current_frame((next_word_pointer+1)*CCSDS_TX_DATALINK_DATA_BUS_SIZE-1 downto next_word_pointer*CCSDS_TX_DATALINK_DATA_BUS_SIZE);
            if (next_word_pointer = 0) then
              next_word_pointer := FRAME_OUTPUT_WORDS - 1;
            else
              next_word_pointer := next_word_pointer - 1;
            end if;
          end if;
        end if;
      end if;
    end process;
end structure;
