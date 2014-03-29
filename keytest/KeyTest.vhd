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
         CLOCK_50      : in  std_logic
	);
end entity KeyTest;

architecture syn of KeyTest is
signal keys : std_logic_vector(15 downto 0);
signal deb_keys : std_logic_vector(15 downto 0);
signal old_keys : std_logic_vector(15 downto 0);
signal serial_data_in, serial_data_out : std_logic_vector(7 downto 0);
signal serial_cswr_n, serial_ready_n : std_logic;
signal LED_INTENSITY : PWMIntensities;
constant ZeroIntensity : PWMIntensity := 0;
begin
	scanner : entity work.KeyScanner(syn)
		port map (COL_IN => TACTL, ROW_OUT => TACTR, keystate => keys, clock => CLOCK_50);
	debouncer : entity work.KeyDebounce(syn)
		port map (keys, deb_keys, CLOCK_50);
	pwm: entity work.PWMLed(syn)
		port map (LED_INTENSITY, LED_GREEN, CLOCK_50);
	serial: entity work.SerialPort(syn)
		port map (serial_data_out, serial_data_in, serial_cswr_n, serial_ready_n, UART_TX, UART_RX, CLOCK_50);
	process(CLOCK_50)
	variable key : integer range 0 to 131071;
	begin
		if rising_edge(CLOCK_50) then
			serial_cswr_n <= serial_ready_n;
			if serial_ready_n = '0' then
				if serial_data_in = "00100000" then
					serial_data_out <= "00100001";
				else
					serial_data_out <= serial_data_in;
				end if;
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
	 	end if;
	end process;
end architecture syn;
