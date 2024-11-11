----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 10/11/2024 10:15:51 PM
-- Design Name: VPE Signal Generator Hardware (Basys3)
-- Module Name: Basys3 - Basys3_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Target Devices: Xilinx Basys3
-- Description: Basys3 implementation that connects the Basys3 Ports to the VPE Transmitter Hardware.
--
--              Use the switches (sw) to represent the 16 bit representation of the data to send. 
--              
--              Once the data is represented with the proper switch combinations, press btnR to store
--              the information into the internal register. This version can store then send 3 different words internally within 
--              a signle frame.
--
--              After loading in 1-3 words, press btnL to transmit the data via JA1. Data will send as a waveform following the 
--              protocol standard set in the patented work.
-- Ports:
--           sw : in STD_LOGIC_VECTOR (15 downto 0);
--           btnL: in std_logic - Used to send the data that is stored within the internal registers.
--           btnR: in std_logic - Used to load the data representation of the switch inputs into the register.
--           btnD: in std_logic - Used to reset the transmitter. Clears internal registers.
--           clk: in std_logic - Driving Clock for the transmitter.   
--           an   : out std_logic_vector(3 downto 0); - anode of 7seg
--           seg  : out std_logic_vector(6 downto 0); - 7seg connections
--           led  : out STD_LOGIC_VECTOR(15 downto 0); - led
--           JA1: out std_logic - The JA port that transmits the protocol signal data that was stored in the registers.
--  
-- 
-- Dependencies: None
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Basys3 is
    Port ( sw : in STD_LOGIC_VECTOR (15 downto 0);
           btnL : in std_logic;
           btnR : in std_logic;
           btnD : in std_logic;
           clk  : in std_logic;
           btnU : in std_logic;
           led  : out STD_LOGIC_VECTOR(15 downto 0);
           seg  : out std_logic_vector(6 downto 0);    
           an   : out std_logic_vector(3 downto 0); 
           JB1  : in std_logic;
           JA1: out std_logic
            );
end Basys3;

architecture Basys3_ARCH of Basys3 is
    
    signal data: std_logic_vector (31 downto 0);
    
    component Wrapper is
        Generic(count: integer);
        Port ( data        : in STD_LOGIC_VECTOR (15 downto 0);
           loadData    : in STD_LOGIC;
           sendData    : in STD_LOGIC;
           clock       : in STD_LOGIC;
           reset       : in STD_LOGIC;
           modeChange  : in STD_LOGIC;
           vpeSerialIn : in STD_LOGIC;
           leds        : out STD_LOGIC_VECTOR(15 downto 0);
           sevenSegs   : out std_logic_vector(6 downto 0);    
           anodes      : out std_logic_vector(3 downto 0);
           vpeSerial   : out STD_LOGIC);
    end component;
    
    begin
    
    BASYS_3_WRAPPER: Wrapper generic map (100000)
             port map (
                data => sw,
                loadData => btnR,
                sendData => btnL,
                clock => clk,
                reset => btnD,
                sevenSegs => seg,
                leds => led,
                modeChange => btnU,
                anodes => an,
                vpeSerialIn => JB1,
                vpeSerial => JA1
    );
    

end Basys3_ARCH;