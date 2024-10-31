library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Entity that counts pulses and assembles them into 7-bit frames
entity PulseCounter is
    port (
        clock     : in std_logic;     -- System clock
        reset     : in std_logic;     -- Reset signal
        vpeClean  : in std_logic;     -- Input pulse signal
        t0En      : in std_logic;     -- Enable signal for sampling
        dataReady : out std_logic;    -- Indicates valid frame
        rxWord    : out std_logic_vector(6 downto 0) -- Output frame
    );
end entity PulseCounter;

architecture behavioral of PulseCounter is
    constant ACTIVE : std_logic := '1';
    signal rxFrame  : std_logic_vector(6 downto 0); -- Stores assembled frame
    signal t0Prev   : std_logic;                    -- Previous t0En for edge detection
    signal dataReady_sig: std_logic;
       
begin    
    -- Main process for sampling pulses and assembling frames
    PULSECOUNTER: process (clock, reset)
    variable rxFrame_var: std_logic_vector(6 downto 0);  -- Shift register for frame assembly
    begin
        if reset = ACTIVE then
            rxFrame <= (others => '1');
            rxFrame_var := (others => '1');
            
        elsif rising_edge(clock) then
            dataReady <= not ACTIVE;          
            
            -- Sample on rising edge of t0En
            if t0En = ACTIVE and t0prev = '0' then              
                 -- Check for frame completion (vpeClean=0 and LSB=1)
                 if vpeClean = '0' and rxFrame_var(0) = '1' then
                    rxFrame <= rxFrame_var;        -- Save completed frame
                    rxFrame_var := "1111111";      -- Reset shift register
                    dataReady <= ACTIVE;           -- Signal frame complete
                    
                 end if;
                 -- Shift in new bit
                 rxFrame_var :=  rxFrame_var(5 downto 0) & vpeClean;
            end if;            
          
            t0Prev <= t0En;
        end if;
        rxWord <= rxFrame;       
    end process;
    
end architecture;