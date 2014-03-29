library IEEE;
library work;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_1164.all;
use work.Types.all;

entity DataMon is
	port (
		DATA_OUT : out std_logic_vector(7 downto 0);
		DATA_IN : in std_logic_vector(7 downto 0);
		DATA_CSWR_N : out std_logic;
		DATA_READY_N : in std_logic;
		UART_TX_EMPTY : in std_logic;
		
		MEMBUS_ADDRESS : out std_logic_vector(31 downto 0);
		MEMBUS_DATA_OUT : out std_logic_vector(7 downto 0);
		MEMBUS_DATA_IN : in std_logic_vector(7 downto 0);
		MEMBUS_CSRD_N : out std_logic;
		MEMBUS_MEMRDY : in std_logic;
		
		CLOCK : in std_logic
	);
end entity DataMon;

architecture syn of DataMon is
type Cmd is (CmdNone, CmdRead, CmdWrite);
type State is (Waiting, ReceivingData1, ReceivingData2, TransmittingData1, TransmittingData2, FetchingData1, FetchingData2);
type DataBuffer is array (0 to 19) of std_logic_vector(7 downto 0);
signal cur_cmd : Cmd := CmdNone;
signal cur_state : State := Waiting;
signal cmd_byte : integer range 0 to 19 := 0;
signal read_byte : integer range 0 to 256 := 0;
signal mem_address : std_logic_vector(31 downto 0);
signal mem_length : integer range 0 to 256;
signal mem_buffer : std_logic_vector(7 downto 0);
begin
	process(CLOCK)
	variable digit : std_logic_vector(3 downto 0);
	variable decval : integer range 0 to 255;
	variable databuf : DataBuffer;
	begin
		if rising_edge(CLOCK) then
			MEMBUS_DATA_OUT <= "00000000";
			MEMBUS_CSRD_N <= '1';
			DATA_CSWR_N <= '1';
			case cur_state is
				when FetchingData1 => 
					if read_byte < mem_length then
						cur_state <= FetchingData2;
						MEMBUS_ADDRESS <= mem_address;
						MEMBUS_CSRD_N <= '0';
					else
						cur_state <= TransmittingData1;
					end if;
				when FetchingData2 => 
					if MEMBUS_MEMRDY = '1' then
						mem_buffer <= MEMBUS_DATA_IN;
						cur_state <= TransmittingData1;
					else
						-- continue waiting
						cur_state <= FetchingData2;
					end if;
				when TransmittingData1 =>
					if cur_cmd = CmdRead and UART_TX_EMPTY = '1' then
						if read_byte = mem_length then
							DATA_OUT <= charToByte('!');
							DATA_CSWR_N <= '0';
							cur_state <= Waiting;
						else
							if to_integer(unsigned(mem_buffer(7 downto 4))) <= 9 then
								DATA_OUT <= x"3" & mem_buffer(7 downto 4);
							else
								DATA_OUT <= std_logic_vector(to_unsigned(55 + to_integer(unsigned(mem_buffer(7 downto 4))), 8));
							end if;
							DATA_CSWR_N <= '0';
							cur_state <= TransmittingData2;
						end if;
					end if;
				when TransmittingData2 => 
					if cur_cmd = CmdRead and UART_TX_EMPTY = '1' then
						if to_integer(unsigned(mem_buffer(3 downto 0))) <= 9 then
							DATA_OUT <= x"3" & mem_buffer(3 downto 0);
						else
							DATA_OUT <= std_logic_vector(to_unsigned(55 + to_integer(unsigned(mem_buffer(3 downto 0))), 8));
						end if;
						DATA_CSWR_N <= '0';
						read_byte <= read_byte + 1;
						mem_address <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(mem_address)), 32));
						cur_state <= FetchingData1;
					end if;
				when others =>
			end case;
			if DATA_READY_N = '0' then
				case cur_state is
					when Waiting => 
						case Character'Val(to_integer(unsigned(DATA_IN))) is
							when 'e' =>
								DATA_CSWR_N <= '0';
								DATA_OUT <= DATA_IN;
							when 'r' =>
								cur_cmd <= CmdRead;
								cur_state <= ReceivingData1;
								cmd_byte <= 0;
							when 'w' =>
								cur_cmd <= CmdWrite;
								cur_state <= ReceivingData1;
								cmd_byte <= 0;
							when others =>
								DATA_CSWR_N <= '0';
								DATA_OUT <= x"3F";
						end case;
					when ReceivingData1 =>
						case DATA_IN(7 downto 4) is
							when "0011" =>
								if to_integer(unsigned(DATA_IN(3 downto 0))) < 10 then
									digit := DATA_IN(3 downto 0);
									cur_state <= ReceivingData2;
								else									
									DATA_CSWR_N <= '0';
									DATA_OUT <= x"3F";
									cur_state <= Waiting;
								end if;
							when "0100" =>
							when "0110" =>
								decval := to_integer(unsigned(DATA_IN(3 downto 0)));
								if decval >= 1 and decval <= 6 then
									digit := std_logic_vector(to_unsigned(9 + decval, 4));
									cur_state <= ReceivingData2;
								else									
									DATA_CSWR_N <= '0';
									DATA_OUT <= x"3F";
									cur_state <= Waiting;
								end if;
							when others => 
								DATA_CSWR_N <= '0';
								DATA_OUT <= x"3F";
								cur_state <= Waiting;
						end case;
					when ReceivingData2 =>
						case DATA_IN(7 downto 4) is
							when "0011" =>
								if to_integer(unsigned(DATA_IN(3 downto 0))) < 10 then
									databuf(cmd_byte) := digit & DATA_IN(3 downto 0);
									cur_state <= ReceivingData1;
								else									
									DATA_CSWR_N <= '0';
									DATA_OUT <= x"3F";
									cur_state <= Waiting;
								end if;
							when "0100" =>
							when "0110" =>
								decval := to_integer(unsigned(DATA_IN(3 downto 0)));
								if decval >= 1 and decval <= 6 then
									databuf(cmd_byte) := digit & std_logic_vector(to_unsigned(9 + decval, 4));
									cur_state <= ReceivingData1;
								else									
									DATA_CSWR_N <= '0';
									DATA_OUT <= x"3F";
									cur_state <= Waiting;
								end if;
							when others => 
								DATA_CSWR_N <= '0';
								DATA_OUT <= x"3F";
								cur_state <= Waiting;
						end case;
						if cmd_byte < 19 then
							if cur_cmd = CmdRead and cmd_byte = 4 then
								mem_address <= databuf(0) & databuf(1) & databuf(2) & databuf(3);
								if databuf(4) = x"00" then
									mem_length <= 256;
								else
									mem_length <= to_integer(unsigned(databuf(4)));
								end if;
								read_byte <= 0;
								cur_state <= FetchingData1;
							end if;
							cmd_byte <= cmd_byte + 1;
						else
							DATA_CSWR_N <= '0';
							DATA_OUT <= x"3F";
							cur_state <= Waiting;							
						end if;
					when others =>
						DATA_CSWR_N <= '0';
						DATA_OUT <= x"3F";
						cur_state <= Waiting;							
				end case;
			end if;
		end if;
	end process;
end architecture syn;
