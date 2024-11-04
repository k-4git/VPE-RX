----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2024 02:43:37 PM
-- Design Name: 
-- Module Name: sevenSegmentController - sevenSegmentController_ARCH
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

entity sevenSegmentController is
    Port ( rxOut : in STD_LOGIC_VECTOR (15 downto 0);
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           modeSwitch: in std_logic;
           wordDigit1 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit2 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit3 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit0 : out STD_LOGIC_VECTOR (3 downto 0);
           newWord : in STD_LOGIC);
end sevenSegmentController;

architecture sevenSegmentController_ARCH of sevenSegmentController is
constant ACTIVE: std_logic := '1';

begin


    Display_Shift: process(clock, reset)
    variable localRxOut: std_logic_vector(15 downto 0);
    
    begin
        if(reset = ACTIVE) then
            wordDigit0 <= (others => '0');
            wordDigit1 <= (others => '0');
            wordDigit2 <= (others => '0');
            wordDigit3 <= (others => '0');
        elsif(rising_edge (clock)) then
            if(modeSwitch = ACTIVE) then
                localRxOut := rxOut;
                
                wordDigit3 <= localRxOut(15 downto 12);
                wordDigit2 <= localRxOut(11 downto 8);
                wordDigit1 <= localRxOut(7 downto 4);
                wordDigit0 <= localRxOut(3 downto 0);
             end if;
         end if;
    end process;

end sevenSegmentController_ARCH;
