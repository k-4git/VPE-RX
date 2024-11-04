----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/03/2024 11:54:57 AM
-- Design Name: 
-- Module Name: DataController - DataController_ARCH
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

entity DataController is
    Port ( modeSwitch : in STD_LOGIC;
           switches : in STD_LOGIC_VECTOR (15 downto 0);
           deButton : in STD_LOGIC;
           rxOut : in STD_LOGIC_VECTOR (15 downto 0);
           newWord : in STD_LOGIC;
           endFrame : in STD_LOGIC;
           clock: in std_logic;
           reset: in std_logic;
           
           wordDigit3 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit2 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit1 : out STD_LOGIC_VECTOR (3 downto 0);
           wordDigit0 : out STD_LOGIC_VECTOR (3 downto 0);
           leds : out STD_LOGIC_VECTOR (15 downto 0));
end DataController;

architecture DataController_ARCH of DataController is
------------------------------------------------------------------CONSTANTS
constant ACTIVE : std_logic := '1';

------------------------------------------------------------------ARRAY DECLARATION
type vector_a is array(0 to 3) of std_logic_vector(63 downto 0);

------------------------------------------------------------------SIGNALS
signal frameONE: std_logic_vector( 63 downto 0);
signal frameTWO: std_logic_vector( 63 downto 0);
signal frameTHREE: std_logic_vector( 63 downto 0);
signal frameFOUR: std_logic_vector( 63 downto 0);

begin
    
    --Holds the Data Decoded from the receive and pushes each word into a 64-Bit Value
    --Has 4 Seperate Frames for a total of 16 words total.
    DATA_REGISTER: process(clock, reset)
    --------------------------------------------------------------VARIABLES
    
    --Variable Array
    variable dataArray: vector_a;
    
    --Counts the address of the Frame and Word for Reference
    variable wordCounter: integer := 0;
    variable frameCounter: integer := 0;
    
    --Holds the Values of the current selected Frame and Word
    variable currentFrame: std_logic_vector( 63 downto 0);
    variable currentWord: std_logic_vector( 15 downto 0); 
    
    begin
    
    if(reset = ACTIVE) then
        dataArray(0) := (others => '0');
        dataArray(1) := (others => '0');
        dataArray(2) := (others => '0');
        dataArray(3) := (others => '0');
        
        wordDigit3 <= (others => '0');
        wordDigit2 <= (others => '0');
        wordDigit1 <= (others => '0');
        wordDigit0 <= (others => '0');
        
        leds <= (others => '0');
    elsif(rising_edge (clock)) then
    
    
        if(modeSwitch = ACTIVE) then
        
            if(newWord = ACTIVE) then
                wordCounter := wordCounter + 1;
            elsif(endFrame = ACTIVE) then
                frameCounter := frameCounter + 1;
            end if;
            
            currentFrame := dataArray(frameCounter);
            currentWord := rxOut;
            
            if(wordCounter < 4) then
                dataArray(frameCounter) := currentFrame(47 downto 0) & currentWord;
            elsif(wordCounter = 4) then
                wordCounter := 0;
            end if;
                                             
            
                
                    
           
        
        
        end if;
    end if;
    
    end process;    

end DataController_ARCH;
