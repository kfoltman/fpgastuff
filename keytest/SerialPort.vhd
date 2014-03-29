library IEEE;
library work;
use work.Types.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;

entity SerialPort is
	port (
		DATA_IN : in std_logic_vector(7 downto 0);
		DATA_OUT : out std_logic_vector(7 downto 0);
		CSWR_N : in std_logic;
		DATA_READY_N : out std_logic;
		TX_EMPTY : out std_logic;
		TX : out std_logic;
		RX : in std_logic;
		CLOCK : in std_logic
	);
end entity SerialPort;

architecture syn of SerialPort is
signal serial_data : std_logic_vector(7 downto 0) := "01100001";
signal bit_ctr : integer range 0 to 10 := 10;
begin
	-- TX process
	process(CLOCK)
	constant speed_div : integer := 434;
	variable speed_ctr : integer range 0 to 511;
	begin
		if rising_edge(CLOCK) then
			if CSWR_N = '0' and bit_ctr = 10 then
				serial_data <= DATA_IN;
				bit_ctr <= 0;
				speed_ctr := 0;
			elsif speed_ctr < speed_div - 1 then
				speed_ctr := speed_ctr + 1;
			else
				speed_ctr := 0;
				if bit_ctr < 10 then
					bit_ctr <= bit_ctr + 1;
				else
					bit_ctr <= 10;
				end if;
			end if;
		end if;
	end process;
	
	process(bit_ctr, CSWR_N)
	begin
		if bit_ctr = 10 and CSWR_N = '1' then
			TX_EMPTY <= '1';
		else
			TX_EMPTY <= '0';
		end if;
	end process;
	
	with bit_ctr select TX <=
		'0' when 0,
		'1' when 9,
		'1' when 10,
		serial_data(bit_ctr - 1) when others;

	-- RX process
	process(CLOCK)
	constant speed_div : integer := 434;
	variable speed_ctr : integer range 0 to 511 := 0;
	variable bit_ctr : integer range 0 to 10 := 10;
	variable shiftreg : std_logic_vector(9 downto 0);
	begin
		if rising_edge(CLOCK) then
			DATA_READY_N <= '1';
			if bit_ctr = 10 then
				if RX = '0' then
					bit_ctr := 0;
				else
					bit_ctr := 10;
				end if;
				speed_ctr := 0;
			elsif speed_ctr = (speed_div / 2) then -- sample at mid-period
				shiftreg(bit_ctr) := RX;
				speed_ctr := speed_ctr + 1;
			elsif speed_ctr < speed_div - 1 then
				speed_ctr := speed_ctr + 1;
			else
				speed_ctr := 0;
				if bit_ctr = 9 then
					DATA_OUT <= shiftreg(8 downto 1);
					DATA_READY_N <= '0';
				end if;
				bit_ctr := bit_ctr + 1;
			end if;
		end if;
	end process;
	
end architecture syn;
