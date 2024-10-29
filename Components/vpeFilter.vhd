----------------------------------------------------------------------------------

-- 
-- Create Date: 10/27/2024 03:31:23 PM
-- Design Name: vpeFilter - 16-bit long BUFFER
-- Module Name: vpeFilter - vpeFilter_ARCH
-- Project Name: RxComponents
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
use ieee.numeric_std.all;

entity vpeFilter is
    Port ( vpeSerial : in STD_LOGIC;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           vpeClean : out STD_LOGIC);
end vpeFilter;

architecture vpeFilter_ARCH of vpeFilter is
--CONSTANTS
constant ACTIVE: std_logic := '1';
--INTERNAL SIGNALS FOR DISPLAY
signal vpeTemp: integer;
signal vpeWord: std_logic_vector(15 downto 0);
signal vpeBit: integer;
begin

    noiseFilter: process (clock, reset)
    --VARIABLES
    
    variable vpeSixteen: std_logic_vector(15 downto 0);
    variable vpeBalance: integer range 0 to 15 := 0;
    variable shiftBit: integer range 0 to 1;
    begin
        if(reset = ACTIVE) then
            vpeClean <= not ACTIVE;
            vpeSixteen := (others => '0');
        elsif(rising_edge (clock)) then
            --Determines if leftmost bit is 1 or 0 and stores it
            --in shiftBit
            if(vpeSixteen(15) = ACTIVE) then                                            
                shiftBit := 1;                                                          
            else
                shiftBit := 0;
            end if;
            
            --Subtracts the Leftmost bit out from the Counter
            --Shifts vpeSerial into the Rightmost bit
            vpeBalance := vpeBalance - shiftBit;                                        
            vpeSixteen := vpeSixteen(14 downto 0) & vpeSerial;                         
            
            --If vpeSerial is Active, add to Counter
            if(vpeSerial = ACTIVE) then                                                 
                vpeBalance := vpeBalance + 1;
            end if;
            
            --DISPLAY INTERNAL SIGNALS
            vpeTemp <= vpeBalance; 
            vpeWord <= vpeSixteen;
            vpeBit <= shiftBit;  
            
            --If Counter is 3/4 of total length of buffer, Output HIGH
            if(vpeBalance > 11) then                                                    
                vpeClean <= ACTIVE;
            else
                vpeClean <= not ACTIVE;
            end if;
        end if;
    end process;


end vpeFilter_ARCH;
