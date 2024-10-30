LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY T0Sampler_tb IS
END T0Sampler_tb;

ARCHITECTURE behavior OF T0Sampler_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT T0Sampler
    PORT(
         vpeClean : IN  std_logic;
         frameStartEn : OUT  std_logic;
         wordStartEn : OUT  std_logic;
         t0Samples : OUT integer;
         clock : IN  std_logic;
         reset : IN  std_logic
        );
    END COMPONENT;
    
    -- Clock and Reset signals
    SIGNAL clock : std_logic := '0';
    SIGNAL reset : std_logic := '0';
    
    -- Signals to drive the DUT (Design Under Test)
    SIGNAL vpeClean : std_logic := '0';
    SIGNAL frameStartEn : std_logic;
    SIGNAL wordStartEn : std_logic;
    SIGNAL t0Samples : integer;

    -- Clock period definitions
    CONSTANT clk_period : time := 10 ns; -- 100 MHz clock, period = 10ns

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: T0Sampler PORT MAP (
          vpeClean => vpeClean,
          frameStartEn => frameStartEn,
          wordStartEn => wordStartEn,
          t0Samples => t0Samples,
          clock => clock,
          reset => reset
        );

    -- Clock process definitions
    clock_process :process
    begin
        clock <= '0';
        wait for clk_period/2;
        clock <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin	

        -- Test Case 1: lowTime of 600ns, highTime of 100ns
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        
        -- Low time of 600ns
        vpeClean <= '0';
        wait for 600 ns;
        
        -- High time of 100ns
        vpeClean <= '1';
        wait for 100 ns;
        
        -- Test Case 2: lowTime of 900ns, highTime of 150ns
        vpeClean <= '0';
        wait for 900 ns;
        
        vpeClean <= '1';
        wait for 150 ns;

        -- Test Case 3: lowTime of 590ns, highTime of 100ns
        vpeClean <= '0';
        wait for 590 ns;
        
        vpeClean <= '1';
        wait for 100 ns;

        -- Stop simulation
        wait;
    end process;

END;
