library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PulseCounter_TB is
end PulseCounter_TB;

architecture behavioral of PulseCounter_TB is
    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;
    constant ACTIVE : std_logic := '1';
    constant T0_PERIOD : time := 1 ms;
    
    -- Component declaration
    component PulseCounter is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            vpeClean  : in  std_logic;
            t0En      : in  std_logic;
            lowCount  : out integer range 0 to 7;
            highCount : out integer range 0 to 7
        );
    end component;
    
    -- Signals
    signal clock     : std_logic := '0';
    signal reset     : std_logic := '0';
    signal vpeClean  : std_logic := '0';
    signal t0En      : std_logic := '0';
    signal lowCount  : integer range 0 to 7;
    signal highCount : integer range 0 to 7;
    signal sim_done  : boolean := false;
    signal t0        : std_logic := '0';

begin
    -- Unit Under Test
    UUT: PulseCounter port map (
        clock     => clock,
        reset     => reset,
        vpeClean  => vpeClean,
        t0En      => t0En,
        lowCount  => lowCount,
        highCount => highCount
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
    
    -- T0 and T0En generation
    t0_gen: process
    begin
        while not sim_done loop
            t0 <= '0';
            t0En <= '0';
            wait for T0_PERIOD/4;
            t0En <= '1';
            wait for T0_PERIOD/4;
            t0 <= '1';
            t0En <= '0';
            wait for T0_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initialize
        reset <= '1';
        wait for CLOCK_PERIOD;
        reset <= '0';
        wait for CLOCK_PERIOD;
        
        --vpe data '0000111'--
        vpeClean <= '0';
        wait for T0_PERIOD*4;
        
        vpeClean <= '1';
        wait for T0_PERIOD*3;
        
        --all zeros--
        vpeClean <= '0';
        wait for T0_PERIOD*6;
        
        vpeClean <= '1';
        wait for T0_PERIOD;
        
        -- End simulation
        wait for CLOCK_PERIOD * 20;
        sim_done <= true;
        wait;
    end process;

end architecture;