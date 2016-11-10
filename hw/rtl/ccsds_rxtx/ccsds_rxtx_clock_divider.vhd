-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_clock_divider
---- Version: 1.0.0
---- Description:
---- Generate output clock = input clock / divider
-------------------------------
---- Author(s):
---- Guillaume REMBERT
-------------------------------
---- Licence:
---- MIT
-------------------------------
---- Changes list:
---- 2016/11/05: initial release
-------------------------------

-- libraries used
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx clock generator inputs and outputs
--=============================================================================
entity ccsds_rxtx_clock_divider is
  generic(
    constant CCSDS_RXTX_CLOCK_DIVIDER: integer range 1 to 4096
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    clk_o: out std_logic
  );
end ccsds_rxtx_clock_divider;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_rxtx_clock_divider is
-- internal constants
-- internal variable signals
-- components instanciation and mapping
  begin
-- presynthesis checks
	  CHKCLKDIV0: if (CCSDS_RXTX_CLOCK_DIVIDER mod 2 /= 0) and (CCSDS_RXTX_CLOCK_DIVIDER /= 1) generate
		  process
		  begin
			  report "ERROR: CLOCK DIVIDER MUST BE A MULTIPLE OF 2 OR 1" severity failure;
			  wait;
		  end process;
	  end generate CHKCLKDIV0;
-- internal processing
  CLOCKDIVIDER1P: if (CCSDS_RXTX_CLOCK_DIVIDER = 1) generate
    clk_o <= clk_i and (not rst_i);
  end generate CLOCKDIVIDER1P;
  CLOCKDIVIDERNP: if (CCSDS_RXTX_CLOCK_DIVIDER /= 1) generate
    --=============================================================================
    -- Begin of clockdividerp
    -- Clock divider
    --=============================================================================
    -- read: rst_i
    -- write: clk_o
    -- r/w:
    CLOCKDIVIDERP : process (clk_i, rst_i)
    -- variables instantiation
    variable counter: integer range 0 to CCSDS_RXTX_CLOCK_DIVIDER/2-1 := CCSDS_RXTX_CLOCK_DIVIDER/2-1;
    variable clock_state: std_logic := '1';
    begin
      if (rst_i = '1') then
        clk_o <= '0';
        clock_state := '1';
        counter := CCSDS_RXTX_CLOCK_DIVIDER/2-1;
      else
        -- on each clock rising edge
        if rising_edge(clk_i) then
          clk_o <= clock_state;
          if (counter = 0) then
            clock_state := clock_state xor '1';
            counter := CCSDS_RXTX_CLOCK_DIVIDER/2-1;
          else
            counter := counter-1;
          end if;
        end if;
      end if;
    end process;
  end generate CLOCKDIVIDERNP;
end structure;
