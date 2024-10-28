----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2024 03:31:23 PM
-- Design Name: 
-- Module Name: vpeFilter - vpeFilter_ARCH
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vpeFilter is
    Port ( vpeSerial : in STD_LOGIC;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           vpeClean : out STD_LOGIC);
end vpeFilter;

architecture vpeFilter_ARCH of vpeFilter is
constant ACTIVE: std_logic := '1';    
begin

    noiseFilter: process (clock, reset)
    variable filterHigh: integer range 0 to 11 := 0;
    variable filterLow: integer range 0 to 11 := 0;
    begin
        if(reset = ACTIVE) then
            vpeClean <= not ACTIVE;
        elsif(rising_edge (clock)) then
            if(vpeSerial = ACTIVE) then
                filterHigh := filterHigh + 1;
            else
                filterHigh := filterLow + 1;
            end if;
            
            if(filterHigh = 11) then
                vpeClean <= ACTIVE;
                
                filterHigh := 0;
                filterLow := 0;
            elsif(filterLow = 11) then
                vpeClean <= not ACTIVE;
                
                filterHigh := 0;
                filterLow := 0;
            end if;         
        end if;
    end process;


end vpeFilter_ARCH;
