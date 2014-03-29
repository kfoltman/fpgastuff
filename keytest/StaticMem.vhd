library IEEE;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;

entity StaticMem is
	port (
		MEMBUS_ADDRESS : in std_logic_vector(31 downto 0);
		MEMBUS_DATA_OUT : in std_logic_vector(7 downto 0);
		MEMBUS_DATA_IN : out std_logic_vector(7 downto 0);
		MEMBUS_CSRD_N : in std_logic;
		MEMBUS_CSWR_N : in std_logic;
		MEMBUS_MEMRDY : out std_logic;
		
		CLOCK_50: in std_logic
	);
end entity StaticMem;

architecture syn of StaticMem is
type MemoryBlock is array(0 to 1023) of std_logic_vector(7 downto 0);
begin
	process(CLOCK_50)
	variable memory: MemoryBlock;
	begin
		if rising_edge(CLOCK_50) then
			if MEMBUS_CSRD_N = '0' then
				MEMBUS_DATA_IN <= memory(to_integer(unsigned(MEMBUS_ADDRESS(9 downto 0))));
				MEMBUS_MEMRDY <= '1';
			elsif MEMBUS_CSWR_N = '0' then
				memory(to_integer(unsigned(MEMBUS_ADDRESS(9 downto 0)))) := MEMBUS_DATA_OUT;
				MEMBUS_MEMRDY <= '1';
			else
				MEMBUS_DATA_IN <= "00000000";
				MEMBUS_MEMRDY <= '0';
			end if;
		end if;
	end process;
end architecture syn;
