library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity T0Sampler_TB is
end T0Sampler_TB;

architecture T0Sampler_TB_ARCH of T0Sampler_TB is

-- Component Declaration
component T0Sampler is
    Port ( vpeClean : in STD_LOGIC;
           frameStartEn : out STD_LOGIC;
           wordStartEn : out STD_LOGIC;
           t0Samples: out integer;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC);
end component;

-- Constants
constant CLOCK_PERIOD : time := 10 ns;
constant ACTIVE : std_logic := '1';

-- Signals
signal tb_clock : std_logic := '0';
signal tb_reset : std_logic := '0';
signal tb_vpeClean : std_logic := '0';
signal tb_frameStartEn : std_logic;
signal tb_wordStartEn : std_logic;
signal tb_t0Samples : integer;

begin

-- Device Under Test
DUT: T0Sampler
    port map (
        clock => tb_clock,
        reset => tb_reset,
        vpeClean => tb_vpeClean,
        frameStartEn => tb_frameStartEn,
        wordStartEn => tb_wordStartEn,
        t0Samples => tb_t0Samples
    );

-- Clock Generation
clock_process: process
begin
    tb_clock <= '0';
    wait for CLOCK_PERIOD/2;
    tb_clock <= '1';
    wait for CLOCK_PERIOD/2;
end process;

-- Stimulus Process
stimulus: process
begin
    -- Print test start
    report "Starting T0Sampler Tests";
    
    -- Initial Reset
    tb_reset <= ACTIVE;
    wait for CLOCK_PERIOD * 2;
    tb_reset <= not ACTIVE;
    wait for CLOCK_PERIOD * 2;

    -- Test Case 1: WordStartEn High Test (within 12% buffer)
    report "Test Case 1: Testing wordStartEn HIGH condition";
    tb_vpeClean <= ACTIVE;
    wait for CLOCK_PERIOD * 10;  -- High for 10 cycles to set t0Samples
    tb_vpeClean <= not ACTIVE;
    wait for CLOCK_PERIOD * 10;  -- Low for exactly the same time (100% ratio)
    
    -- Verify wordStartEn
    assert tb_wordStartEn = ACTIVE 
        report "Test Case 1 Failed: wordStartEn should be HIGH"
        severity error;
    
    wait for CLOCK_PERIOD * 5;  -- Gap between tests

    -- Test Case 2: Different t0Samples for WordStartEn
    report "Test Case 2: Testing wordStartEn HIGH with different t0Samples";
    tb_vpeClean <= ACTIVE;
    wait for CLOCK_PERIOD * 200;  -- High for 20 cycles
    tb_vpeClean <= not ACTIVE;
    wait for CLOCK_PERIOD * 200;  -- Low for matching time
    
    -- Verify wordStartEn
    assert tb_wordStartEn = ACTIVE 
        report "Test Case 2 Failed: wordStartEn should be HIGH"
        severity error;
    
    wait for CLOCK_PERIOD * 5;  -- Gap between tests

    -- Test Case 3: FrameStartEn High Test
    report "Test Case 3: Testing frameStartEn HIGH condition";
    tb_vpeClean <= ACTIVE;
    wait for CLOCK_PERIOD * 150;  -- High for 15 cycles
    tb_vpeClean <= not ACTIVE;
    wait for CLOCK_PERIOD * 950;  -- Low for >6x the high time
    
    -- Verify frameStartEn
    assert tb_frameStartEn = ACTIVE 
        report "Test Case 3 Failed: frameStartEn should be HIGH"
        severity error;
    
    wait for CLOCK_PERIOD * 5;  -- Gap between tests

    -- Test Case 4: Alternative FrameStartEn Test
    report "Test Case 4: Testing frameStartEn HIGH with different timing";
    tb_vpeClean <= ACTIVE;
    wait for CLOCK_PERIOD * 100;  -- High for 10 cycles
    tb_vpeClean <= not ACTIVE;
    wait for CLOCK_PERIOD * 700;  -- Low for 7x the high time
    
    -- Verify frameStartEn
    assert tb_frameStartEn = ACTIVE 
        report "Test Case 4 Failed: frameStartEn should be HIGH"
        severity error;

    -- End simulation
    wait for CLOCK_PERIOD * 10;
    report "All tests completed";
    assert false report "Test Complete" severity failure;
    
end process;

-- Monitor Process to display signal changes
monitor: process(tb_clock)
begin
    if rising_edge(tb_clock) then
        if tb_wordStartEn = ACTIVE then
            report "WordStartEn activated at time " & time'image(now);
        end if;
        if tb_frameStartEn = ACTIVE then
            report "FrameStartEn activated at time " & time'image(now);
        end if;
        if tb_t0Samples'event then
            report "t0Samples changed to " & integer'image(tb_t0Samples) & " at time " & time'image(now);
        end if;
    end if;
end process;

end T0Sampler_TB_ARCH;