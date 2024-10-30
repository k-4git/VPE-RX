library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PulseCounter is
    port (
        clock   : in std_logic;
        reset   : in std_logic;
        vpeClean : in std_logic;
        t0En     : in std_logic;
        rxWord : out std_logic_vector(6 downto 0)
    );
end entity PulseCounter;

architecture behavioral of PulseCounter is
    constant ACTIVE : std_logic := '1';
    signal rxFrame : std_logic_vector(6 downto 0); --:= "0000000";
    signal vpeReader:  std_logic;
        
begin    
    PULSECOUNTER: process (clock, reset)
    begin
        if reset = ACTIVE then
            --rxFrame <= (others => '0');
            vpeReader <= '0';
        elsif rising_edge(clock) then
            vpeReader <= vpeClean;
           
            if t0En = ACTIVE then
                rxFrame <= vpeReader & rxFrame(6 downto 1);
            end if;
        end if;
        rxWord <= rxFrame;
    end process;
    
end architecture;