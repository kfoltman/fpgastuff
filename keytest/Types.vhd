library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Types is
	type PWMIntensity is range 0 to 255;
	type PWMIntensities is array (0 to 7) of PWMIntensity;

	function charToByte(charIn:character) return std_logic_vector;
	function rgbmul(baseval:in std_logic_vector(7 downto 0); scale:in integer) return std_logic_vector;

end package Types;

package body Types is
	function charToByte(charIn:character) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(character'pos(charIn),8));
	end function charToByte;

	function rgbmul(baseval:in std_logic_vector(7 downto 0); scale:in integer) return std_logic_vector is
	variable mulval : integer;
	begin
		mulval := to_integer(unsigned(baseval)) * scale / 256;
		return std_logic_vector(to_unsigned(mulval, 8));
	end;
end Types;
