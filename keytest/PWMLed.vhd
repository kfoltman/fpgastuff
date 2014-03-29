library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use work.Types.all;

entity PWMLed is
	port (
		INTENSITY : in PWMIntensities;
		OUTPUT : out std_logic_vector(7 downto 0);
		CLOCK : in std_logic
	);
end entity PWMLed;

architecture syn of PWMLed is
signal cycle: integer range 0 to 254;
begin
	process(CLOCK)
	begin
		if rising_edge(CLOCK) then
			for i in 0 to 7 loop
				if integer(INTENSITY(i)) > cycle then
					OUTPUT(i) <= '1';
				else
					OUTPUT(i) <= '0';
				end if;
			end loop;
			if cycle = 254 then
				cycle <= 0;
			else
				cycle <= cycle + 1;
			end if;
		end if;
	end process;
end;
