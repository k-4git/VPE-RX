library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxDecoder is
    port (
        clock     : in std_logic;
        reset     : in std_logic;
        dataReady : in std_logic;
        rxWord    : in std_logic_vector(6 downto 0);       
        idleEn    : out std_logic
    );
end entity RxDecoder;

architecture behavioral of RxDecoder is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';

    --+++=========Signals========+++--
    signal rxWord_sig : std_logic_vector (6 downto 0);
    signal bitFlag : boolean := false;
    signal bitPos  : integer;
    --+++=========functions========+++--
    
begin
    DATA_CHECKER: process (clock, reset)
   -- variable bitFlag : boolean := false;
   -- variable bitPos  : integer;
    begin
        if reset = ACTIVE then
            bitflag <= false;
            bitPos  <= 0;
        elsif rising_edge(clock) then
            if dataReady = ACTIVE then
                if rxWord /= "1111111" or rxWord /= "0000000" then
                    for i in 6 downto 0 loop
                        if rxWord(i) = '0' and bitFlag = false then
                            bitPos <= i;
                            bitFlag <= true;
                        end if;
                    end loop;                    
                elsif rxWord = "0000000" then
                    idleEn <= ACTIVE;
                end if;
            else 
                bitFlag <= false;
                bitPos  <= 0;
        end if;
    end process;

    DECODER: process (clock, reset)
    variable rxWord_var : std_logic_vector ( bitPos downto 0);
    begin
        if reset = ACTIVE then
            
        elsif rising_edge(clock) then
            if bitFlag = true then
                --We need to check grab bit position
                -- and use functions to decode and push into nibble
                rxWord_var := rxWord(bitPos downto 0); 
                -- now decode with functions
            end if ;
            
        end if;
    end process;
    

end architecture;