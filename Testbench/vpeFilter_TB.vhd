----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2024 03:57:19 PM
-- Design Name: 
-- Module Name: vpeFilter_TB - vpeFilter_TB_ARCH
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

entity vpeFilter_TB is
--  Port ( );
end vpeFilter_TB;

architecture vpeFilter_TB_ARCH of vpeFilter_TB is

type vpeArray is array (0 to 4) of std_logic_vector(15 downto 0);
constant CLOCK_PERIOD: time := 10 ns;
constant ACTIVE: std_logic := '1';
component vpeFilter is
    Port(
        vpeSerial: in std_logic;
        
        clock: in std_logic;
        reset: in std_logic;
        
        vpeClean: out std_logic);
end component;
signal vpeSerial: std_logic;
signal clock: std_logic;
signal reset: std_logic;
signal vpeClean: std_logic;

begin
    UUT: vpeFilter port map (
        vpeSerial => vpeSerial,
        clock => clock,
        reset => reset,
        vpeClean => vpeClean);
    
    CLOCK_DRIVER: process
    begin
        clock <= not ACTIVE;
        wait for CLOCK_PERIOD;
        clock <= ACTIVE;
        wait for CLOCK_PERIOD;
    end process;
    
    RESET_DRIVER: process
    begin
        reset <= not ACTIVE;
        wait for 500* CLOCK_PERIOD;
        reset <= ACTIVE;
        wait for CLOCK_PERIOD;
        reset <= not ACTIVE;
    end process;     
    
    SIGNAL_DRIVER: process
    variable vpeSixteen: std_logic_vector(15 downto 0);
    variable arrayTB : vpeArray :=
       ("1111000011111111",                             
        "0000000000000000",                             
        "0101010111100000",                             
        "1111111100000000",                             
        "1111010111101111");                            
    begin
        for i in 0 to 4 loop
            vpeSixteen := arrayTB(i);
            for j in 0 to 15 loop
                vpeClean <= vpeSixteen(j);
                wait for 10*CLOCK_PERIOD;
            end loop;    
        end loop;    
    end process;
    
end vpeFilter_TB_ARCH;
