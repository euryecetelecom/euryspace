-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_rxtx_srrc
---- Version: 1.0.0
---- Description:
---- Squared Raised Root Cosine FIR filter (pipelined systolic architecture)
---- Input: 1 clk / sam_val_i <= '1' / sam_i <= "SAMPLESDATATOBEFILTERED"
---- Timing requirements: 1 clock cycle for valid output sample / impulse delay = (6*CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*2*2+1) / impulse response time = (6*CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*2+1)
---- Output: sam_val_o <= "1" / sam_o <= "FILTEREDSAMPLES"
---- Ressources requirements: TODO
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
-- Filter impulse response - SRRC(t):
-- t = 0 => SRRC(0) = 1
-- t = +/-Ts/(4*B) => SRRC(+/-Ts/(4*B)) = sin(PI.(1-B)/(4.B)) + cos(PI.(1+B)/(4.B))
-- t /= 0 and t /= Ts/(4*B) => SRRC(t) =  (sin(PI.t.(1-B)/Ts) + 4.B.t.cos(PI.t.(1+B)/Ts)/Ts) / (PI.t.(1-((4.B.t)/Ts)^2)/Ts)
-- t: time
-- Ts: symbol period
-- B: filter roll-off

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary rxtx srrc inputs and outputs
--=============================================================================
entity ccsds_rxtx_srrc is
  generic(
    constant CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE: integer range 0 to 2 := 1; -- 0=Dirichlet (Rectangular) / 1=Hamming / 2=Bartlett (Triangular)
    constant CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO: integer := 4;
    constant CCSDS_RXTX_SRRC_ROLL_OFF: real := 0.5;
    constant CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH: integer
  );
  port(
    -- inputs
    clk_i: in std_logic;
    rst_i: in std_logic;
    sam_i: in std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
    sam_val_i: in std_logic;
    -- outputs
    sam_o: out std_logic_vector(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
    sam_val_o: out std_logic
  );
end ccsds_rxtx_srrc;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture structure of ccsds_rxtx_srrc is
-- internal constants
  constant CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES: integer:= 6; -- in symbol Time
  constant CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER: integer := CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES*2+1;
  constant CCSDS_RXTX_SRRC_NORMALIZATION_GAIN: real := 2.0**(real(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH) - real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO)**0.5 + 1.0) - 1.0; -- Exact value should be (RMS Gain = Sqrt(Sum(Pow(coef,2)))) * Full Scale Value 
  constant CCSDS_RXTX_SRRC_SIG_MUL_SIZE: integer := 2*CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH;
  constant CCSDS_RXTX_SRRC_SIG_ADD_SIZE: integer := CCSDS_RXTX_SRRC_SIG_MUL_SIZE;
-- internal variable signals
  type samples_array is array(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER*2-1 downto 0) of signed(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
  type srrc_tap_array is array(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1 downto 0) of signed(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0);
  type srrc_multiplier_array is array(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1 downto 0) of signed(CCSDS_RXTX_SRRC_SIG_MUL_SIZE-1 downto 0);
  type srrc_adder_array is array(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1 downto 0) of signed(CCSDS_RXTX_SRRC_SIG_ADD_SIZE-1 downto 0);
  signal sam_i_memory: signed(CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH-1 downto 0) := (others => '0');
  signal sam_i_pipeline_registers: samples_array := (others => (others => '0'));
  signal srrc_coefficients: srrc_tap_array;
  signal srrc_multipliers_registers: srrc_multiplier_array := (others => (others => '0'));
  signal srrc_adders_registers: srrc_adder_array := (others => (others => '0'));
  signal srrc_zero: signed(CCSDS_RXTX_SRRC_SIG_ADD_SIZE-1 downto 0) := (others => '0');
 
-- components instanciation and mapping
  begin
    -- SRRC coefficients generation
    -- At t = 0
    srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES) <= to_signed(integer(CCSDS_RXTX_SRRC_NORMALIZATION_GAIN),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
    -- Coefficients are symetrical / they are computed only for positive time response
    SRRC_COEFS_GENERATOR: for coefficient_counter in 1 to CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES generate
      -- At t = Ts/(4*B)
      SRRC_SPECIFIC_COEFS: if (real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO)/real(coefficient_counter) = 4.0*CCSDS_RXTX_SRRC_ROLL_OFF) generate
        SRRC_COEFS_WINDOW_DIRICHLET: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 0) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer(CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)) + cos(MATH_PI * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_DIRICHLET;
        SRRC_COEFS_WINDOW_HAMMING: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 1) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer((0.54 + 0.46 * cos(2.0 * MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1))) * CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)) + cos(MATH_PI * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_HAMMING;
        SRRC_COEFS_WINDOW_BARTLETT: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 2) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer((1.0 - abs((real(coefficient_counter) - real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1)/2.0) / real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1)/2.0)) * CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)) + cos(MATH_PI * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF) / (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF)))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_BARTLETT;
      end generate SRRC_SPECIFIC_COEFS;
      -- At t > 0 and t /= Ts/(4*B)
      SRRC_GENERIC_COEFS: if (real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO)/real(coefficient_counter) /= 4.0*CCSDS_RXTX_SRRC_ROLL_OFF) generate
        SRRC_COEFS_WINDOW_DIRICHLET: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 0) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer(CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF)) + 4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * cos(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF))) / (MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO))**2))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_DIRICHLET;
        SRRC_COEFS_WINDOW_HAMMING: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 1) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer((0.54 + 0.46 * cos(2.0 * MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1))) *CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF)) + 4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * cos(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF))) / (MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO))**2))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_HAMMING;
        SRRC_COEFS_WINDOW_BARTLETT: if (CCSDS_RXTX_SRRC_APODIZATION_WINDOW_TYPE = 2) generate
          srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter) <= to_signed(integer((1.0 - abs((real(coefficient_counter) - real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1)/2.0) / real(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1)/2.0)) * CCSDS_RXTX_SRRC_NORMALIZATION_GAIN * (sin(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - CCSDS_RXTX_SRRC_ROLL_OFF)) + 4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * cos(MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 + CCSDS_RXTX_SRRC_ROLL_OFF))) / (MATH_PI * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO) * (1.0 - (4.0 * CCSDS_RXTX_SRRC_ROLL_OFF * real(coefficient_counter) / real(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO))**2))),CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH);
        end generate SRRC_COEFS_WINDOW_BARTLETT;
      end generate SRRC_GENERIC_COEFS;
      -- Setting symetrical coefficients (t < 0)
      srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES-coefficient_counter) <= srrc_coefficients(CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO*CCSDS_RXTX_SRRC_RESPONSE_SYMBOL_CYCLES+coefficient_counter);
    end generate SRRC_COEFS_GENERATOR;
-- presynthesis checks
	  CHKSRRCP0: if CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO mod 2 /= 0 generate
		  process
		  begin
			  report "ERROR: SRRC OVERSAMPLING RATIO MUST BE A MULTIPLE OF 2" severity failure;
			  wait;
		  end process;
	  end generate CHKSRRCP0;
	  CHKSRRCP1: if CCSDS_RXTX_SRRC_OVERSAMPLING_RATIO = 0 generate
		  process
		  begin
			  report "ERROR: SRRC OVERSAMPLING RATIO CANNOT BE NULL" severity failure;
			  wait;
		  end process;
	  end generate CHKSRRCP1;
	  CHKSRRCP2: if (CCSDS_RXTX_SRRC_ROLL_OFF < 0.0) or (CCSDS_RXTX_SRRC_ROLL_OFF > 1.0) generate
		  process
		  begin
			  report "ERROR: SRRC ROLL OFF HAS TO BE BETWEEN 0.0 AND 1.0" severity failure;
			  wait;
		  end process;
	  end generate CHKSRRCP2;
-- internal processing
    --=============================================================================
    -- Begin of srrcp
    -- FIR filter coefficients
    --=============================================================================
    -- read: rst_i, sam_val_i, sam_i
    -- write: sam_o, sam_val_o
    -- r/w: sam_i_memory, sam_i_pipeline_registers, srrc_adders_registers, srrc_multipliers_registers
    SRRCP: process (clk_i)
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          sam_o <= (others => '0');
          sam_val_o <= '0';
        else
          if (sam_val_i = '1') then
            sam_val_o <= '1';
            sam_i_pipeline_registers(0) <= signed(sam_i);
            sam_i_pipeline_registers(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER*2-1 downto 1) <= sam_i_pipeline_registers(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER*2-2 downto 0);
            for i in 0 to CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1 loop
              srrc_multipliers_registers(i) <= sam_i_pipeline_registers(i*2) * srrc_coefficients(i);
              if (i = 0) then
                srrc_adders_registers(i) <= srrc_multipliers_registers(i) + srrc_zero;
              else
                srrc_adders_registers(i) <= srrc_multipliers_registers(i) + srrc_adders_registers(i-1);
              end if;
            end loop;
            sam_o <= std_logic_vector(srrc_adders_registers(CCSDS_RXTX_SRRC_FIR_COEFFICIENTS_NUMBER-1)(CCSDS_RXTX_SRRC_SIG_ADD_SIZE-1 downto CCSDS_RXTX_SRRC_SIG_ADD_SIZE-CCSDS_RXTX_SRRC_SIG_QUANT_DEPTH));
          else
            sam_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end structure;
