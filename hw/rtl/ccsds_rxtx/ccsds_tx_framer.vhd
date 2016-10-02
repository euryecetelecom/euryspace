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
-------------------------------

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
--TRANSFER FRAME DATA FIELD => Variable
--[OPT] SECURITY TRAILER
--[OPT] TRANSFER FRAME TRAILER (2 to 6 octets)
--       \ [OPT] OPERATIONAL CONTROL FIELD => 4 octets
--       \ [OPT] Frame error control field => 2 octets


-- libraries used
library ieee;
use ieee.std_logic_1164.all;

    --TBD: FIXME check granularity before synthesis for bus data size and total frame size (in words terms)

-- unitary tx framer
entity ccsds_tx_framer is
  generic(
    CCSDS_TX_FRAMER_HEADER_SIZE : integer := 6; -- in Bytes
    CCSDS_TX_FRAMER_DATA_SIZE : integer := 32; -- in Bytes
    CCSDS_TX_FRAMER_TRAILER_SIZE : integer := 2; -- in Bytes
    CCSDS_TX_FRAMER_DATA_BUS_SIZE : integer := 32 -- in bits
  );
  port(
    clk_i: in std_logic;
    clk_o: out std_logic;
    rst_i: in std_logic;
    buf_empty_i: in std_logic;
    next_data_o: out std_logic;
    data_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
    data_valid_i: in std_logic;
    data_o: out std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
    data_valid_o: out std_logic
  );
end ccsds_tx_framer;

architecture structure of ccsds_tx_framer is

  component ccsds_tx_header is
    generic(
      CCSDS_TX_HEADER_SIZE: integer
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      nxt_i: in std_logic;
      data_o: out std_logic_vector(CCSDS_TX_FRAMER_HEADER_SIZE*8-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

  component ccsds_tx_trailer is
    generic(
      CCSDS_TX_TRAILER_DATA_BUS_SIZE : integer := 32; -- in bits
      CCSDS_TX_TRAILER_SIZE: integer := 2 -- in Bytes
    );
    port(
      clk_i: in std_logic;
      rst_i: in std_logic;
      data_i: in std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);
      data_valid_i: in std_logic;
      data_o: out std_logic_vector(CCSDS_TX_FRAMER_TRAILER_SIZE*8-1 downto 0);
      data_valid_o: out std_logic
    );
  end component;

--  signal wire_nxt_h: std_logic;
  signal wire_data_header: std_logic_vector(CCSDS_TX_FRAMER_HEADER_SIZE*8-1 downto 0);
  signal wire_data_trailer: std_logic_vector(CCSDS_TX_FRAMER_TRAILER_SIZE*8-1 downto 0);
  signal wire_data_valid_header: std_logic;
  signal wire_data_valid_trailer: std_logic;
  signal ccsds_tx_framer_data_o: std_logic_vector(CCSDS_TX_FRAMER_DATA_BUS_SIZE-1 downto 0);

-- internal variable signals
  signal wire_rst_header: std_logic := '0';
  signal wire_rst_trailer: std_logic := '0';
  signal wire_next_header: std_logic := '0';
  type frame_array is array (CCSDS_TX_FRAMER_HEADER_SIZE+CCSDS_TX_FRAMER_TRAILER_SIZE+CCSDS_TX_FRAMER_DATA_SIZE-1 downto 0) of std_logic_vector(7 downto 0);
  signal current_frame: frame_array;
  signal current_frame_ready: std_logic := '0';
  signal current_frame_transmitted: std_logic := '0';
  signal current_frame_read_pos: integer range 0 to CCSDS_TX_FRAMER_HEADER_SIZE+CCSDS_TX_FRAMER_TRAILER_SIZE+CCSDS_TX_FRAMER_DATA_SIZE-1 := 0;
  signal next_frame: frame_array;
  signal next_frame_ready: std_logic := '0';
  signal next_frame_flushed: std_logic := '0';
  signal next_frame_write_pos: integer range 0 to CCSDS_TX_FRAMER_HEADER_SIZE+CCSDS_TX_FRAMER_TRAILER_SIZE+CCSDS_TX_FRAMER_DATA_SIZE-1 := 0;

-- components instanciation and mapping
  begin
  tx_header_0: ccsds_tx_header
    generic map(
      CCSDS_TX_HEADER_SIZE => CCSDS_TX_FRAMER_HEADER_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => wire_rst_header,
      nxt_i => wire_next_header,
      data_o => wire_data_header,
      data_valid_o => wire_data_valid_header
    );

  tx_trailer_0: ccsds_tx_trailer
    generic map(
      CCSDS_TX_TRAILER_DATA_BUS_SIZE => CCSDS_TX_FRAMER_DATA_BUS_SIZE,
      CCSDS_TX_TRAILER_SIZE => CCSDS_TX_FRAMER_TRAILER_SIZE
    )
    port map(
      clk_i => clk_i,
      rst_i => wire_rst_trailer,
      data_i => (others => '1'),
      data_valid_i => '0',
    -- new_data_i ?? / utilisation du rst??
      data_o => wire_data_trailer,
      data_valid_o => wire_data_valid_trailer
    );


    
  FRAMERGENP: process (clk_i)
--  variable header_done: std_logic := '0';
--  if data_valid_i
--  if trailer ok i
--> copy header + copy data + copy trailer
--> not forget to update next data to on and off when needed
  begin
    -- on each clock rising edge
    if rising_edge(clk_i) then
      -- reset signal received
      if (rst_i = '1') then
        next_data_o <= '0';
        wire_rst_header <= '1';
        wire_rst_trailer <= '1';
        wire_next_header <= '0';
--        next_frame <= (others => '0');
        next_frame_ready <= '0';
        next_frame_write_pos <= 0;
      else
        if (next_frame_write_pos = 0) then
          wire_rst_trailer <= '0';
          next_frame_ready <= '0';
          if (wire_data_valid_header = '1') then
            next_frame(0) <= wire_data_header(7 downto 0);
            wire_next_header <= '1';
            next_frame_write_pos <= next_frame_write_pos + 1;
            next_data_o <= '1';
          end if;
        else
          wire_next_header <= '0';
          if (next_frame_write_pos < CCSDS_TX_FRAMER_HEADER_SIZE+CCSDS_TX_FRAMER_DATA_SIZE) then
            next_frame_ready <= '0';
            if (next_frame_write_pos = CCSDS_TX_FRAMER_HEADER_SIZE+CCSDS_TX_FRAMER_DATA_SIZE-1) then
              next_data_o <= '0';
            else
              next_data_o <= '1';
            end if;
            if (data_valid_i = '1') then
              next_frame(next_frame_write_pos)  <= data_i(7 downto 0);
              next_frame(next_frame_write_pos+1)  <= data_i(15 downto 8);
              next_frame(next_frame_write_pos+2)  <= data_i(23 downto 16);
              next_frame(next_frame_write_pos+3)  <= data_i(31 downto 24);
              next_frame_write_pos <= next_frame_write_pos + 1;
            end if;
          else
            next_data_o <= '0';
            if (next_frame_flushed = '0') then
              if (wire_data_valid_trailer = '1') then
                next_frame(next_frame_write_pos) <= wire_data_trailer(7 downto 0);
                next_frame(next_frame_write_pos+1) <= wire_data_trailer(15 downto 8);
                next_frame_ready <= '1';
              end if;
            else
              next_frame_write_pos <= 0;
              wire_rst_trailer <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
--    TRAILERCOMPUTEP
--  while frame next pointer increasing (diff from previous) and pointer inferieur à valeur position trailer
--> compute trailer data for next frame in real time
  
 -- FRAMERSTREAMP: process (clk_i)
 -- begin
    -- on each clock rising edge
 --   if rising_edge(clk_i) then
      -- reset signal received
  --    if (rst_i = '1') then
 --     data_o <= data_i;
 --     data_valid_o <= data_valid_i;
 --     clk_o <= clk_i;
 --   end if;
 -- end process;
--  if frame current ready
  --> copy data circularly + update pointer between reads
  
  FRAMECOPYP: process (clk_i)
--  if frame current finished to read and next frame ready to copy
  begin
    -- on each clock rising edge
    if rising_edge(clk_i) then
      -- reset signal received
      if (rst_i = '1') then
        next_frame_flushed <= '0';
        current_frame_ready <= '0';
      else
        if (next_frame_ready = '1') and (current_frame_transmitted = '1') then
          current_frame <= next_frame;
          next_frame_flushed <= '1';
          current_frame_ready <= '1';
        else
          next_frame_flushed <= '0';
          current_frame_ready <= '0';        
        end if;
      end if;
    end if;
  end process;
  
  --> FROM NEXT TO CURRENT AT GOOD TIME + CHANGE HEADER + RESET TAILER

--HEADER (+ 6 à + 70 octets) / avant data / indépendant

--TRAILER (+ 2 à + 6 octets) / après data / fonction des data


--TRANSFER FRAME PRIMARY HEADER => 6 octets
--[OPT] TRANSFER FRAME SECONDARY HEADER => up to 64 octets
--[OPT] SECURITY HEADER
--TRANSFER FRAME DATA FIELD => Variable
--[OPT] SECURITY TRAILER
--[OPT] TRANSFER FRAME TRAILER (2 to 6 octets)
  


--begin  
  -- FRAMER PROCESS
--  FRAMERP : process (clk_i)
--  variable test: integer := 0;
--  begin
--   data_valid_o <= data_valid_i;
--    data_o <= data_i;
--    clk_o <= clk_i;
--    next_data_o <= '1';
-- FOR TESTING PURPOSES ONLY
--    if rising_edge(clk_i) then
--      if (test < 150) then
--        test := test + 1;
--        next_data_o <= '1';
--      elsif (test > 200) then
--        next_data_o <= '1';
--      else
--        test := test + 1;
--        next_data_o <= '0';
--      end if;
--    end if;
--  end process;
end structure;
