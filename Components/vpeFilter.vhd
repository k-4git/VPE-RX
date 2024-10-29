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
use ieee.numeric_std.all;
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
signal vpeTemp: integer;
begin

    noiseFilter: process (clock, reset)
    variable vpeSixteen: integer := 0;
    variable vpeCap: integer := 0;
    begin
        if(reset = ACTIVE) then
            vpeClean <= not ACTIVE;
        elsif(rising_edge (clock)) then
            if(vpeSerial = ACTIVE) then
                if(vpeCap < 15) then
                    vpeSixteen := vpeSixteen + 1;
                end if;
            elsif(vpeSerial = not ACTIVE) then
                if(vpeSixteen > 0) then
                    vpeSixteen := vpeSixteen - 1;
                end if;
            end if;
            
            if(vpeSixteen >= 11) then
                vpeClean <= ACTIVE;
            else
                vpeClean <= not ACTIVE;
            end if;
            vpeTemp <= vpeSixteen;
        end if;
    end process;


end vpeFilter_ARCH;
