library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity t0GEN is
    port (
        clock      : in std_logic;
        reset      : in std_logic;
        t0Samples  : in integer;
        t0GenEn    : in std_logic;
        t0En       : out std_logic
    );
end entity t0GEN;

architecture behavioral of t0GEN is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';
    
    --+++=========Signals========+++--
    signal sampleCount : integer := 0;
    signal genPulse : std_logic := '0';
    
    --+++=========Functions========+++--

begin
    t0GENERATE: process (clock, reset)
    variable genCounter : integer := 0;
    begin
        if reset = ACTIVE then
            genCounter := 0;
            sampleCount <= 0;
            t0En <= not ACTIVE;
        elsif rising_edge(clock) then
            if t0GenEn = ACTIVE then
                --Capture the middle of the sample
                sampleCount <= t0Samples/2;

               -- We want to output a pulse every half cycle to sample in the middle
                if genCounter /= sampleCount then
                    genCounter := genCounter+1;
                    genPulse <= not ACTIVE;
                    
                else
                    --Reset Counter whenever 
                    genCounter := 0;
                    genPulse <= not genPulse;    
                end if;   
            else 
                genPulse <= not ACTIVE;
                genCounter := 0;
            end if;
        end if;
       -- Assign output--
        t0En <= genPulse;
    end process;

    

end architecture;
