library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Types.all;

entity KeyTest is
	port (
			TACTL			  : in    std_logic_vector(3 downto 0);
			TACTR			  : buffer std_logic_vector(3 downto 0);			
         LED_GREEN     : buffer std_logic_vector(7 downto 0);
			UART_RX       : in std_logic;
			UART_TX       : out std_logic;

			SPIFLASH_CS : out std_logic;
			SPIFLASH_MOSI : out std_logic;
			SPIFLASH_MISO : in std_logic;
			SPIFLASH_SCK : out std_logic;

         CLOCK_50      : in  std_logic
	);
end entity KeyTest;

architecture syn of KeyTest is
signal keys : std_logic_vector(15 downto 0);
signal deb_keys : std_logic_vector(15 downto 0);
signal old_keys : std_logic_vector(15 downto 0);
signal serial_data_in, serial_data_out : std_logic_vector(7 downto 0);
signal serial_cswr_n, serial_ready_n, serial_tx_empty : std_logic;
signal LED_INTENSITY : PWMIntensities;

signal membus_address : std_logic_vector(31 downto 0);
signal membus_data_in, membus_data_in_fakemem, membus_data_in_flash : std_logic_vector(7 downto 0);
signal membus_data_out : std_logic_vector(7 downto 0);
signal membus_csrd_n, membus_csrd_n_fakemem, membus_csrd_n_flash : std_logic;
signal membus_memrdy, membus_memrdy_fakemem, membus_memrdy_flash : std_logic;


constant ZeroIntensity : PWMIntensity := 0;
begin
	scanner : entity work.KeyScanner(syn)
		port map (COL_IN => TACTL, ROW_OUT => TACTR, keystate => keys, clock => CLOCK_50);
	debouncer : entity work.KeyDebounce(syn)
		port map (keys, deb_keys, CLOCK_50);
	pwm: entity work.PWMLed(syn)
		port map (LED_INTENSITY, LED_GREEN, CLOCK_50);
	serial: entity work.SerialPort(syn)
		port map (serial_data_out, serial_data_in, serial_cswr_n, serial_ready_n, serial_tx_empty, UART_TX, UART_RX, CLOCK_50);
	sermon: entity work.DataMon(syn)
		port map (serial_data_out, serial_data_in, serial_cswr_n, serial_ready_n, serial_tx_empty, membus_address, membus_data_out, membus_data_in, membus_csrd_n, membus_memrdy, CLOCK_50);
	fakemem: entity work.FakeMem(syn)
		port map (membus_address, membus_data_out, membus_data_in_fakemem, membus_csrd_n_fakemem, membus_memrdy_fakemem, CLOCK_50);
	flashmem: entity work.SpiFlashMem(syn)
		port map (membus_address, membus_data_out, membus_data_in_flash, membus_csrd_n_flash, membus_memrdy_flash, SPIFLASH_CS, SPIFLASH_MOSI,SPIFLASH_MISO, SPIFLASH_SCK, CLOCK_50);
	
	-- CS/ for various kinds of memories
	with membus_address(31 downto 24) select membus_csrd_n_fakemem <= 
		membus_csrd_n when "00000011",
		'1' when others;
	
	with membus_address(31 downto 24) select membus_csrd_n_flash <= 
		membus_csrd_n when "00000000",
		membus_csrd_n when "00000001",
		'1' when others;
	
	-- MEMRDY multiplexing
	with membus_address(31 downto 24) select membus_memrdy <= 
		-- 32MB SPI flashmemory at 00xxxxxx/01xxxxxx
		membus_memrdy_flash when "00000000",
		membus_memrdy_flash when "00000001",
		-- 16MB fake memory at 03xxxxxx
		membus_memrdy_fakemem when "00000011",
		'1' when others;

	-- data bus multiplexing
	with membus_address(31 downto 24) select membus_data_in <= 
		-- 32MB SPI flash at 00xxxxxx		
		membus_data_in_flash when "00000000",
		membus_data_in_flash when "00000001",
		-- another 16MB block reserved for keypad press status
		("0000000" & deb_keys(to_integer(unsigned(membus_address(3 downto 0))))) when "00000010",
		-- 16MB fake memory at 03xxxxxx
		membus_data_in_fakemem when "00000011",
		"10101010" when others;
	
	process(CLOCK_50)
	variable key : integer range 0 to 131071;
	begin
		if rising_edge(CLOCK_50) then
			if key < 8 then
				if deb_keys(key) = '1' and old_keys(key) = '0' then
					LED_INTENSITY(key) <= 255;
				elsif PWMIntensity(LED_INTENSITY(key)) > ZeroIntensity then
					LED_INTENSITY(key) <= LED_INTENSITY(key) - 1;
				else
					LED_INTENSITY(key) <= 0;
				end if;
				old_keys(key) <= deb_keys(key);
			end if;
			if key = 131071 then
				key := 0;
			else
				key := key + 1;
			end if;
	 	end if;
	end process;
end architecture syn;
