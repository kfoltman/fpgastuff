library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KeyDebounce is
	port (
		KEYSTATE: in std_logic_vector(15 downto 0);
		DEBOUNCED: buffer std_logic_vector(15 downto 0);
		CLOCK: in std_logic
	);
end entity KeyDebounce;

architecture syn of KeyDebounce is
type timers is array (0 to 15) of integer range 0 to 65535;
begin
	process(CLOCK)
	variable keynum : integer range 0 to 15;
	variable keytimers : timers;
	variable oldstate : std_logic_vector(15 downto 0);
	begin
		if rising_edge(CLOCK) then
			if KEYSTATE(keynum) = oldstate(keynum) then
				if keytimers(keynum) = 65535 then
					keytimers(keynum) := 0;
					DEBOUNCED(keynum) <= oldstate(keynum);
				else
					keytimers(keynum) := keytimers(keynum) + 1;
				end if;
			else
				keytimers(keynum) := 0;
				oldstate(keynum) := KEYSTATE(keynum);
			end if;
			if keynum = 15 then
				keynum := 0;
			else
				keynum := keynum + 1;
			end if;
		end if;
	end process;
end architecture syn;
