library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RxDecoder_tb is
end entity;

architecture test of RxDecoder_tb is
    -- Component declaration for Device Under Test (DUT)
    component RxDecoder is
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            dataReady   : in  std_logic;
            rxWord      : in  std_logic_vector(6 downto 0);    
            idleEn      : out std_logic;
            rxNibble    : out std_logic_vector(3 downto 0);  
            nibbleReady : out std_logic
        );
    end component;

    -- Test bench signals
    signal clock_tb       : std_logic := '0';
    signal reset_tb       : std_logic := '0';
    signal dataReady_tb   : std_logic := '0';
    signal rxWord_tb      : std_logic_vector(6 downto 0) := (others => '0');
    signal idleEn_tb      : std_logic;
    signal rxNibble_tb    : std_logic_vector(3 downto 0);
    signal nibbleReady_tb : std_logic;
    constant clock_period : time := 10 ns;

    -- Test vector definitions
    type test_vectors is record
        input  : std_logic_vector(6 downto 0);  -- 7-bit encoded input
        output : std_logic_vector(3 downto 0);  -- Expected 4-bit output
    end record;
    
    type test_array is array (natural range <>) of test_vectors;
    
    -- Test cases including valid and invalid inputs
    constant tests : test_array := (
        ("1111011", "0000"), ("1111001", "0001"), ("1110111", "0010"), ("1110011", "0011"),
        ("1110001", "0100"), ("1110111", "0101"), ("1100111", "0110"), ("1100011", "0111"),
        ("1100001", "1000"), ("1011111", "1001"), ("1001111", "1010"), ("1000111", "1011"),
        ("1000011", "1100"), ("1000001", "1101"), ("0111111", "1110"), ("0011111", "1111"),
        -- Invalid input patterns
        ("1010101", "XXXX"), ("0000000", "XXXX"), ("1111110", "XXXX"), ("0101010", "XXXX")
    );

begin
    -- Device Under Test instantiation
    UUT: RxDecoder port map (
        clock => clock_tb, 
        reset => reset_tb, 
        dataReady => dataReady_tb,
        rxWord => rxWord_tb, 
        idleEn => idleEn_tb, 
        rxNibble => rxNibble_tb,
        nibbleReady => nibbleReady_tb
    );

    -- Clock generation process
    clock_process: process
    begin
        clock_tb <= '0'; wait for clock_period/2;
        clock_tb <= '1'; wait for clock_period/2;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initial reset
        reset_tb <= '1';
        wait for clock_period;
        reset_tb <= '0';
        wait for clock_period;

        -- Test vector application
        for i in tests'range loop
            dataReady_tb <= '1';
            rxWord_tb <= tests(i).input;
            wait for clock_period;
            dataReady_tb <= '0';
            wait for clock_period*3;
        end loop;
        
        report "Simulation completed";
        wait;
    end process;

end architecture;