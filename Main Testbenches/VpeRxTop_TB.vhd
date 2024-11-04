library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity VpeRxTop_tb is
end VpeRxTop_tb;

architecture sim of VpeRxTop_tb is
    component VpeRxTop is
        Port ( 
            vpeSerial : in STD_LOGIC;
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            rxOut : out STD_LOGIC_VECTOR(31 downto 0);
            newWord : out STD_LOGIC;
            endFrame : out STD_LOGIC
        );
    end component;

    -- Test bench signals
    signal vpeSerial_tb: std_logic := '0';
    signal clock_tb: std_logic := '0';
    signal reset_tb: std_logic := '0';
    signal rxOut_tb: std_logic_vector(31 downto 0);
    signal newWord_tb: std_logic;
    signal endFrame_tb: std_logic;

    constant clock_period : time := 10 ns;
    
    procedure send_vpe_pattern(
        signal vpe: out std_logic;
        pattern: in string;
        period_multiplier: in integer) is
    begin
        for i in pattern'range loop
            if pattern(i) = '0' then
                vpe <= '0';
            else
                vpe <= '1';
            end if;
            wait for clock_period * period_multiplier;
        end loop;
    end procedure;

begin
    -- Unit Under Test
    uut: VpeRxTop port map (
        vpeSerial => vpeSerial_tb,
        clock => clock_tb,
        reset => reset_tb,
        rxOut => rxOut_tb,
        newWord => newWord_tb,
        endFrame => endFrame_tb
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
        -- First frame
        send_vpe_pattern(vpeSerial_tb, "0000001", 100);     -- FRAME_START       
        send_vpe_pattern(vpeSerial_tb, "0011", 100);        -- VPE-Pattern #3
        send_vpe_pattern(vpeSerial_tb, "01", 100);          -- WORD_START       
        send_vpe_pattern(vpeSerial_tb, "00111", 100);       -- VPE-Pattern #6
       -- send_vpe_pattern(vpeSerial_tb, "0000000", 100);     -- all zeros
        
        -- Second frame
        send_vpe_pattern(vpeSerial_tb, "0000001", 500);     -- FRAME_START 
        send_vpe_pattern(vpeSerial_tb, "0011111", 500);     -- VPE-Pattern #15
        send_vpe_pattern(vpeSerial_tb, "01", 500);          -- WORD_START  
        send_vpe_pattern(vpeSerial_tb, "011111", 500);      -- VPE-Pattern #9
        send_vpe_pattern(vpeSerial_tb, "01", 500);          -- WORD_START  
        send_vpe_pattern(vpeSerial_tb, "001111", 500);      -- VPE-Pattern #10
        send_vpe_pattern(vpeSerial_tb, "01", 500);          -- WORD_START 
        send_vpe_pattern(vpeSerial_tb, "000111", 500);      -- VPE-Pattern #11
        send_vpe_pattern(vpeSerial_tb, "01", 500);          -- WORD_START 
        send_vpe_pattern(vpeSerial_tb, "011", 500);         -- VPE-PATTERN #0
        
        -- Third frame     
        send_vpe_pattern(vpeSerial_tb, "0000001", 50);     -- FRAME_START 
        send_vpe_pattern(vpeSerial_tb, "000001", 50);      -- VPE-PATTERN #13
        send_vpe_pattern(vpeSerial_tb, "0000000", 50);     -- all zeros
        send_vpe_pattern(vpeSerial_tb, "0", 50);           -- all zeros
              
        wait for clock_period * 1000; -- Allow time to observe final state
        reset_tb <= '1';
        wait;
    end process;
end sim;