library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RxTop_tb is
end RxTop_tb;

architecture sim of RxTop_tb is
    component RxTop is
        port (
            vpeSerial: in std_logic;
            clock: in std_logic;
            reset: in std_logic;
            RxOut: out std_logic_vector(31 downto 0);
            NewWord: out std_logic;
            EndFlag: out std_logic
        );
    end component;

    signal vpeSerial_tb: std_logic := '0';
    signal clock_tb: std_logic := '0';
    signal reset_tb: std_logic := '0';
    signal RxOut_tb: std_logic_vector(31 downto 0);
    signal NewWord_tb: std_logic;
    signal EndFlag_tb: std_logic;

    constant clock_period : time := 10 ns;
    
    procedure send_vpe_pattern(
        signal vpe: out std_logic;
        pattern: in string) is
    begin
        for i in pattern'range loop
            if pattern(i) = '0' then
                vpe <= '0';
            else
                vpe <= '1';
            end if;
            wait for clock_period * 5; -- 100 clock cycles = 1us with 10ns period
        end loop;
    end procedure;

begin
    uut: RxTop port map (
        vpeSerial => vpeSerial_tb,
        clock => clock_tb,
        reset => reset_tb,
        RxOut => RxOut_tb,
        NewWord => NewWord_tb,
        EndFlag => EndFlag_tb
    );

    clock_process : process
    begin
        clock_tb <= '0';
        wait for clock_period/2;
        clock_tb <= '1';
        wait for clock_period/2;
    end process;

    stimulus_process : process
    begin
        -- Initialize
        reset_tb <= '1';
        wait for clock_period * 100;  -- 1us
        reset_tb <= '0';
        wait for clock_period * 100;  -- 1us

        -- Test patterns of different lengths
        send_vpe_pattern(vpeSerial_tb, "0000001");     -- FRAME_START
        send_vpe_pattern(vpeSerial_tb, "0011");      -- VPE-Pattern #3
        send_vpe_pattern(vpeSerial_tb, "01");       -- WORD_START
        send_vpe_pattern(vpeSerial_tb, "00111");    -- VPE-Pattern #5
         send_vpe_pattern(vpeSerial_tb, "0000000");    -- all zeros --turn off;
        
        
        
        wait;
    end process;

end sim;