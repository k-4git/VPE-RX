library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity DataRegister is
    port (
        clock       : in std_logic;
        reset      : in std_logic;
        pushDataEn : in std_logic;
        rxNibble   : in std_logic_vector(3 downto 0);
        nibbleReady: in std_logic;         -- Indicates valid nibble for processing
        RxOut      : out std_logic_vector(31 downto 0)
    );
end entity;

architecture behavioral of DataRegister is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';

    --+++=========Signals========+++--
    -- Holds completed 32-bit word for output
    signal rxOut_sig: std_logic_vector(31 downto 0); 
begin

    DATA_OUT: process (clock, reset)
    -- Tracks received nibbles (0-8)
    variable nibbleCnt: integer := 0;
    -- Builds 32-bit word as nibbles arrive
    variable rxOut_var: std_logic_vector(31 downto 0);
    begin
        if reset = ACTIVE then
            nibbleCnt := 0;
            rxOut_var := (others => '0');
            rxOut_sig <= (others => '0'); 
            
        elsif rising_edge(clock) then
            if nibbleCnt = 8 then
                rxOut_sig <= rxOut_var;
                nibbleCnt := 0;  
                rxOut_var := (others => '0');  
            else
                if nibbleReady = ACTIVE then
                    -- Build word from right to left, MSB will be first nibble received
                    rxOut_var := rxOut_var(27 downto 0) & rxNibble;
                    nibbleCnt := nibbleCnt + 1;
                end if;
            end if;
        end if;
        RxOut <= rxOut_sig;
    end process;
    
end architecture;