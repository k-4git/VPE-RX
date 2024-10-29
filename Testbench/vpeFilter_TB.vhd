----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/27/2024 04:30:00 PM
-- Design Name: 
-- Module Name: vpeFilter_TB - vpeFilter_TB_ARCH
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Testbench for vpeFilter module
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
 
    -- Define a type for the test vectors
    type vpeArray is array (0 to 4) of std_logic_vector(15 downto 0);
    -- Constants
    constant CLOCK_PERIOD: time := 10 ns;
    constant ACTIVE: std_logic := '1';
    -- Component Declaration for the Unit Under Test (UUT)
    component vpeFilter is
        Port(
            vpeSerial: in std_logic;
            clock: in std_logic;
            reset: in std_logic;
            vpeClean: out std_logic
        );
    end component;
    -- Signals to connect to UUT
    signal vpeSerial: std_logic := '0';
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal vpeClean: std_logic;
    -- Test vector array
    constant arrayTB : vpeArray := (
        "1111000011111111",                             
        "0000000000000000",                             
        "0101010111100000",                             
        "1111111100000000",                             
        "1111010111101111"
    );                            
 
begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: vpeFilter 
        port map (
            vpeSerial => vpeSerial,
            clock => clock,
            reset => reset,
            vpeClean => vpeClean
        );
    -- Clock Generation Process
    CLOCK_DRIVER: process
    begin
        -- Initialize Clock
        clock <= '0';
        wait for CLOCK_PERIOD / 2;
        -- Toggle Clock
        loop
            clock <= not clock;
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process CLOCK_DRIVER;
    -- Reset Generation Process
    RESET_DRIVER: process
    begin
        -- Initialize Reset
        reset <= '1';
        wait for 100 ns;  -- Hold reset for 100 ns
        reset <= '0';
        wait;
    end process RESET_DRIVER;     
    -- Signal Driving Process
    SIGNAL_DRIVER: process
        variable vpeSixteen: std_logic_vector(15 downto 0);
    begin
        -- Wait for Reset to De-assert
        wait until reset = '0';
        wait for CLOCK_PERIOD;  -- Ensure clock edge after reset
        -- Apply Test Vectors
        for i in 0 to arrayTB'length - 1 loop
            vpeSixteen := arrayTB(i);
            for j in 0 to 15 loop
                vpeSerial <= vpeSixteen(j);
                wait for CLOCK_PERIOD;  -- Wait for one clock cycle
            end loop;    
        end loop;
        -- Wait for some time to observe final behavior
        wait for 100 ns;
        -- Finish Simulation
        assert false report "Testbench completed successfully." severity failure;
    end process SIGNAL_DRIVER;
    -- Optional: Monitor Signals
    MONITOR: process
    begin
        wait on clock, reset, vpeSerial, vpeClean;
        report "Time: " & time'image(now) & 
               " | Reset: " & std_logic'image(reset) &
               " | vpeSerial: " & std_logic'image(vpeSerial) &
               " | vpeClean: " & std_logic'image(vpeClean);
    end process MONITOR;
 
end vpeFilter_TB_ARCH;