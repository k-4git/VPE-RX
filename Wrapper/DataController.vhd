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


   signal LIVEselectedArray: std_logic_vector(63 downto 0);
    signal LIVEselectedSwitches: std_logic_vector(3 downto 0);
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
        
            
        --sif endFrame is ACTIVE, change frame Arrays
        if(endFrame = ACTIVE) then
            frameCounter := frameCounter + 1;
            wordCounter := 0;
        end if;
        
        --Insert frameCounter's Array into currentFrame
        currentFrame := dataArray(frameCounter);
        
        --Insert rxOut into 16-bit variable
        currentWord := rxOut;
    
        --If newWord is ACTIVE, increase wordCounter by 1
        if(newWord = ACTIVE) then
            --If wordCounter is not at the end, insert currentWord from the right.
            if(wordCounter < 4) then
                dataArray(frameCounter) := currentFrame(47 downto 0) & currentWord;
                wordCounter := wordCounter + 1;
            end if;
        end if;
        
        --Stores data Arrays into seperate frame signals for view.
        frameONE <= dataArray(0);
        frameTWO <= dataArray(1);
        frameTHREE <= dataArray(2);
        frameFOUR <= dataArray(3);
    end if;

    end process;    
    LED_SWITCH_DISPLAY: process(clock, reset)
    -- Local variables for frame processing
    variable selectedArray: std_logic_vector(63 downto 0) := (others => '0');
    variable selectedSwitches: std_logic_vector(3 downto 0) := (others => '0');
    
    -- Variables for seven segment display
    variable tempWordDigit3: std_logic_vector(3 downto 0) := (others => '0');
    variable tempWordDigit2: std_logic_vector(3 downto 0) := (others => '0');
    variable tempWordDigit1: std_logic_vector(3 downto 0) := (others => '0');
    variable tempWordDigit0: std_logic_vector(3 downto 0) := (others => '0');
    
    -- LED status variables
    variable tempLeds: std_logic_vector(15 downto 0) := (others => '0');

    begin
        if reset = ACTIVE then
            -- Reset all outputs
            wordDigit3 <= (others => '0');
            wordDigit2 <= (others => '0');
            wordDigit1 <= (others => '0');
            wordDigit0 <= (others => '0');
            leds <= (others => '0');
            
        elsif rising_edge(clock) then
            if modeSwitch = ACTIVE then
                -- Check Frame ONE status
                if( frameONE(63 downto 48) /= x"0000" and frameONE(47 downto 0) = x"000000000000") then
                    tempLeds(15) := '1'; 
                end if;
                if(frameONE(47 downto 32) /= x"0000" and (frameONE(63 downto 48) & frameOne(31 downto 0)) = x"000000000000") then
                    tempLeds(14) := '1';
                end if;
                if(frameONE(31 downto 16) /= x"0000" and (frameONE(63 downto 32) & frameOne(15 downto 0)) = x"000000000000") then
                    tempLeds(13) := '1';
                end if;
                if(frameONE(15 downto 0) /= x"0000" and frameONE(63 downto 16) = x"000000000000") then
                    tempLeds(12) := '1';
                end if;
                
                -- Frame TWO (LEDs 11-8)
                if( frameTWO(63 downto 48) /= x"0000" and frameTWO(47 downto 0) = x"000000000000") then
                    tempLeds(11) := '1'; 
                end if;
                if(frameTWO(47 downto 32) /= x"0000" and (frameTWO(63 downto 48) & frameTWO(31 downto 0)) = x"000000000000") then
                    tempLeds(10) := '1';
                end if;
                if(frameTWO(31 downto 16) /= x"0000" and (frameTWO(63 downto 32) & frameTWO(15 downto 0)) = x"000000000000") then
                    tempLeds(9) := '1';
                end if;
                if(frameTWO(15 downto 0) /= x"0000" and frameTWO(63 downto 16) = x"000000000000") then
                    tempLeds(8) := '1';
                end if;
                
                -- Frame THREE (LEDs 7-4)
                if( frameTHREE(63 downto 48) /= x"0000" and frameTHREE(47 downto 0) = x"000000000000") then
                    tempLeds(11) := '1'; 
                end if;
                if(frameTHREE(47 downto 32) /= x"0000" and (frameTHREE(63 downto 48) & frameTHREE(31 downto 0)) = x"000000000000") then
                    tempLeds(10) := '1';
                end if;
                if(frameTHREE(31 downto 16) /= x"0000" and (frameTHREE(63 downto 32) & frameTHREE(15 downto 0)) = x"000000000000") then
                    tempLeds(9) := '1';
                end if;
                if(frameTHREE(15 downto 0) /= x"0000" and frameTHREE(63 downto 16) = x"000000000000") then
                    tempLeds(8) := '1';
                end if;
                
                -- Frame FOUR (LEDs 3-0)
                if( frameFOUR(63 downto 48) /= x"0000" and frameFOUR(47 downto 0) = x"000000000000") then
                    tempLeds(11) := '1'; 
                end if;
                if(frameFOUR(47 downto 32) /= x"0000" and (frameFOUR(63 downto 48) & frameFOUR(31 downto 0)) = x"000000000000") then
                    tempLeds(10) := '1';
                end if;
                if(frameFOUR(31 downto 16) /= x"0000" and (frameFOUR(63 downto 32) & frameFOUR(15 downto 0)) = x"000000000000") then
                    tempLeds(9) := '1';
                end if;
                if(frameFOUR(15 downto 0) /= x"0000" and frameFOUR(63 downto 16) = x"000000000000") then
                    tempLeds(8) := '1';
                end if;
    
                leds <= tempLeds;
    
                -- Handle seven segment display when deButton is pressed
                if deButton = ACTIVE then
                    -- Frame selection based on switch position
                    if switches(15 downto 12) /= "0000" and switches(11 downto 0) = x"000" then
                        selectedArray := frameONE;
                        selectedSwitches := switches(15 downto 12);
                    elsif switches(11 downto 8) /= "0000" and switches(15 downto 12) = "0000" and switches(7 downto 0) = x"00" then
                        selectedArray := frameTWO;
                        selectedSwitches := switches(11 downto 8);
                    elsif switches(7 downto 4) /= "0000" and switches(15 downto 8) = x"00" and switches(3 downto 0) = "0000" then
                        selectedArray := frameTHREE;
                        selectedSwitches := switches(7 downto 4);
                    elsif switches(3 downto 0) /= "0000" and switches(15 downto 4) = x"000" then
                        selectedArray := frameFOUR;
                        selectedSwitches := switches(3 downto 0);
                    end if;
    
                    -- Word selection within selected frame
                    case selectedSwitches is
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
                            null;
                    end case;
    
                    -- Update seven segment display outputs
                    wordDigit3 <= tempWordDigit3;
                    wordDigit2 <= tempWordDigit2;
                    wordDigit1 <= tempWordDigit1;
                    wordDigit0 <= tempWordDigit0;
                end if;
            end if;
        end if;
    end process;
   
end DataController_ARCH;
