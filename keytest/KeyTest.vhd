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
			SPIFLASH_MOSI : inout std_logic;
			SPIFLASH_MISO : in std_logic;
			SPIFLASH_SCK : out std_logic;
			SPIFLASH_WPIO2 : in std_logic;
			SPIFLASH_HOLDIO3 : in std_logic;

			WS2812B_OUT	  	: out std_logic;
			
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
signal membus_data_in, membus_data_in_fakemem, membus_data_in_flash, membus_data_in_sram : std_logic_vector(7 downto 0);
signal membus_data_out : std_logic_vector(7 downto 0);
signal membus_csrd_n, membus_csrd_n_fakemem, membus_csrd_n_flash, membus_csrd_n_sram : std_logic;
signal membus_cswr_n, membus_cswr_n_sram : std_logic;
signal membus_memrdy, membus_memrdy_fakemem, membus_memrdy_flash, membus_memrdy_sram : std_logic;

signal cur_diode: std_logic_vector(2 downto 0);
signal cycle_end: std_logic_vector(2 downto 0);
signal RGB_R, RGB_G, RGB_B : std_logic_vector(7 downto 0);
signal RGB_R_BASE, RGB_G_BASE, RGB_B_BASE : std_logic_vector(7 downto 0);
signal rgbcycleend : std_logic;
signal rgbprescaler : integer range 0 to 499999;
signal rgbscaler : integer range 0 to 511;

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
		port map (serial_data_out, serial_data_in, serial_cswr_n, serial_ready_n, serial_tx_empty, membus_address, membus_data_out, membus_data_in, membus_csrd_n, membus_cswr_n, membus_memrdy, CLOCK_50);
	fakemem: entity work.FakeMem(syn)
		port map (membus_address, membus_data_out, membus_data_in_fakemem, membus_csrd_n_fakemem, membus_memrdy_fakemem, CLOCK_50);
	sram: entity work.StaticMem(syn)
		port map (membus_address, membus_data_out, membus_data_in_sram, membus_csrd_n_sram, membus_cswr_n_sram, membus_memrdy_sram, CLOCK_50);
	flashmem: entity work.SpiFlashMem(syn)
		port map (membus_address, membus_data_out, membus_data_in_flash, membus_csrd_n_flash, membus_memrdy_flash, SPIFLASH_CS, SPIFLASH_MOSI, SPIFLASH_MISO, SPIFLASH_WPIO2, SPIFLASH_HOLDIO3, SPIFLASH_SCK, CLOCK_50);
	ledctrl: entity work.WS2812B(syn)
		port map (RGB_R, RGB_G, RGB_B, WS2812B_OUT, cur_diode, rgbcycleend, CLOCK_50);
	
	-- CS/ for various kinds of memories
	with membus_address(31 downto 24) select membus_csrd_n_fakemem <= 
		membus_csrd_n when "00000011",
		'1' when others;
	
	with membus_address(31 downto 24) select membus_csrd_n_flash <= 
		membus_csrd_n when "00000000",
		membus_csrd_n when "00000001",
		'1' when others;
	
	with membus_address(31 downto 24) select membus_csrd_n_sram <= 
		membus_csrd_n when "00000100",
		'1' when others;
	
	with membus_address(31 downto 24) select membus_cswr_n_sram <= 
		membus_cswr_n when "00000100",
		'1' when others;
	
	-- MEMRDY multiplexing
	with membus_address(31 downto 24) select membus_memrdy <= 
		-- 32MB SPI flashmemory at 00xxxxxx/01xxxxxx
		membus_memrdy_flash when "00000000",
		membus_memrdy_flash when "00000001",
		-- 16MB fake memory at 03xxxxxx
		membus_memrdy_fakemem when "00000011",
		-- 1KB SRAM at 04xxxxxx
		membus_memrdy_sram when "00000100",
		'1' when others;

	with cur_diode select RGB_R_BASE <=
		"11000000" when "000",
		"11000000" when "001",
		"11000000" when "010",
		"00000000" when "011",
		"00000000" when "100",
		"00000000" when others;
		
	with cur_diode select RGB_G_BASE <=
		"00000000" when "000",
		"01100000" when "001",
		"11000000" when "010",
		"11000000" when "011",
		"00000000" when "100",
		"00000000" when others;
		
	with cur_diode select RGB_B_BASE <=
		"00000000" when "000",
		"00000000" when "001",
		"00000000" when "010",
		"00000000" when "011",
		"11000000" when "100",
		"00000000" when others;
		
	-- data bus multiplexing
	with membus_address(31 downto 24) select membus_data_in <= 
		-- 32MB SPI flash at 00xxxxxx		
		membus_data_in_flash when "00000000",
		membus_data_in_flash when "00000001",
		-- another 16MB block reserved for keypad press status
		("0000000" & deb_keys(to_integer(unsigned(membus_address(3 downto 0))))) when "00000010",
		-- 16MB fake memory at 03xxxxxx
		membus_data_in_fakemem when "00000011",
		-- 1KB SRAM at 04xxxxxx
		membus_data_in_sram when "00000100",
		"10101010" when others;
	
	process(CLOCK_50)
	variable key : integer range 0 to 131071;
	variable rgbscaler2 : integer range 0 to 255;
	begin
		if rising_edge(CLOCK_50) then
			if rgbcycleend = '1' then
				if rgbprescaler < 19 then
					rgbprescaler <= rgbprescaler + 1;
				else
					rgbprescaler <= 0;
					if rgbscaler < 511 then
						rgbscaler <= rgbscaler + 1;
					else
						rgbscaler <= 0;
					end if;
				end if;
			end if;
			if membus_cswr_n = '0' and membus_address(31 downto 24) = "00000010" then
				LED_INTENSITY(to_integer(unsigned(membus_address(2 downto 0)))) <= PWMIntensity(to_integer(unsigned(membus_data_out)));
			end if;
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
			if rgbscaler < 256 then
				rgbscaler2 := rgbscaler;
			else
				rgbscaler2 := (511 - rgbscaler);
			end if;
			rgbscaler2 := rgbscaler2 * rgbscaler2 / 256;
			RGB_R <= work.Types.rgbmul(RGB_R_BASE, rgbscaler2);
			RGB_G <= work.Types.rgbmul(RGB_G_BASE, rgbscaler2);
			RGB_B <= work.Types.rgbmul(RGB_B_BASE, rgbscaler2);
	 	end if;
	end process;
end architecture syn;
