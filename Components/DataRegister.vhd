library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity DataRegister is
    port (
        clock  : in std_logic;
        reset : in std_logic;
        pushDataEn: in std_logic;
        rxNibble : in std_logic_vector(3 downt 0);
        RxOut : out std_logic_vector(31 downto 0)
    );
end entity;

architecture  of behavioral DataRegister is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';

    --+++=========Signals========+++--
    signal rxOut_sig: std_logic_vector(31 downt 0); 
begin

    DATA_OUT: process (clock, reset)
    variable nibbleCnt: integer := 0;
    variable rxOut_var: std_logic_vector( 31 downto 0);
    begin
        if reset = ACTIVE then
            rxOut_sig <= (others => '0'); 
            nibbleCnt := 0;
        elsif rising_edge(clock) then
            --Output the data whenever the register is full.
            if nibblCnt = 8 then
                rxOut_sig <= rxOut_var;
                nibbleCnt = 0;  -- reset Counter

            else
                -- load the register with a nibble each time and keep track
                if nibbleReady = ACTIVE then
                    rxOut_var := rxOut_var(31 downto 4) & rxNibble;
                    nibbleCnt := nibbleCnt +1;

                end if;
            end if ;


        end if;
    end process;
    

end architecture;