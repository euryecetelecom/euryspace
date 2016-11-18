-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_filter
---- Version: 1.0.0
---- Description:
---- Transform symbols to samples, oversample signal and filter it with SRRC filter
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/11/06: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx filter inputs and outputs
--=============================================================================
entity ccsds_tx_filter is
  generic(
    constant CCSDS_TX_FILTER_BITS_PER_SYMBOL: integer; -- in bits
    constant CCSDS_TX_FILTER_OVERSAMPLING_RATIO: integer;
    constant CCSDS_TX_FILTER_OFFSET_IQ: boolean := true;
    constant CCSDS_TX_FILTER_MODULATION_TYPE: integer;
    constant CCSDS_TX_FILTER_SIG_QUANT_DEPTH: integer
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    sym_i_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
    sym_q_i: in std_logic_vector(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0);
    sym_val_i: in std_logic;
    -- outputs
    sam_i_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
    sam_q_o: out std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
    sam_val_o: out std_logic
  );
end ccsds_tx_filter;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_tx_filter is
  component ccsds_rxtx_oversampler is
    generic(
      CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO: integer;
      CCSDS_RXTX_OVERSAMPLER_SYMBOL_DEPHASING: boolean;
      CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH: integer
    );
    port(
      clk_i: in std_logic;
      sam_i: in std_logic_vector(CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_i: in std_logic;
      rst_i: in std_logic;
      sam_o: out std_logic_vector(CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_o: out std_logic
    );
  end component;
  component ccsds_rxtx_srrc is
    generic(
      CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO: integer;
      CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      sam_i: in std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_i: in std_logic;
      sam_o: out std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
      sam_val_o: out std_logic
    );
  end component;
-- internal constants
-- internal variable signals
  signal wire_sam_i: std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
  signal wire_sam_q: std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
  signal wire_sam_i_val: std_logic := '0';
  signal wire_sam_q_val: std_logic := '0';
  signal wire_sam_i_osr: std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
  signal wire_sam_q_osr: std_logic_vector(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1 downto 0);
  signal wire_sam_i_osr_val: std_logic;
  signal wire_sam_q_osr_val: std_logic;
  signal wire_sam_i_srrc_val: std_logic;
  signal wire_sam_q_srrc_val: std_logic;
-- components instanciation and mapping
  begin
  tx_oversampler_i_0: ccsds_rxtx_oversampler
    generic map(
      CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO => CCSDS_TX_FILTER_OVERSAMPLING_RATIO,
      CCSDS_RXTX_OVERSAMPLER_SYMBOL_DEPHASING => false,
      CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH => CCSDS_TX_FILTER_SIG_QUANT_DEPTH
    )
    port map(
      clk_i => clk_i,
      sam_i => wire_sam_i,
      sam_val_i => wire_sam_i_val,
      rst_i => rst_i,
      sam_val_o => wire_sam_i_osr_val,
      sam_o => wire_sam_i_osr
    );
  tx_srrc_i_0: ccsds_rxtx_srrc
    generic map(
      CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_TX_FILTER_OVERSAMPLING_RATIO,
      CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_TX_FILTER_SIG_QUANT_DEPTH
    )
    port map(
      clk_i => clk_i,
      sam_i => wire_sam_i_osr,
      sam_val_i => wire_sam_i_osr_val,
      rst_i => rst_i,
      sam_o => sam_i_o,
      sam_val_o => wire_sam_i_srrc_val
    );
  -- BPSK
  BPSK_GENERATION: if (CCSDS_TX_FILTER_BITS_PER_SYMBOL = 1) and (CCSDS_TX_FILTER_MODULATION_TYPE = 2) generate
    sam_q_o <= (others => '0');
    wire_sam_q_srrc_val <= '1';
  end generate BPSK_GENERATION;
  -- nPSK
  NPSK_GENERATION: if (CCSDS_TX_FILTER_MODULATION_TYPE /= 2) or (CCSDS_TX_FILTER_BITS_PER_SYMBOL /= 1) generate
    tx_oversampler_q_0: ccsds_rxtx_oversampler
      generic map(
        CCSDS_RXTX_OVERSAMPLER_OVERSAMPLING_RATIO => CCSDS_TX_FILTER_OVERSAMPLING_RATIO,
        CCSDS_RXTX_OVERSAMPLER_SYMBOL_DEPHASING => CCSDS_TX_FILTER_OFFSET_IQ,
        CCSDS_RXTX_OVERSAMPLER_SIG_QUANT_DEPTH => CCSDS_TX_FILTER_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => clk_i,
        sam_i => wire_sam_q,
        sam_val_i => wire_sam_q_val,
        rst_i => rst_i,
        sam_val_o => wire_sam_q_osr_val,
        sam_o => wire_sam_q_osr
      );
    tx_srrc_q_0: ccsds_rxtx_srrc
      generic map(
        CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO => CCSDS_TX_FILTER_OVERSAMPLING_RATIO,
        CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH => CCSDS_TX_FILTER_SIG_QUANT_DEPTH
      )
      port map(
        clk_i => clk_i,
        sam_i => wire_sam_q_osr,
        sam_val_i => wire_sam_q_osr_val,
        rst_i => rst_i,
        sam_o => sam_q_o,
        sam_val_o => wire_sam_q_srrc_val
      );
    end generate NPSK_GENERATION;
    --Valid samples indicator
    sam_val_o <= wire_sam_i_srrc_val and wire_sam_q_srrc_val;
-- presynthesis checks
	  CHKFILTERP0: if (CCSDS_TX_FILTER_BITS_PER_SYMBOL > 2*(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1)) generate
		  process
		  begin
			  report "ERROR: BITS PER SYMBOL CANNOT BE HIGHER THAN 2*(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1)" severity failure;
			  wait;
		  end process;
	  end generate CHKFILTERP0;
-- internal processing
--=============================================================================
    -- Begin of samplesp
    -- Convert symbols to signed samples
    --=============================================================================
    -- read: rst_i, sym_i, sym_val_i
    -- write: wire_sam_i,  wire_sam_i_val, wire_sam_q, wire_sam_q_val
    -- r/w:
    SAMPLESP: process (clk_i)
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          wire_sam_i_val <= '0';
          wire_sam_q_val <= '0';
        else
          if (sym_val_i = '1') then
            wire_sam_i_val <= '1';
            wire_sam_q_val <= '1';
            if (CCSDS_TX_FILTER_BITS_PER_SYMBOL > 1) then
              wire_sam_i(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-2 downto CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL) <= sym_i_i(CCSDS_TX_FILTER_BITS_PER_SYMBOL-2 downto 0);
              wire_sam_q(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-2 downto CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL) <= sym_q_i(CCSDS_TX_FILTER_BITS_PER_SYMBOL-2 downto 0);
            end if;
            -- positive I value
            if (sym_i_i(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1) = '1') then
              wire_sam_i(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1) <= '0';
              wire_sam_i(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0) <= (others => '1');
            --negative I value
            else
              wire_sam_i(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1) <= '1';
              wire_sam_i(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0) <= (others => '0');
            end if;
            -- positive Q value
            if (sym_q_i(CCSDS_TX_FILTER_BITS_PER_SYMBOL-1) = '1') then
              wire_sam_q(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1) <= '0';
              wire_sam_q(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0) <= (others => '1');
            -- negative Q value
            else
              wire_sam_q(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-1) <= '1';
              wire_sam_q(CCSDS_TX_FILTER_SIG_QUANT_DEPTH-CCSDS_TX_FILTER_BITS_PER_SYMBOL-1 downto 0) <= (others => '0');
            end if;
          else
            wire_sam_i_val <= '0';
            wire_sam_q_val <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
