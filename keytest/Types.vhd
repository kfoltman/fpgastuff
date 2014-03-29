library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Types is
	type PWMIntensity is range 0 to 255;
	type PWMIntensities is array (0 to 7) of PWMIntensity;
end package Types;

