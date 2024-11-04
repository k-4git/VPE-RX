----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2024 03:11:16 PM
-- Design Name: 
-- Module Name: Debouncer_Toggle - Debouncer_Toggle_ARCH
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

entity Debouncer_Toggle is
    Port ( 
        modeChange: in std_logic;
        clock: in std_logic;
        reset: in std_logic;
        
        modeSwitch: out std_logic);
end Debouncer_Toggle;

architecture Debouncer_Toggle_ARCH of Debouncer_Toggle is

constant ACTIVE: std_logic:= '1';    
begin
        TOGGLE: process(clock, reset)
        variable tempSwitch: std_logic:= not ACTIVE;
        begin
            if(reset = ACTIVE) then
                tempSwitch := not ACTIVE;
            elsif(rising_edge (clock)) then
                if(modeChange = ACTIVE) then
                    tempSwitch := not tempSwitch;
                end if;
                
            end if;
            modeSwitch <= tempSwitch;            
        end process;
end Debouncer_Toggle_ARCH;
