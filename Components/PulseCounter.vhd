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
--+++=========Constants========+++--
constant ACTIVE : std_logic := '1';
    
--+++=========Signals========+++--
signal vpeReader : std_logic;
signal rxFrame   : std_logic_vector(7 downto 0) := "00000000";

begin
    
    PULSECOUNTER:  process (clock, reset)
    variable dataFlag : boolean := TRUE;
    begin
        if reset = ACTIVE then
            rxFrame <= "00000000";
            vpeReader <= '0';
        elsif rising_edge(clock) then
            if dataFlag = TRUE then
                vpeReader <= vpeClean;
                rxFrame(7) <= '0';  -- Always keep MSB as 0

                if t0En = ACTIVE then
                    if vpeReader = ACTIVE then
                        rxFrame(6 downto 0) <= rxFrame(5 downto 0) & '1';
                    elsif vpeReader = not ACTIVE then
                        rxFrame(6 downto 0) <= rxFrame(5 downto 0) & '0';
                    end if;                   
                end if;             
            end if;
        end if;
        rxWord <= rxFrame(6 downto 0);
    end process;

end architecture;