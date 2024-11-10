----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/31/2024 03:30:26 PM
-- Design Name: 
-- Module Name: Rx_Controller - Rx_Controller_ARCH
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

entity Rx_Controller is
    Port ( wordStartEn : in STD_LOGIC;
           frameStartEn : in STD_LOGIC;
           idleEn : in STD_LOGIC;
           
           wordFlag : out STD_LOGIC;
           endFlag : out STD_LOGIC;
           tGenMode : out STD_LOGIC;
           
           clock: in std_logic;
           reset: in std_logic);
           
end Rx_Controller;

architecture Rx_Controller_ARCH of Rx_Controller is

--Create type and signal for state machine
type state_t is (IDLE, SAMPLE);
signal rx_State: state_t;

--CONSTANTS
constant ACTIVE: std_logic := '1';


begin
    RX_CONTROLLER: process(clock, reset)
    
    begin
        if(reset = ACTIVE) then
        
            --If Reset, Set all Outputs to not ACTIVE,
            --set State back to IDLE
            wordFlag <= not ACTIVE;
            endFlag <= not ACTIVE;
            tGenMode <= not ACTIVE;
            rx_State <= IDLE;
        elsif(rising_edge (clock)) then
            case (rx_State) is
                --No pulse being decoded or sampled
                when (IDLE) =>
                
                    --Sampling Mode Control Signal is off
                    tGenMode <= not ACTIVE;
                    
                    --If frameStart Pulse is detected
                    if(frameStartEn = ACTIVE) then
                    
                        --Enable Sampling Mode Signal and
                        --Change State to SAMPLE
                        tGenMode <= ACTIVE;
                        rx_State <= SAMPLE;
                    end if;
                
                --SAMPLE State is to detect different control signals
                --and outputs different Flags       
                when (SAMPLE) =>
                    
                    --Keep tGenMode on
                    tGenMode <= ACTIVE;
                    
                    --Initially, wordFlag and endFalg is not ACTIVE
                    wordFlag <= not ACTIVE;
                    endFlag <= not ACTIVE;     
                    
                    --If Decoder sees all 0s, go back to IDLE
--                    if(idleEn = ACTIVE) then
--                        rx_State <= IDLE;
                        
                    --Else, if Frame is Detected, Keep Decoding
                    --and send endFlag
                    if(frameStartEn = ACTIVE) then
                        endFlag <= ACTIVE;
                    --Else, if Word is detected, Send WordFlag
                    elsif(wordStartEn = ACTIVE) then
                        wordFlag <= ACTIVE;
                    end if;
                    
                    -- Include when others for synthesis safety
                when others =>
                    rx_State <= IDLE;
                    tGenMode <= not ACTIVE;
                    wordFlag <= not ACTIVE;
                    endFlag <= not ACTIVE;          
            end case; 
        end if;   
    end process;  

end Rx_Controller_ARCH;
