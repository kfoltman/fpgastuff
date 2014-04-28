library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity WS2812B is
	generic (
		diodecount : natural := 5
	);
	port (
		R, G, B : in std_logic_vector(7 downto 0);
		DATA_OUT : out std_logic;
		CUR_DIODE : out integer range 0 to diodecount - 1;
		CYCLE_END : out std_logic;
		FORCE_RESET : in std_logic;
		CLOCK : in std_logic
	);
end entity WS2812B;

architecture syn of WS2812B is
begin
	process(CLOCK)
	constant prescaler_value : integer := 62;
	variable bitidx : integer range 0 to 7 := 0;
	variable diodeidx : integer range 0 to diodecount - 1 := 0;
	variable compidx : integer range 0 to 2 := 0;
	variable databit : std_logic := '0';
	variable prescaler : integer range 0 to prescaler_value - 1 := 0;
	variable waitval : integer range 0 to 2500 := 0;
	begin
		if rising_edge(CLOCK) then
			cycle_end <= '0';
			if waitval > 0 then
				waitval := waitval - 1;
				DATA_OUT <= '0';
			else
				case compidx is
					when 0 => databit := G(7 - bitidx);
					when 1 => databit := R(7 - bitidx);
					when 2 => databit := B(7 - bitidx);
				end case;
				if prescaler < 17 then -- 0..0.34us (T0H)
					DATA_OUT <= '1';
					prescaler := prescaler + 1;
				elsif prescaler < 42 then -- 0.34..0.9us (T1H)
					DATA_OUT <= databit;
					prescaler := prescaler + 1;
				elsif prescaler < prescaler_value - 1 then -- 0.9..1.24us (T0H+T0L or T1H+T1L)
					DATA_OUT <= '0';
					prescaler := prescaler + 1;
				else
					DATA_OUT <= '0';
					if bitidx = 7 then
						bitidx := 0;
						if compidx = 2 then
							compidx := 0;
							if diodeidx < diodecount - 1 and FORCE_RESET = '0' then
								diodeidx := diodeidx + 1;
							else
								diodeidx := 0;
								waitval := 2500;
								cycle_end <= '1';
							end if;
						else
							compidx := compidx + 1;
						end if;
					else
						bitidx := bitidx + 1;
					end if;
					prescaler := 0;
				end if;
			end if;
			CUR_DIODE <= diodeidx;
		end if;
	end process;
end architecture syn;
