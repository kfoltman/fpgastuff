library IEEE;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;

entity FakeMem is
	port (
		MEMBUS_ADDRESS : in std_logic_vector(31 downto 0);
		MEMBUS_DATA_OUT : in std_logic_vector(7 downto 0);
		MEMBUS_DATA_IN : out std_logic_vector(7 downto 0);
		MEMBUS_CSRD_N : in std_logic;
		MEMBUS_MEMRDY : out std_logic;
		
		CLOCK_50: in std_logic
	);
end entity FakeMem;

architecture syn of FakeMem is
begin
	process(CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			if MEMBUS_CSRD_N = '0' then
				MEMBUS_DATA_IN <= MEMBUS_ADDRESS(7 downto 0) xor MEMBUS_ADDRESS(15 downto 8);
				MEMBUS_MEMRDY <= '1';
			else
				MEMBUS_DATA_IN <= "00000000";
				MEMBUS_MEMRDY <= '0';
			end if;
		end if;
	end process;
end architecture syn;
