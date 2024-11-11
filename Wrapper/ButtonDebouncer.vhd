----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/11/2024 04:33:46 PM
-- Design Name: 
-- Module Name: ButtonDebouncer - ButtonDebouncer_ARCH
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ButtonDebouncer is
  generic ( DEBOUNCE_CYCLES : integer);  -- For 100 MHz clock (100MHz * 5ms)
        
  Port ( 
        buttonIn: in std_logic;
        pulseOut: out std_logic;
        clock: in std_logic;
        reset: in std_logic );
end ButtonDebouncer;
    
architecture ButtonDebouncer_ARCH of ButtonDebouncer is
    --------------------------------------------------------------------CONSTANTS
    constant ACTIVE: std_logic := '1';
    
    -- Two-stage synchronizer to prevent metastability
    signal sync0, sync1 : STD_LOGIC := '0';
    --------------------------------------------------------------------SIGNALS
    signal trigger: std_logic;      
    signal debounced : std_logic :='0';                                  --Stabilized Pulse
    signal counter: integer range 0 to DEBOUNCE_CYCLES := 0;
    
    
begin

    ----------------------------------------------------------------PROCESS: Stabilizer
     -- Synchronize the asynchronous button input to the clock domain
    SYNC_CHAIN: process(clock, reset)
    begin
        if reset = ACTIVE then
            sync0 <= '0';
            sync1 <= '0';
        elsif rising_edge(clock) then
            sync0 <= buttonIn;
            sync1 <= sync0;
        end if;
    end process;       
    
    DEBOUNCER: process(clock, reset)
   -- variable counter: integer range 0 to DEBOUNCE_CYCLES := 0;
    begin
        if reset = ACTIVE then
            counter <= 0;
            debounced <= not ACTIVE;
        elsif (rising_edge(clock)) then
            if counter < DEBOUNCE_CYCLES then
                counter <= counter +1;
            elsif counter = DEBOUNCE_CYCLES then
                debounced <= sync1;
                counter <= 0;
            end if;          
        end if;
    end process;     
    trigger <= debounced;
    ----------------------------------------------------------------Process: Pulse Generator
    LevelDetector: process(reset, clock)                          --Will output A single Pulse
        variable held: std_logic;                                 --When Trigger goes from a 
    begin                                                         --Low to a High
        if (reset=ACTIVE) then                                    --Will Reset AfterWards
            pulseOut <= not ACTIVE;
            held  := not ACTIVE;
        elsif (rising_edge(clock)) then
            pulseOut <= not ACTIVE;
            if (trigger=ACTIVE) then
                if (held = not ACTIVE) then
                    pulseOut <= ACTIVE;
                    held        := ACTIVE;
                end if;
            else
                held := not ACTIVE;
            end if;
        end if;
    end process;
end ButtonDebouncer_ARCH;