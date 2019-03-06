-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_coder
---- Version: 1.0.0
---- Description:
---- Implementation of standard CCSDS 131.0-B-2
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
-- Entity declaration for ccsds_tx / unitary tx coder inputs and outputs
--=============================================================================
entity ccsds_tx_coder is
  generic(
    constant CCSDS_TX_CODER_ASM_LENGTH: integer; -- Attached Synchronization Marker length / in Bytes
    constant CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT: integer; -- in bits
    constant CCSDS_TX_CODER_DATA_BUS_SIZE: integer; -- in bits
    constant CCSDS_TX_CODER_DIFFERENTIAL_BITS_PER_CODEWORD: integer; -- Number of bits per codeword (should be equal to bits per symbol of lower link)
    constant CCSDS_TX_CODER_DIFFERENTIAL_ENABLED: boolean -- Enable differential coder
  );
  port(
    -- inputs
    clk_i: in std_logic;
    dat_i: in std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
    dat_val_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector((CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8)*CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_coder;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_coder is
  component ccsds_tx_coder_convolutional is
    generic(
      CCSDS_TX_CODER_CONV_DATA_BUS_SIZE: integer;
      CCSDS_TX_CODER_CONV_RATE_OUTPUT: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      bus_o: out std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_CODER_CONV_DATA_BUS_SIZE*CCSDS_TX_CODER_CONV_RATE_OUTPUT-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_coder_differential is
    generic(
      CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD: integer;
      CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_randomizer is
    generic(
      CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
  component ccsds_tx_synchronizer is
    generic(
      CCSDS_TX_ASM_LENGTH: integer;
      CCSDS_TX_ASM_DATA_BUS_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      dat_i: in std_logic_vector(CCSDS_TX_ASM_DATA_BUS_SIZE-1 downto 0);
      dat_val_i: in std_logic;
      rst_i: in std_logic;
      dat_o: out std_logic_vector(CCSDS_TX_ASM_DATA_BUS_SIZE+CCSDS_TX_ASM_LENGTH*8-1 downto 0);
      dat_val_o: out std_logic
    );
  end component;
-- internal constants
-- internal variable signals
  signal wire_coder_diff_dat_o: std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8-1 downto 0);
  signal wire_coder_diff_dat_val_o: std_logic;
  signal wire_randomizer_dat_o: std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE-1 downto 0);
  signal wire_randomizer_dat_val_o: std_logic;
  signal wire_synchronizer_dat_o: std_logic_vector(CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8-1 downto 0);
  signal wire_synchronizer_dat_val_o: std_logic;
  --HERE CONV
-- components instanciation and mapping
  begin
  tx_coder_randomizer_0: ccsds_tx_randomizer
    generic map(
      CCSDS_TX_RANDOMIZER_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_val_i => dat_val_i,
      dat_i => dat_i,
      dat_val_o => wire_randomizer_dat_val_o,
      dat_o => wire_randomizer_dat_o
    );
  NODIFFCODERGENP: if (CCSDS_TX_CODER_DIFFERENTIAL_ENABLED = false) generate
    tx_coder_synchronizer_0: ccsds_tx_synchronizer
      generic map(
        CCSDS_TX_ASM_LENGTH => CCSDS_TX_CODER_ASM_LENGTH,
        CCSDS_TX_ASM_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        dat_val_i => wire_randomizer_dat_val_o,
        dat_i => wire_randomizer_dat_o,
        dat_val_o => wire_synchronizer_dat_val_o,
        dat_o => wire_synchronizer_dat_o
      );
    tx_coder_convolutionnal_0: ccsds_tx_coder_convolutional
      generic map(    
        CCSDS_TX_CODER_CONV_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8,
        CCSDS_TX_CODER_CONV_RATE_OUTPUT => CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => wire_synchronizer_dat_o,
        dat_val_i => wire_synchronizer_dat_val_o,
--        bus_o => ,
        dat_o => dat_o,
        dat_val_o => dat_val_o
      );
   end generate NODIFFCODERGENP;
  DIFFCODERGENP: if (CCSDS_TX_CODER_DIFFERENTIAL_ENABLED = true) generate
    tx_coder_synchronizer_0: ccsds_tx_synchronizer
      generic map(
        CCSDS_TX_ASM_LENGTH => CCSDS_TX_CODER_ASM_LENGTH,
        CCSDS_TX_ASM_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        dat_val_i => wire_randomizer_dat_val_o,
        dat_i => wire_randomizer_dat_o,
        dat_val_o => wire_synchronizer_dat_val_o,
        dat_o => wire_synchronizer_dat_o
      );
    tx_coder_differential_0: ccsds_tx_coder_differential
      generic map(
        CCSDS_TX_CODER_DIFF_BITS_PER_CODEWORD => CCSDS_TX_CODER_DIFFERENTIAL_BITS_PER_CODEWORD,
        CCSDS_TX_CODER_DIFF_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        dat_val_i => wire_synchronizer_dat_val_o,
        dat_i => wire_synchronizer_dat_o,
        dat_val_o => wire_coder_diff_dat_val_o,
        dat_o => wire_coder_diff_dat_o
      );
    tx_coder_convolutionnal_0: ccsds_tx_coder_convolutional
      generic map(
        CCSDS_TX_CODER_CONV_DATA_BUS_SIZE => CCSDS_TX_CODER_DATA_BUS_SIZE+CCSDS_TX_CODER_ASM_LENGTH*8,
        CCSDS_TX_CODER_CONV_RATE_OUTPUT => CCSDS_TX_CODER_CONVOLUTIONNAL_RATE_OUTPUT
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => wire_coder_diff_dat_o,
        dat_val_i => wire_coder_diff_dat_val_o,
--        bus_o => ,
        dat_o => dat_o,
        dat_val_o => dat_val_o
      );
   end generate DIFFCODERGENP;
-- presynthesis checks
-- internal processing
end structure;
