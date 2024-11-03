library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxSampler_tb is
end RxSampler_tb;

architecture sim of RxSampler_tb is
    component RxSampler is
        Port ( 
            vpeSerial : in STD_LOGIC;
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            idleEn : in STD_LOGIC;
            newWord : out STD_LOGIC;
            endFrame : out STD_LOGIC;
            vpeClean: out STD_LOGIC;
            t0En : out STD_LOGIC
        );
    end component;

    -- Test bench signals
    signal vpeSerial_tb: std_logic := '0';
    signal clock_tb: std_logic := '0';
    signal reset_tb: std_logic := '0';
    signal idleEn_tb: std_logic := '0';
    signal newWord_tb: std_logic;
    signal endFrame_tb: std_logic;
    signal vpeClean_tb: std_logic;
    signal t0En_tb: std_logic;
    
    -- Pulse counter signal

    constant clock_period : time := 10 ns;
    
    procedure send_vpe_pattern(
        signal vpe: out std_logic;
        signal idle: out std_logic;
        pattern: in string) is
    begin
        idle <= '0';  -- Reset idle signal
        for i in pattern'range loop
            if pattern(i) = '0' then
                vpe <= '0';
            else
                vpe <= '1';
            end if;
            wait for clock_period * 100; -- 100 clock cycles = 1us with 10ns period
        end loop;
        -- Check if pattern is all zeros to set idleEn
        if pattern = "0000000" then
            idle <= '1';
        end if;
    end procedure;

begin
    -- Unit Under Test
    uut: RxSampler port map (
        vpeSerial => vpeSerial_tb,
        clock => clock_tb,
        reset => reset_tb,
        idleEn => idleEn_tb,
        newWord => newWord_tb,
        endFrame => endFrame_tb,
        vpeClean => vpeClean_tb,
        t0En => t0En_tb
    );

    -- Clock generation process
    clock_process : process
    begin
        clock_tb <= '0';
        wait for clock_period/2;
        clock_tb <= '1';
        wait for clock_period/2;
    end process;

    -- Stimulus process
    stimulus_process : process
    begin
        -- Initialize
        reset_tb <= '1';
        wait for clock_period * 100;  -- 1us
        reset_tb <= '0';
        wait for clock_period * 100;  -- 1us

        -- Test Pattern Sequence
        -- Each pattern will now trigger the t0Gen based on tGenMode
        send_vpe_pattern(vpeSerial_tb, idleEn_tb, "0000001");     -- FRAME_START       
        send_vpe_pattern(vpeSerial_tb, idleEn_tb, "0011");        -- VPE-Pattern #3
        send_vpe_pattern(vpeSerial_tb, idleEn_tb, "01");          -- WORD_START       
        send_vpe_pattern(vpeSerial_tb, idleEn_tb, "00111");       -- VPE-Pattern #7        "1100111"
        send_vpe_pattern(vpeSerial_tb, idleEn_tb, "0000000");     -- all zeros --turn off
        
       -- wait for clock_period * 5000; -- Allow time to observe final state
        
        wait;
    end process;

end sim;