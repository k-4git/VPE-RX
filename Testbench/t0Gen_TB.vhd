library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity t0GEN_TB is
end t0GEN_TB;

architecture behavioral of t0GEN_TB is
    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;
    constant ACTIVE : std_logic := '1';
    
    -- Component declaration
    component t0GEN is
        port (
            clock      : in std_logic;
            reset      : in std_logic;
            t0Samples  : in integer;
            t0GenEn    : in std_logic;
            t0En       : out std_logic
        );
    end component;
    
    -- Signals
    signal clock      : std_logic := '0';
    signal reset      : std_logic := '0';
    signal t0Samples  : integer := 0;
    signal t0GenEn    : std_logic := '0';
    signal t0En       : std_logic;
    
    signal sim_done   : boolean := false;

begin
 
    UUT: t0GEN port map (
        clock     => clock,
        reset     => reset,
        t0Samples => t0Samples,
        t0GenEn   => t0GenEn,
        t0En      => t0En
    );
    
    -- Clock generation
    clock_gen: process
    begin
        while not sim_done loop
            clock <= '0';
            wait for CLOCK_PERIOD/2;
            clock <= '1';
            wait for CLOCK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus process
    stimulus: process
    begin
        -- Initialize signals
        reset <= '1';
        t0GenEn <= '0';
        t0Samples <= 16;  -- Test with 10 samples
        wait for CLOCK_PERIOD * 2;
        
        -- Release reset
        reset <= '0';
        wait for CLOCK_PERIOD * 2;
        
        -- Enable t0Gen
        t0GenEn <= '1';
        wait for CLOCK_PERIOD * 50;  -- Wait for multiple cycles
        
        -- Test with different sample values
        t0Samples <= 20;
        wait for CLOCK_PERIOD * 50;
        
        t0Samples <= 5;
        wait for CLOCK_PERIOD * 50;
        
        -- Disable t0Gen
        t0GenEn <= '0';
        wait for CLOCK_PERIOD * 10;
        
        -- Test enable/disable sequence
        t0GenEn <= '1';
        wait for CLOCK_PERIOD * 20;
        t0GenEn <= '0';
        wait for CLOCK_PERIOD * 10;
        
        -- End simulation
        sim_done <= true;
        wait for CLOCK_PERIOD * 2;
        
        report "Simulation completed successfully";
        wait;
    end process;

end architecture;