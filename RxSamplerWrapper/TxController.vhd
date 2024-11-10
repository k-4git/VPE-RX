-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 09/16/2024 06:39:03 PM
-- Design Name: VPE Signal Transmitter.
-- Module Name: TxController - TxController_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Target Devices: None.
-- Tool Versions: 
-- Description: Controller Component that handles the current state of the VpeTx Component.
--              This compnent is responsible for ensure that the proper packets are sent sequentially. 
-- 
--
-- Dependencies: None
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity TxController is
    Port ( 
        txMode : in STD_LOGIC;
        loadEn: in STD_LOGIC;
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        nibbleIndex: in integer;
        t0En: in std_logic;
        highCountIndex: in integer range 0 to 7;
        
        startTx: out std_logic;
        nextNibble: out STD_LOGIC;
        sendWS : out STD_LOGIC;
        sendFS : out STD_LOGIC;
        wordEndEn : out STD_LOGIC;
        sendWord : out STD_LOGIC
        );
end TxController;

architecture TxController_ARCH of TxController is
    
    constant ACTIVE: std_logic := '1';


    type state_t is (IDLE, FRAME_START, NEXT_WORD_TRANSITION, TX_ENCODE);
    
    signal currentState: state_t;
    
    begin

        TX_CONTROL: process (clock, reset)
        variable nextNibbleTemp: std_logic := not ACTIVE;
        variable sendAnotherWordFlag: std_logic := not ACTIVE;
        variable t0EnCount: integer := 0;
        variable transitionCount: integer := 0;
        begin
            if (reset = ACTIVE) then
                sendWS <= not ACTIVE;
                sendWord <= not ACTIVE;
                sendFS <= not ACTIVE;
                currentState <= IDLE;
                wordEndEn <= not ACTIVE;
                sendAnotherWordFlag := not ACTIVE;
                t0EnCount := 0;
                transitionCount := 0;
            
            elsif (rising_edge(clock)) then
                wordEndEn <= not ACTIVE;
                case currentState is
                    when IDLE =>
                        startTx <= not ACTIVE;
                        sendWS <= not ACTIVE;
                        sendFS <= not ACTIVE;
                        sendWord <= not ACTIVE;
                        
                        -- Ready to start sending the packets.
                        if(txMode = ACTIVE and loadEn = ACTIVE) then
                            currentState <= FRAME_START; 
                        end if;
                        
                    --Transmitting the Frame Start Packet.        
                    when FRAME_START =>
                       sendFS <= ACTIVE;
                       startTx <= ACTIVE;   
                       if(highCountIndex = 0) then
                            currentState <= TX_ENCODE;
                            startTx <= not ACTIVE;
                       end if;
                    
                    --Transmitting nibbles in the word.   
                    when TX_ENCODE =>
                       sendWORD <= ACTIVE;
                       sendFS <= not ACTIVE;
                       startTx <= ACTIVE;
                       nextNibble <= not ACTIVE;
                       if(highCountIndex = 0) then
                          if(nibbleIndex > 0) then
                            nextNibble <= ACTIVE;
                          else
                            wordEndEn <= ACTIVE;
                            currentState <= NEXT_WORD_TRANSITION;
                          end if;
                       end if;
                    
                    --If we're loading in another word,
                    --Transmit a word pulse, otherwise, go back
                    -- to IDLE.   
                    when NEXT_WORD_TRANSITION => 
                       sendWS <= ACTIVE;
                       sendWord <= not ACTIVE;
                       startTx <= ACTIVE;
                       wordEndEn <= not ACTIVE;
                       
                       
                       --Flag. We do this during the first and second pulse
                       -- of the word start. if this gets set before the "LOGIC HIGH"
                       -- pulse for word start is sent, then we know to finisht the word
                       -- start and load in another word.
                       if(loadEn = ACTIVE) then
                           sendAnotherWordFlag := ACTIVE;                           
                        end if;
                        
                        
                       --If we're finishing up sending the low pulse of the word start
                       --and loadEn was never set, then go back to idle.
                       if(t0EnCount = 1 and sendAnotherWordFlag = not ACTIVE) then
                            currentState <= IDLE;
                       
                       --Else if we're set to send another word, 
                       --This logic ensures that we finish sending the
                       --single low and high pulse of the WORD_START transmission
                       --over vpe.
                       elsif(sendAnotherWordFlag = ACTIVE) then
                           if(t0EnCount = 2) then
                            sendWS <= not ACTIVE;
                            sendWord <= ACTIVE;
                            currentState <= TX_ENCODE;
                            sendAnotherWordFlag := not ACTIVE;
                            t0EnCount := 0;
                           end if;
                       
                       --Else if we haven't finished the transition,
                       --keep the state the same.      
                       elsif(t0EnCount < 2) then
                         currentState <= NEXT_WORD_TRANSITION;
                         sendWS <= ACTIVE;
                       
                       else
                        --Finally we're done with all of the cycles,
                        --We're not sending the word start, so we're 
                        --going back to the idle state.
                        sendWS <= not ACTIVE;
                        t0EnCount := 0;
                        currentState <= IDLE;
                       end if;
                       
                       --Increment the t0En pulse that we're currently on.
                       if(t0En = ACTIVE) then
                        t0EnCount := t0EnCount + 1;
                       end if;      
                end case;        
            end if;
        end process;
end architecture TxController_ARCH;