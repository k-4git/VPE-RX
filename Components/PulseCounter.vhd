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
        dataReady: out std_logic;
        rxWord : out std_logic_vector(6 downto 0)
    );
end entity PulseCounter;

architecture behavioral of PulseCounter is
    constant ACTIVE : std_logic := '1';
    signal rxFrame  : std_logic_vector(6 downto 0); --:= "0000000";
    signal vpeReader: std_logic;
    --signal dataReady: std_logic;
    signal t0Prev   : std_logic; 
    signal dataReady_sig: std_logic;
       
begin    
    PULSECOUNTER: process (clock, reset)
    variable rxFrame_var: std_logic_vector( 6 downto 0);
    begin
        if reset = ACTIVE then
            rxFrame <= (others => '1');
            rxFrame_var := (others => '1');
            vpeReader <= '0';
        elsif rising_edge(clock) then
            dataReady <= not ACTIVE;
            if t0En = ACTIVE and t0prev = '0' then
                  -- rxFrame_var := rxFrame;                
                 if vpeClean = '0' and rxFrame_var(0) = '1' then
                    rxFrame <= rxFrame_var;
                    rxFrame_var := "1111111";
                    dataReady <= ACTIVE;                    
                    
                 end if;
                 rxFrame_var :=  rxFrame_var(5 downto 0) & vpeClean;
            end if;            
          
            vpeReader <= vpeClean;
            t0Prev <= t0En;
        end if;
        rxWord <= rxFrame;       
    end process;

    
end architecture;