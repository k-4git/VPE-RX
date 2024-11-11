----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 09/29/2024 08:19:09 PM
-- Design Name: VpeTransmitter - HW Implementation
-- Module Name: TxPulse - Behavioral
-- Project Name: CPE 4490 - Advanced VHDL
-- Description: Transmits the VPE signal varying on the number of high pulses and low pulses.
-- 
-- Ports:
--      highCount: std_logic - the number of ACTIVE HIGH pulses to send sequentially.
--      lowCount: std_logic - the number of ACTIVE LOW pulses to send sequentially.
--      t0En: std_logic - the signal that controls when to send the next pulse. This is set
--            by an external stimulus.
--      startTx : std_logic: flag that tells the component whether or not to start transmitting
--                the number of high and low pulses that are active on the highCount and lowCount busses.
--      clock: std_logic - the clock signal to drive the component.
--      reset: std_logic - the signal that will reset the component to initial settings.
--      vpeSerial: std_logic - the output signal that will transmit the encoded pulses.
--      highCountIndex: integer - the current index of the high pulse being sent. When the
--                      high pulses are done transmitting, this value will be 0. Also used 
--                      in the TxController to control the current state of the transmitter.
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity TxPulse is
    Port ( highCount : in integer;
           lowCount : in integer;
           startTx: in std_logic;
           t0En : in STD_LOGIC;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           vpeSerial : out STD_LOGIC;
           highCountIndex : out integer range 0 to 7);
end TxPulse;

architecture TxPulse_ARCH of TxPulse is
    constant ACTIVE: std_logic := '1';
   
    signal transmittingZeroes: std_logic := ACTIVE;
    signal currentCount: integer range 0 to 7 := 1;
begin

PROCESS_DATA: process(clock, reset)
    variable highCountIndexTmp: integer range 0 to 7 :=7;
    
    begin
        if(reset = ACTIVE) then
            currentCount <= 1;
            transmittingZeroes <= ACTIVE;
            vpeSerial <= not ACTIVE;
            
        elsif(rising_edge(clock)) then

            highCountIndex <= 7;           
            
            if(t0En = ACTIVE) then
                vpeSerial <= not ACTIVE;
                if(startTx = ACTIVE) then
                    if(transmittingZeroes = ACTIVE) then
                        vpeSerial <= not ACTIVE;
                        if(currentCount >= lowCount) then
                            transmittingZeroes <= not ACTIVE;
                            currentCount <= 1;
                        else
                            currentCount<= currentCount + 1;
                        end if;
                        
                    else
                        vpeSerial <= ACTIVE;
                        if(currentCount >= highCount) then
                            transmittingZeroes <= ACTIVE;
                            currentCount <= 1;
                        else
                            currentCount <= currentCount + 1;
                        end if;
                        highCountIndexTmp := highCount - currentCount;
                        highCountIndex <= highCountIndexTmp;
                    end if;
                    
                end if;
            end if;
           end if;
    end process;


end TxPulse_ARCH;
