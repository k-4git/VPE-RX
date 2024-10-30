library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity DataRegister_tb is
end entity;

architecture behavioral of DataRegister_tb is
    -- Component Declaration
    component DataRegister is
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            pushDataEn  : in std_logic;
            rxNibble    : in std_logic_vector(3 downto 0);
            nibbleReady : in std_logic;
            RxOut       : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Test Signals
    signal clock_tb       : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal pushDataEn_tb  : std_logic := '0';
    signal rxNibble_tb    : std_logic_vector(3 downto 0) := (others => '0');
    signal nibbleReady_tb : std_logic := '0';
    signal RxOut_tb       : std_logic_vector(31 downto 0);

    -- Clock period definition
    constant CLOCK_PERIOD : time := 10 ns;

begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: DataRegister
    port map (
        clock       => clock_tb,
        reset       => reset_tb,
        pushDataEn  => pushDataEn_tb,
        rxNibble    => rxNibble_tb,
        nibbleReady => nibbleReady_tb,
        RxOut       => RxOut_tb
    );

    -- Clock Process
    clock_process: process
    begin
        clock_tb <= '0';
        wait for CLOCK_PERIOD/2;
        clock_tb <= '1';
        wait for CLOCK_PERIOD/2;
    end process;

    -- Stimulus Process
    stimulus: process
    begin
        -- Initial Reset
        reset_tb <= '1';
        nibbleReady_tb <= '0';
        wait for CLOCK_PERIOD*2;
        reset_tb <= '0';
        wait for CLOCK_PERIOD;

        -- Test Case 1: Load 8 nibbles (32 bits)
        for i in 0 to 7 loop
            pushDataEn_tb <= '1';
            nibbleReady_tb <= '1';
            rxNibble_tb <= std_logic_vector(to_unsigned(i, 4));
            wait for CLOCK_PERIOD;
            nibbleReady_tb <= '0';
            pushDataEn_tb <= '0';
            wait for CLOCK_PERIOD;
        end loop;

        -- Wait to observe output
        wait for CLOCK_PERIOD*2;

        -- Test Case 2: Load another set of 8 nibbles with different values
        for i in 15 downto 8 loop
            pushDataEn_tb <= '1';
            nibbleReady_tb <= '1';
            rxNibble_tb <= std_logic_vector(to_unsigned(i mod 16, 4));
            wait for CLOCK_PERIOD;
            nibbleReady_tb <= '0';
            pushDataEn_tb <= '0';
            wait for CLOCK_PERIOD;
        end loop;

        -- Wait to observe output
        wait for CLOCK_PERIOD*2;

        -- Test Case 3: Test reset during data loading
        -- Load a few nibbles
        for i in 0 to 3 loop
            pushDataEn_tb <= '1';
            nibbleReady_tb <= '1';
            rxNibble_tb <= std_logic_vector(to_unsigned(i, 4));
            wait for CLOCK_PERIOD;
            nibbleReady_tb <= '0';
            pushDataEn_tb <= '0';
            wait for CLOCK_PERIOD;
        end loop;

        -- Assert reset
        reset_tb <= '1';
        wait for CLOCK_PERIOD*2;
        reset_tb <= '0';
        wait for CLOCK_PERIOD;

        -- Test Case 4: Test nibbleReady control
        -- Try loading with nibbleReady deasserted
        pushDataEn_tb <= '1';
        nibbleReady_tb <= '0';
        rxNibble_tb <= "1111";
        wait for CLOCK_PERIOD*2;

        -- Then assert nibbleReady to show data is only loaded when ready
        nibbleReady_tb <= '1';
        wait for CLOCK_PERIOD;
        nibbleReady_tb <= '0';
        pushDataEn_tb <= '0';
        wait for CLOCK_PERIOD*2;

        -- Wait for a while before ending simulation
        wait for CLOCK_PERIOD*10;
        
        -- End simulation
        assert false report "Simulation Completed" severity note;
        wait;
    end process;

end architecture;