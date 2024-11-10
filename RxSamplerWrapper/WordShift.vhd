----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 10/01/2024 05:25:41 PM
-- Design Name: VpeTransmitter - HW Implementation
-- Module Name: WordShift - WordShift_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Description: Receives a 4-bit number, and converts it to a series of high and low pulses.
-- 
-- Signals:
--      loadEn: std_logic - flag to tell the component to load in the next word.
--      nextNibble: - flag to tell the component to shift in the next nibble to the output.                                  
--      clock: std_logic - the clock signal to drive the component.
--      reset: std_logic - the signal that will reset the component to initial settings.
--      data: std_logic_vector(31 downto 0) - 32 bit word that will be translated and sent
--                     via vpeSerial based on the current standard.
--      currentNibble: std_logic_vector(3 downto 0) - the current nibble that needs to be transmitted
--      nibbleIndex: integer: the index of the current nibble in the word being processed.
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity WordShift is
    port (
        -- Inputs --
        clock      : in std_logic;
        reset      : in std_logic;
        nextNibble : in std_logic;
        loadEn     : in std_logic;
        data       : in std_logic_vector(31 downto 0);
        
        -- Outputs --
        currentNibble: out std_logic_vector(3 downto 0);
        nibbleIndex: out integer range 0 to 7
    );
end entity WordShift;

architecture WordShift_ARCH of WordShift is

    constant ACTIVE   : std_logic := '1';
        
begin
   
    PROCESS_WORD: process (clock, reset)
        variable foundStart: std_logic := not ACTIVE;
        variable nibbleIndexTemp: integer range 0 to 7 := 7;
        variable currentWord: std_logic_vector(31 downto 0) := (others => not ACTIVE);
        
        begin
            if reset = ACTIVE then
                currentNibble  <= (others => not ACTIVE);
                nibbleIndexTemp   := 7;
                currentWord     := (others => not ACTIVE);
            elsif rising_edge(clock) then
               
                --Find starting point when we load in a new word. 
                if(loadEn = ACTIVE) then
                    foundStart := not ACTIVE;
                    nibbleIndexTemp := 7;
                    currentWord := data;
                    for i in 7 downto 0 loop
                        if(currentWord(i*4+3 downto i*4) /= "0000") then
                            if(foundStart = not ACTIVE) then
                                nibbleIndexTemp := i;
                                foundStart := ACTIVE;
                            end if;
                        end if;
                    end loop;  
                end if;
                

                if(nextNibble = ACTIVE) then
                    if(nibbleIndexTemp > 0) then
                        nibbleIndexTemp := nibbleIndexTemp - 1; 
                    end if;
                end if;
                nibbleIndex <= nibbleIndexTemp;
                currentNibble <= currentWord(nibbleIndexTemp*4+3 downto nibbleIndexTemp*4);
            end if;
    end process;

end architecture WordShift_ARCH;

