library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KeyScanner is
	port (
			COL_IN		  : in    std_logic_vector(3 downto 0);
			ROW_OUT		  : out std_logic_vector(3 downto 0);			
         KEYSTATE     : buffer std_logic_vector(15 downto 0);
         CLOCK        : in  std_logic
	);
end entity KeyScanner;

architecture syn of KeyScanner is
signal phase, nextphase : integer range 0 to 3;
signal row, nextrow : integer range 0 to 3;
begin
   process(row, phase)
	begin
		-- next_row_out <= ( others => 'Z' );
		if phase = 3 then
			nextphase <= 0;
			if row = 3 then
				nextrow <= 0;
			else
				nextrow <= row + 1;
			end if;
		else
			nextphase <= phase + 1;
			nextrow <= row;
		end if;
	end process;

	process(CLOCK)
	begin
		if rising_edge(CLOCK) then
			for i in 0 to 3 loop
				case phase is
					when 0 =>
						if i = row then 
							row_out(i) <= '0';
						else
							row_out(i) <= 'Z';
						end if;
					when 1 =>
						if i = row then 
							row_out(i) <= '0';
							KEYSTATE(4 * i + 3 downto 4 * i) <= COL_IN xor "1111";
						else
							row_out(i) <= 'Z';
						end if;
					when 2 =>
						if i = row then 
							row_out(i) <= '1';
						else
							row_out(i) <= 'Z';
						end if;
					when 3 => 
						row_out(i) <= 'Z';
				end case;
			end loop;
			phase <= nextphase;
			row <= nextrow;
		end if;
	end process;
end architecture syn;