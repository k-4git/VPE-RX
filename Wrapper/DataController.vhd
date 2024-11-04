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

function Led_FOUR_Vector(vector: std_logic_vector) return std_logic_vector is

variable ledQUAD: std_logic_vector(3 downto 0) := (others => '0');

begin
    for i in 0 to 3 loop
        for j in 0 to 15 loop
            if(vector(j + 16* i) = '1') then
                LEDQUAD(i) := '1';
            end if;    
        end loop;
    end loop;                           
        
    return ledQUAD;
end function Led_FOUR_Vector;
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
        
        frameONE <= (others => '0');
        frameTWO  <= (others => '0');
        frameTHREE  <= (others => '0');
        frameFOUR <= (others => '0');
        
        leds <= (others => '0');
    elsif(rising_edge (clock)) then
        
        --If newWord is ACTIVE, increase wordCounter by 1
        if(newWord = ACTIVE) then
            wordCounter := wordCounter + 1;
        --elsif endFrame is ACTIVE, change frame Arrays
        elsif(endFrame = ACTIVE) then
            frameCounter := frameCounter + 1;
            wordCounter := 0;
        end if;
        
        --Insert frameCounter's Array into currentFrame
        currentFrame := dataArray(frameCounter);
        
        --Insert rxOut into 16-bit variable
        currentWord := rxOut;
        
        --If wordCounter is not at the end, insert currentWord from the right.
        if(wordCounter < 4) then
            dataArray(frameCounter) := currentFrame(47 downto 0) & currentWord;
        end if;
        
        --Stores data Arrays into seperate frame signals for view.
        frameONE <= dataArray(0);
        frameTWO <= dataArray(1);
        frameTHREE <= dataArray(2);
        frameFOUR <= dataArray(3);
    end if;

    end process;    
    
    --Will push data into the four 4-bit vectors from the selected
    --16-bit array using switches and the confirmation
    LED_SWITCH_DISPLAY: process(clock, reset)
    
    --Local variable for arrays and the switches for detection
    variable selectedArray: std_logic_vector(15 downto 0);
    variable selectedSwitches: std_logic_vector(3 downto 0);
    
    --Local variable for the sevenSegmentDriver based off
    --Selected Switch for the associated Word
    variable tempWordDigit3 : std_logic_vector(3 downto 0);
    variable tempWordDigit2 : std_logic_vector(3 downto 0);
    variable tempWordDigit1 : std_logic_vector(3 downto 0);
    variable tempWordDigit0 : std_logic_vector(3 downto 0);
    
    --The Leds divided into 4 pieces for the 4 frames
    variable frameLED1: std_logic_vector(3 downto 0);
    variable frameLED2: std_logic_vector(3 downto 0);
    variable frameLED3: std_logic_vector(3 downto 0);
    variable frameLED4: std_logic_vector(3 downto 0);
    
    --The total LED vector
    variable tempLeds :std_logic_vector(15 downto 0);
    begin
        if(reset = ACTIVE) then
            wordDigit3 <= (others => '0');
            wordDigit2 <= (others => '0');
            wordDigit1 <= (others => '0');
            wordDigit0 <= (others => '0');
            selectedArray := (others => '0');
        elsif(rising_edge (clock)) then
            --If RECEIVE MODE IS ON
            if(modeSwitch = ACTIVE) then
                --Calls function to return a 4-bit vector
                --that lights each one if there is a word
                --in the associated 16-bit of the total frame cap
                frameLED1 := Led_FOUR_Vector(frameONE);
                frameLED2 := Led_FOUR_Vector(frameTWO);
                frameLED3 := Led_FOUR_Vector(frameTHREE);
                frameLED4 := Led_FOUR_Vector(frameFOUR);
                
                --Combine all Signals into tempLeds to later display on leds
                tempLeds := frameLED1 & frameLED2 & frameLED3 & frameLED4;
                
                --If deButton(loadButton) then the switches input is 
                --updated on the SevenSegmentDriver
                if(deButton = ACTIVE) then
                    
                    --If switches = (xxxx 0000 0000 0000)
                    if(switches(15 downto 12) = not "0000" and switches(11 downto 0) = x"000") then
                        selectedArray := FrameONE;
                        selectedSwitches := switches(15 downto 12);        
                    --If switches = (0000 xxxx 0000 0000)
                    elsif(switches(11 downto 8) = not "0000" and switches(15 downto 12) = "0000" and switches(7 downto 0) = x"00") then
                        selectedArray := FrameTWO;
                        selectedSwitches := switches(11 downto 8); 
                    --If switches = (0000 0000 xxxx 0000)
                    elsif(switches(7 downto 4) = not "0000" and switches(15 downto 9) = "0000" and switches(3 downto 0) = "0000") then        
                        selectedArray := FrameTHREE;
                        selectedSwitches := switches(7 downto 4); 
                    --If switches = (0000 0000 0000 xxxx)    
                    elsif(switches(3 downto 0) = not "0000" and switches(15 downto 4) = x"000") then      
                        selectedArray := FrameFOUR;
                        selectedSwitches := switches(3 downto 0); 
                    else
                        selectedArray := selectedArray;
                    end if;
                    
                    --Case Statement for storing values into the variables for
                    --SevenSegmentDriver use
                    case(selectedSwitches) is
                        when "0001" =>
                            tempWordDigit3 := selectedArray(15 downto 12);
                            tempWordDigit2 := selectedArray(11 downto 8);
                            tempWordDigit1 := selectedArray(7 downto 4);
                            tempWordDigit0 := selectedArray(3 downto 0);
                        when "0010" =>
                            tempWordDigit3 := selectedArray(31 downto 28);
                            tempWordDigit2 := selectedArray(27 downto 24);
                            tempWordDigit1 := selectedArray(23 downto 20);
                            tempWordDigit0 := selectedArray(19 downto 16);
                        when "0100" =>
                            tempWordDigit3 := selectedArray(47 downto 44);
                            tempWordDigit2 := selectedArray(43 downto 40);
                            tempWordDigit1 := selectedArray(39 downto 36);
                            tempWordDigit0 := selectedArray(35 downto 32);
                        when "1000" =>
                            tempWordDigit3 := selectedArray(63 downto 60);
                            tempWordDigit2 := selectedArray(59 downto 56);
                            tempWordDigit1 := selectedArray(55 downto 52);
                            tempWordDigit0 := selectedArray(51 downto 48);
                        when others =>
                            tempWordDigit3 := tempWordDigit3;
                            tempWordDigit2 := tempWordDigit2;
                            tempWordDigit1 := tempWordDigit1;
                            tempWordDigit0 := tempWordDigit0;
                    end case;
                    
                    
                    --Store Variable into signals
                    wordDigit3 <= tempWordDigit3;
                    wordDigit2 <= tempWordDigit2;
                    wordDigit1 <= tempWordDigit1;
                    wordDigit0 <= tempWordDigit0;     
                        
                end if;    
                
                
            
            end if;
        end if;          
    end process;
end DataController_ARCH;
