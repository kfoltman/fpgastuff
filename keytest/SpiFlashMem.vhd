library IEEE;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.Types.all;

entity SpiFlashMem is
	port (
		MEMBUS_ADDRESS : in std_logic_vector(31 downto 0);
		MEMBUS_DATA_OUT : in std_logic_vector(7 downto 0);
		MEMBUS_DATA_IN : out std_logic_vector(7 downto 0);
		MEMBUS_CSRD_N : in std_logic;
		MEMBUS_MEMRDY : out std_logic;

		SPIFLASH_CS : out std_logic;
		SPIFLASH_MOSI : out std_logic;
		SPIFLASH_MISO : in std_logic;
		SPIFLASH_SCK : out std_logic;
		CLOCK: in std_logic
	);
end entity SpiFlashMem;

architecture syn of SpiFlashMem is
type SpiState is (Setup, Idle, SendCommand, SendAddress, WaitForData, ReceiveData, EndTransaction);
constant ReadCmd : std_logic_vector(7 downto 0) := "00010011";
signal state: SpiState := Setup;
signal counter: integer range 0 to 255 := 0;
signal address: std_logic_vector(31 downto 0) := x"00000000";
signal data: std_logic_vector(7 downto 0);
signal edge: std_logic;
begin
	process(CLOCK)
	begin
		if rising_edge(CLOCK) then
			MEMBUS_MEMRDY <= '0';
			if (state = Setup) or (state = Idle) or (state = EndTransaction) then
				SPIFLASH_CS <= '1';
			else
				SPIFLASH_CS <= '0';
			end if;
			SPIFLASH_SCK <= edge;
			case state is
				when Setup =>
					if counter < 255 then
						counter <= counter + 1;
					else
						state <= Idle;
					end if;
				when Idle =>
					if MEMBUS_CSRD_N = '0' then
						address(24 downto 0) <= MEMBUS_ADDRESS(24 downto 0);
						state <= SendCommand;
						counter <= 0;
						SPIFLASH_CS <= '0';
					end if;
				when SendCommand =>
					SPIFLASH_MOSI <= ReadCmd(7 - counter);
					if edge = '1' then
						if counter = 7 then
							state <= SendAddress;
							counter <= 0;
						else
							counter <= counter + 1;
						end if;
					end if;
				when SendAddress =>
					SPIFLASH_MOSI <= address(31 - counter);
					if edge = '1' then
						if counter = 31 then
							state <= WaitForData;
							counter <= 0;
						else
							counter <= counter + 1;
						end if;
					end if;
				when WaitForData =>
					state <= ReceiveData;
				when ReceiveData =>
					if edge = '1' then
						data(7 - counter) <= SPIFLASH_MISO;
						if counter = 7 then
							state <= EndTransaction;
							counter <= 0;
						else
							counter <= counter + 1;
						end if;
					end if;
				when EndTransaction =>
					MEMBUS_DATA_IN <= data;
					MEMBUS_MEMRDY <= '1';
					--state <= SendCommand;
					--address <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(address)), 32));
					state <= Idle;
					counter <= 0;
			end case;
			if state = Idle then
				edge <= '0';
			else
				edge <= not edge;
			end if;
		end if;
	end process;
end;
