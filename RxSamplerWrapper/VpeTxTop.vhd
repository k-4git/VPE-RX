----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 09/07/2024 04:26:04 PM
-- Design Name: VpeTransmitter - HW Implementation
-- Module Name: VpeTx_Top - VpeTx_Top_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Description: Top Module that connects all of the responsible components for the 
--              VpeTransmitter.
-- 
--              The following signals are used.
--
--              data       : 32 bit word that will be translated and sent via vpeSerial based on the 
--                            current standard.
--              loadEn     :  Flag set by an external source to tell the transmitter to load in the data
--                            from the bus.
--              clock    : the clock signal
--              reset    : resets the component when value is set to HIGH.
--              t0En     :  The pulse that the data will be transmitted at.
--              txMode   : std_logic - The flag that will tell the transmitter to start sending information.
--              wordEndEn : std_logic - External flag letting the controller know that the word is nearing 
--                                      completion of transmitting the signal. Normally set high when the last
--                                      high pulse is being transmitted.
--              vpeSerial : in STD_LOGIC: The signal of pulses that we will listen to.
--
-- Dependencies: None
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity VpeTxTop is
    Port (data : in STD_LOGIC_VECTOR (31 downto 0); 
          t0En : in STD_LOGIC;
          txMode : in STD_LOGIC; 
          loadEn: in STD_LOGIC; 
          clock : in STD_LOGIC;
          reset : in STD_LOGIC;
          
          vpeSerial : out STD_LOGIC;
          wordEndEn : out STD_LOGIC);
end entity VpeTxTop;

architecture VpeTxTop_ARCH of VpeTxTop is
    constant ACTIVE: std_logic := '1';
    
    signal highCount: integer range 0 to 7;
    signal lowCount: integer range 0 to 7;
    signal nextNibble: std_logic;
    signal nibbleIndex: integer range 0 to 7;
    signal sendWS: std_logic;
    signal sendWord: std_logic;
    signal sendFS: std_logic;
    signal currentNibble: std_logic_vector(3 downto 0);
    signal outputData: std_logic_vector(3 downto 0);
    signal highCountIndex: integer range 0 to 7;
    signal startTx: std_logic;
    
    component TxController is
        Port ( 
            txMode : in STD_LOGIC;
            loadEn: in STD_LOGIC;
            clock : in STD_LOGIC;
            reset : in STD_LOGIC;
            nibbleIndex: in integer;
    
            highCountIndex: in integer; 
            t0En: in std_logic;
            startTx: out std_Logic;
            wordEndEn: out std_logic;
            sendWS : out STD_LOGIC;
            sendFS : out STD_LOGIC;
            nextNibble: out STD_LOGIC;
            sendWord : out STD_LOGIC);
    end component;    
    
    component TxPulse is
        Port ( highCount : in integer;
               lowCount : in integer;
               t0En : in STD_LOGIC;
               clock : in STD_LOGIC;
               reset : in STD_LOGIC;
               startTx: in STD_LOGIC;
               vpeSerial : out STD_LOGIC;
               highCountIndex : out integer range 0 to 7);
              
    end component;
    
    component WordShift is
        port (
            -- Inputs --
            clock      : in std_logic;
            reset      : in std_logic;
            nextNibble : in std_logic;
            loadEn     : in std_logic;
            data       : in std_logic_vector(31 downto 0);
            
            -- Outputs --
            currentNibble: out std_logic_vector(3 downto 0);
            nibbleIndex : out integer range 0 to 7
        );
    end component;
    
    component PulseEncode is
        Port ( currentNibble : in STD_LOGIC_VECTOR (3 downto 0);
               sendWS : in STD_LOGIC;
               sendFS : in STD_LOGIC;
               sendWord : in STD_LOGIC;
               startTX : in STD_LOGIC;
               clock : in STD_LOGIC;
               reset : in STD_LOGIC;
               lowCount: out integer range 0 to 7;
               highCount: out integer range 0 to 7
               );
    end component;
    
    
    begin
    
        TX_PULSE: TxPulse port map (
            highCount => highCount,
            lowCount => lowCount,
            t0En => t0En,
            clock => clock,
            startTx => startTx,
            reset => reset,
            vpeSerial => vpeSerial,
            highCountIndex => highCountIndex
        );
    
        
        PULSE_ENCODE: PulseEncode port map (
            currentNibble => currentNibble,
            sendWS => sendWS,
            sendFS => sendFS,
            sendWord => sendWord,
            startTX => startTX,
            clock => clock,
            reset => reset,
            lowCount => lowCount,
            highCount => highCount
        );
    
        WORD_SHIFT: WordShift port map
        (
            -- Inputs --
            clock  => clock,
            reset  => reset,
            nextNibble => nextNibble,
            loadEn  => loadEn,
            data => data,
            currentNibble => currentNibble,
            nibbleIndex => nibbleIndex
        ); 
        
        TX_CONTROLLER: TxController port map ( 
            txMode => txMode,
            loadEn => loadEn,
            clock  => clock,
            reset => reset,
            wordEndEn => wordEndEn,
            t0En => t0En,
            nibbleIndex => nibbleIndex,
            highCountIndex => highCountIndex,
            nextNibble => nextNibble,
            sendWS => sendWS,
            sendFS => sendFS,
            sendWord => sendWord,
            startTx => startTx
        );
        

end VpeTxTop_ARCH;
