library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxDecoder_tb is
end RxDecoder_tb;

architecture sim of RxDecoder_tb is
    component RxDecoder is
        Port ( 
            clock : in std_logic;
            reset : in std_logic;
            vpeClean : in std_logic;
            t0En : in std_logic;
            idleEn : out std_logic;
            rxOut : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Test bench signals
    signal clock_tb: std_logic := '0';
    signal reset_tb: std_logic := '0';
    signal vpeClean_tb: std_logic := '0';
    signal t0En_tb: std_logic := '0';
    signal idleEn_tb: std_logic;
    signal rxOut_tb: std_logic_vector(31 downto 0);

    constant clock_period : time := 10 ns;
    
    procedure send_pattern(
        signal vpe: out std_logic;
        signal t0: out std_logic;
        pattern: in string) is
    begin
        for i in pattern'range loop
            -- Set vpeClean
            if pattern(i) = '0' then
                vpe <= '0';
            else
                vpe <= '1';
            end if;
            
            -- Generate t0En pulse for each bit
            t0 <= '1';
            wait for clock_period * 5;  -- Extended from 2 to 5 clock cycles
            t0 <= '0';
            wait for clock_period * 95;  -- Adjusted to maintain 100 cycle period
        end loop;
    end procedure;

begin
    -- Unit Under Test
    uut: RxDecoder port map (
        clock => clock_tb,
        reset => reset_tb,
        vpeClean => vpeClean_tb,
        t0En => t0En_tb,
        idleEn => idleEn_tb,
        rxOut => rxOut_tb
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
        send_pattern(vpeClean_tb, t0En_tb, "0000001");     -- FRAME_START       
        send_pattern(vpeClean_tb, t0En_tb, "0011");        -- VPE-Pattern #3
        send_pattern(vpeClean_tb, t0En_tb, "01");          -- WORD_START       
        send_pattern(vpeClean_tb, t0En_tb, "00111");       -- VPE-Pattern #6
        send_pattern(vpeClean_tb, t0En_tb, "0000000");     -- all zeros
        
        send_pattern(vpeClean_tb, t0En_tb, "0000001");     -- FRAME_START 
        send_pattern(vpeClean_tb, t0En_tb, "0011111");     -- VPE-Pattern #15
        send_pattern(vpeClean_tb, t0En_tb, "01");          -- WORD_START  
        send_pattern(vpeClean_tb, t0En_tb, "011111");     -- VPE-Pattern #9
        send_pattern(vpeClean_tb, t0En_tb, "01");          -- WORD_START  
        send_pattern(vpeClean_tb, t0En_tb, "001111");     -- VPE-Pattern #10
        send_pattern(vpeClean_tb, t0En_tb, "01");          -- WORD_START 
        send_pattern(vpeClean_tb, t0En_tb, "000111");     -- VPE-Pattern #11
        send_pattern(vpeClean_tb, t0En_tb, "01");          -- WORD_START 
        send_pattern(vpeClean_tb, t0En_tb, "011");        -- VPE-PATTERN #0
        
             
        send_pattern(vpeClean_tb, t0En_tb, "0000001");     -- FRAME_START 
        send_pattern(vpeClean_tb, t0En_tb, "000001");        -- VPE-PATTERN #13
        send_pattern(vpeClean_tb, t0En_tb, "0000000");     -- all zeros
        send_pattern(vpeClean_tb, t0En_tb, "0");     -- all zeros
              
        wait for clock_period * 1000; -- Allow time to observe final state
        
        wait;
    end process;

end sim;