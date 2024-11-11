----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey
-- 
-- Create Date: 10/01/2024 05:25:41 PM
-- Design Name: VpeTransmitter - HW Implementation
-- Module Name: PulseEncode - PulseEncode_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Description: Receives a 4-bit number, and converts it to a series of high and low pulses.
-- 
-- Signals:
--      currentNibble: std_logic_vector(3 downto 0) - the 4-bit number to be converted.
--                                   ****sendWord needs to be enabled for this to transmit.
--      sendWS: std_logic - When ACTIVE, this component will output a single low and high pulse, which is 
--                          the representation of the signal.
--      sendFS: std_logic - When ACTIVE, this component will output 6 low and a signle high pulse, which is 
--                          the representation of the signal.
--      sendWord: std_logic - When ACTIVE, this component will send the combination of low and high pulses
--                            depending which nibble is loaded in.
--      startTx : std_logic - flag that tells the component whether to update the current low and high pulse counts.
--      clock: std_logic - the clock signal to drive the component.
--      reset: std_logic - the signal that will reset the component to initial settings.
--      lowCount: integer range 0 to 7: the number of low pulses to be sent.
--      highCount: integer range 0 to 7: the number of high pulses to be sent.
--
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PulseEncode is
    Port ( currentNibble : in STD_LOGIC_VECTOR (3 downto 0);
           sendWS : in STD_LOGIC;
           sendFS : in STD_LOGIC;
           sendWord : in STD_LOGIC;
           startTx : in STD_LOGIC;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           lowCount: out integer range 0 to 7;
           highCount: out integer range 0 to 7
           );
end PulseEncode;

architecture PulseEncode_ARCH of PulseEncode is
    
    constant ACTIVE: std_logic := '1';
    
    function get_low_count(dataNibble: in std_logic_vector(3 downto 0)) return integer is
        begin
          case(dataNibble) is
                when "0000" => return 1;
                when "0001" => return 2;
                when "0010" => return 1;
                when "0011" => return 2;
                when "0100" => return 3;
                when "0101" => return 1;
                when "0110" => return 2;
                when "0111" => return 3;
                when "1000" => return 4;
                when "1001" => return 1;
                when "1010" => return 2;
                when "1011" => return 3;
                when "1100" => return 4;
                when "1101" => return 5;
                when "1110" => return 1;
                when others => return 2;
            end case;
        end function;
    
        function get_high_count(dataNibble: in std_logic_vector(3 downto 0)) return integer is
        begin
          case(dataNibble) is
                when "0000" => return 2;
                when "0001" => return 1;
                when "0010" => return 3;
                when "0011" => return 2;
                when "0100" => return 1;
                when "0101" => return 4;
                when "0110" => return 3;
                when "0111" => return 2;
                when "1000" => return 1;
                when "1001" => return 5;
                when "1010" => return 4;
                when "1011" => return 3;
                when "1100" => return 2;
                when "1101" => return 1;
                when "1110" => return 6;
                when others => return 5;
            end case;
        end function;  
begin

    ENCODE_NIBBLE: process(clock, reset)
    begin
        if (reset = ACTIVE) then
            lowCount <= 0;
            highCount <= 0;
        else
            if (rising_edge(clock)) then
                if(startTx = ACTIVE) then
                             lowCount <= 7; 
                             highCount <= 7;    
                     if(sendWS = ACTIVE) then
                            lowCount <= 1;
                            highCount <= 1;
                        elsif(sendFS = ACTIVE) then
                            lowCount <= 6;
                            highCount <= 1;
                        elsif(sendWord = ACTIVE) then
                            lowCount <= get_low_count(currentNibble);
                            highCount <= get_high_count(currentNibble);
                        end if;
                end if;
            end if;
        end if;
    end process;


end PulseEncode_ARCH;
