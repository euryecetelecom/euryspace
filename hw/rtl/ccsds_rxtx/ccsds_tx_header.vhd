-------------------------------
---- Project: EurySPACE CCSDS RX/TX with wishbone interface
---- Design Name: ccsds_tx_header
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
---- 2016/02/28: initial release
---- 2016/10/21: rework
---- 2016/11/03: add idle data flag
-------------------------------
--TODO: static fixed virtual channel now - implement virtual channel service
--TODO: secondary header
--TODO: security header

--TRANSFER FRAME PRIMARY HEADER => 6 octets
--  \  MASTER CHANNEL ID => 12 bits
--      \ TRANSFER FRAME VERSION NUMBER => 2 bits
--      \ SPACECRAFT ID => 10 bits
--  \ VIRTUAL CHANNEL ID => 3 bits
--  \ OCF FLAG => 1 bit
--  \ MASTER CHANNEL FRAME COUNT => 1 octet
--  \ VIRTUAL CHANNEL FRAME COUNT => 1 octet
--  \ TRANSFER FRAME DATA FIELD STATUS => 2 octets
--      \ TRANSFER FRAME SECONDARY HEADER FLAG => 1 bit
--      \ SYNC FLAG => 1 bit
--      \ PACKET ORDER FLAG => 1 bit
--      \ SEGMENT LENGTH ID => 2 bits
--      \ FIRST HEADER POINTER => 11 bits
--[OPT] TRANSFER FRAME SECONDARY HEADER => up to 64 octets
--       \ TRANSFER FRAME SECONDARY HEADER ID => 1 octet
--             \ TRANSFER FRAME SECONDARY HEADER VERSION NUMBER => 2 bits
--             \ TRANSFER FRAME SECONDARY HEADER LENGTH => 6 bits
--       \ TRANSFER FRAME SECONDARY HEADER DATA FIELD => up to 63 octets
--[OPT] SECURITY HEADER

-- libraries used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- Entity declaration for ccsds_tx / unitary tx header inputs and outputs
--=============================================================================
entity ccsds_tx_header is
  generic(
    CCSDS_TX_HEADER_LENGTH: integer; -- in Bytes
    CCSDS_TX_HEADER_MCI_TFVN: std_logic_vector(2-1 downto 0) := "00"; -- Transfer Frame Version Number value
    CCSDS_TX_HEADER_MCI_SID: std_logic_vector(10-1 downto 0) := "1100110011"; -- Spacecraft ID value
    CCSDS_TX_HEADER_MCFC_LENGTH: integer := 8; -- Master Channel Frame Count length - in bits
    CCSDS_TX_HEADER_OCFF: std_logic := '0'; -- Operationnal Control Field Flag
    CCSDS_TX_HEADER_VCI: std_logic_vector(3-1 downto 0) := "000"; -- Virtual Channel Identifier value
    CCSDS_TX_HEADER_VCFC_LENGTH: integer := 8; -- Virtual Channel Frame Count length - in bits
    CCSDS_TX_HEADER_TFDFS_LENGTH: integer := 16; -- Transfer Frame Data Field Status length - in bits
    CCSDS_TX_HEADER_TFDFS_POF: std_logic := '0'; -- Packet Order Flag
    CCSDS_TX_HEADER_TFDFS_SF: std_logic := '0'; -- Synchronization Flag
    CCSDS_TX_HEADER_TFDFS_SLI: std_logic_vector(1 downto 0) := "11"; -- Segment Length Identifier
    CCSDS_TX_HEADER_TFDFS_TFSHF: std_logic := '0' -- Transfer Frame Secondary Header Flag
  );
  port(
    -- inputs
    clk_i: in std_logic;
    idl_i: in std_logic;
    nxt_i: in std_logic;
    rst_i: in std_logic;
    -- outputs
    dat_o: out std_logic_vector(CCSDS_TX_HEADER_LENGTH*8-1 downto 0);
    dat_val_o: out std_logic
  );
end ccsds_tx_header;

--=============================================================================
-- architecture declaration / internal components and connections
--=============================================================================
architecture rtl of ccsds_tx_header is
-- internal variable signals
-- components instanciation and mapping
  begin
  
-- presynthesis checks
    CHKHEADERP0 : if CCSDS_TX_HEADER_LENGTH*8 /= (CCSDS_TX_HEADER_MCI_TFVN'length + CCSDS_TX_HEADER_MCI_SID'length + CCSDS_TX_HEADER_VCI'length + CCSDS_TX_HEADER_MCFC_LENGTH + CCSDS_TX_HEADER_VCFC_LENGTH + CCSDS_TX_HEADER_TFDFS_LENGTH + 1) generate
      process
      begin
        report "ERROR: HEADER LENGTH IS DIFFERENT OF TOTAL SUBELEMENTS LENGTH" severity failure;
	wait;
      end process;
    end generate CHKHEADERP0;
    
-- internal processing

    --=============================================================================
    -- Begin of headerp
    -- Generate valid headers
    --=============================================================================
    -- read: rst_i, nxt_i
    -- write: dat_val_o, dat_o
    -- r/w: 
    HEADERP : process (clk_i)
    variable header_mci_tfvn: std_logic_vector(CCSDS_TX_HEADER_MCI_TFVN'length-1 downto 0) := CCSDS_TX_HEADER_MCI_TFVN; -- Transfer Frame Version Number
    variable header_mci_sid: std_logic_vector(CCSDS_TX_HEADER_MCI_SID'length-1 downto 0) := CCSDS_TX_HEADER_MCI_SID; -- Spacecraft ID
    variable header_vci: std_logic_vector(CCSDS_TX_HEADER_VCI'length-1 downto 0) := CCSDS_TX_HEADER_VCI; -- Virtual Channel Identifier
    variable header_ocff: std_logic := CCSDS_TX_HEADER_OCFF; -- Operationnal Control Field Flag
    variable header_mcfc: integer range 0 to (2**CCSDS_TX_HEADER_MCFC_LENGTH)-1 := 0; -- Master Channel Frame Count
    variable header_vcfc: integer range 0 to (2**CCSDS_TX_HEADER_VCFC_LENGTH)-1 := 0; -- Virtual Channel Frame Count
    variable header_tfdfs_fhp: std_logic_vector(CCSDS_TX_HEADER_TFDFS_LENGTH-6 downto 0) := "00000000000"; -- First Header Pointer / 11111111110 when idle data inside only
    begin
      -- on each clock rising edge
      if rising_edge(clk_i) then
        -- reset signal received
        if (rst_i = '1') then
          dat_o <= (others => '0');
          dat_val_o <= '0';
          header_mci_tfvn := CCSDS_TX_HEADER_MCI_TFVN;
          header_mci_sid := CCSDS_TX_HEADER_MCI_SID;
          header_vci := CCSDS_TX_HEADER_VCI;
          header_ocff := '1';
          header_mcfc := 0;
          header_vcfc := 0;
          header_tfdfs_fhp := "00000000000";
        else
          if (nxt_i = '1') then
            if(idl_i = '1') then
              header_tfdfs_fhp := "11111111110";
            else
              header_tfdfs_fhp := "00000000000";
            end if;
            dat_val_o <= '1';
            dat_o(CCSDS_TX_HEADER_LENGTH*8-1 downto CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length) <= header_mci_tfvn;
            dat_o(CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-1 downto CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length) <= header_mci_sid;
            dat_o(CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-1 downto CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length) <= header_vci;
            dat_o(CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length-1) <= header_ocff;
            dat_o(CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length-1-1 downto CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length-1-CCSDS_TX_HEADER_MCFC_LENGTH) <= std_logic_vector(to_unsigned(header_mcfc,CCSDS_TX_HEADER_MCFC_LENGTH));
            dat_o(CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length-1-CCSDS_TX_HEADER_MCFC_LENGTH-1 downto CCSDS_TX_HEADER_LENGTH*8-CCSDS_TX_HEADER_MCI_TFVN'length-CCSDS_TX_HEADER_MCI_SID'length-CCSDS_TX_HEADER_VCI'length-1-CCSDS_TX_HEADER_MCFC_LENGTH-CCSDS_TX_HEADER_VCFC_LENGTH) <= std_logic_vector(to_unsigned(header_vcfc,CCSDS_TX_HEADER_VCFC_LENGTH));
            dat_o(CCSDS_TX_HEADER_TFDFS_LENGTH-1 downto CCSDS_TX_HEADER_TFDFS_LENGTH-5) <= CCSDS_TX_HEADER_TFDFS_TFSHF & CCSDS_TX_HEADER_TFDFS_SF & CCSDS_TX_HEADER_TFDFS_POF & CCSDS_TX_HEADER_TFDFS_SLI;
            dat_o(CCSDS_TX_HEADER_TFDFS_LENGTH-6 downto 0) <= header_tfdfs_fhp;
            if (header_mcfc = (2**CCSDS_TX_HEADER_MCFC_LENGTH)-1) then
              header_mcfc := 0;
            else
              header_mcfc := header_mcfc + 1;
            end if;
            if (header_vcfc = (2**CCSDS_TX_HEADER_VCFC_LENGTH)-1) then
              header_vcfc := 0;
            else
              header_vcfc := header_vcfc + 1;
            end if;
          else
            dat_val_o <= '0';
          end if;
        end if;
      end if;
    end process;
end rtl;
