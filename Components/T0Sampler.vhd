----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/28/2024 04:02:10 PM
-- Design Name: 
-- Module Name: T0Sampler - T0Sampler_ARCH
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity T0Sampler is
        
    Port ( vpeClean : in STD_LOGIC;
           frameStartEn : out STD_LOGIC;
           wordStartEn : out STD_LOGIC;
           t0Samples: out integer;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC);
end T0Sampler;

architecture T0Sampler_ARCH of T0Sampler is

constant ACTIVE: std_logic := '1';

type sample_t is (LOWCOUNT, HIGHCOUNT, CALCULATE, TIMERESET);

signal lowTime: std_logic_vector(31 downto 0);
signal highTime: std_logic_vector(31 downto 0);

signal t0Sampled: std_logic_vector(31 downto 0);

signal SampleState: sample_t;

signal lowCountEn: std_logic;
signal highCountEn: std_logic;
signal timeResetEn: std_logic;
signal resultEn: std_logic;
signal calculateEn: std_logic;

begin

    
        
    SAMPLE_CONTROLLER: process(clock, reset)
    
    variable edgeFlag: std_logic := ACTIVE;
    
    begin
        if(reset = ACTIVE) then
            frameStartEn <= not ACTIVE;
            wordStartEn <= not ACTIVE;
            timeResetEn <= not ACTIVE;
        elsif(rising_edge (clock)) then
            
            case (SampleState) is
            
            --LOWCOUNT State, Will count in Background until vpeClean goes HIGH
            --Afterward, will send lowCountEn to stop count and Transition into HIGHCOUNT
            when LOWCOUNT =>
            
                timeResetEn <= not ACTIVE;
                
                if(vpeClean = not edgeFlag) then
                    sampleState <= HIGHCOUNT;
                    lowCountEn <= not ACTIVE;
                    highCountEn <= ACTIVE;
                end if;
            
            --HIGHCOUNT, will count in Background after vpeClean goes HIGH
            --Will send highCountEn to stop count when vpeClean goes low and transition
            --into CALCULATE
            when HIGHCOUNT =>
                
                if(vpeClean = not edgeFlag) then
                    sampleState <= CALCULATE;
                    highCountEn <= not ACTIVE;
                    calculateEn <= ACTIVE;
                end if;
                
            --will calculate t0 and receive t0PushEn when done, transitions back into LOWCOUNT
            when CALCULATE =>
                if(resultEn = ACTIVE) then
                    sampleState <= TIMERESET;
                end if;
                
            --Resets the values of lowTime and highTime, while setting lowCountEn back to HIGH
            when TIMERESET =>
                resultEn <= not ACTIVE;
                timeResetEn <= ACTIVE;
                lowCountEn <= ACTIVE;
                sampleState <= LOWCOUNT;
                edgeFlag := ACTIVE;
            end case;
        end if;
    end process;
    
    LOW_COUNT: process(clock, reset)
    
    variable lowCount: std_logic_vector(31 downto 0);
    
    begin
        if(reset = ACTIVE) then
            lowTime <= (others => '0');
        elsif(rising_edge (clock)) then
            if(lowCountEn = ACTIVE) then
                if(timeResetEn = ACTIVE) then
                    lowCount := (others => '0');
                else
                    lowCount := std_logic_vector(unsigned(lowCount) + 1);
                end if;
            else     
                lowTime <= lowCount;
            end if;          
        end if;
    end process;
    
    HIGH_COUNT: process(clock, reset)
    
    variable highCount: std_logic_vector(31 downto 0);
    
    begin
        if(reset = ACTIVE) then
            highTime <= (others => '0');
            
        elsif(rising_edge (clock)) then
        
            if(highCountEn = ACTIVE) then
            
                if(timeResetEn = ACTIVE) then
                    highCount := (others => '0');
                    
                else
                    highCount := std_logic_vector(unsigned(highCount) + 1);
                end if;
                
            else     
                highTime <= highCount;
            end if; 
        end if;
    end process;
    
    CALCULATE_T0: process(clock,reset)
    variable frameFOURx: std_logic_vector(31 downto 0) := (others => '0');
    variable frameTWOx: std_logic_vector(31 downto 0) := (others => '0');
    variable frameThresh: std_logic_vector(31 downto 0) := (others => '0');
    
    variable highTemp: std_logic_vector(31 downto 0) := (others => '0');
    variable lowTemp: std_logic_vector(31 downto 0) := (others => '0');
    
    variable highBuffer: std_logic_vector(31 downto 0) := (others => '0');
    
    variable adjustWordPlus: std_logic_vector(31 downto 0) := (others => '0');
    variable adjustWordMin: std_logic_vector(31 downto 0) := (others => '0');
    variable adjustFrame: std_logic_vector(31 downto 0) := (others => '0');
    
    begin
        if(reset = ACTIVE) then
            frameStartEn <= not ACTIVE;
            wordStartEn <= not ACTIVE;
            t0Samples <= 0;
            resultEn <= not ACTIVE;
        elsif(rising_edge (clock)) then       
            lowTemp := lowTime;
            highTemp := highTime;
            
            highBuffer := "000" & highTemp(28 downto 0);
            
            frameFOURx := (highTemp(29 downto 0) & "00");
            frameTWOx := (highTemp(30 downto 0) & '0');
            frameThresh :=  std_logic_vector(unsigned(frameFOURx) + unsigned(frameTWOx));
            
            adjustFrame :=  std_logic_vector(unsigned(frameThresh) - unsigned(highBuffer));
            
            adjustWordPlus := std_logic_vector(unsigned(highTemp) + unsigned(highBuffer));
            adjustWordMin := std_logic_vector(unsigned(highTemp) - unsigned(highBuffer));
            
            if(lowTemp >= adjustFrame) then
                frameStartEn <= ACTIVE;
                
            elsif(lowTemp <= adjustWordPlus and lowTemp >= adjustWordMin) then
                wordStartEn <= ACTIVE;
                
            else    
                frameStartEn <= not ACTIVE;
                wordStartEn <= not ACTIVE;
            end if;
            t0Samples <= to_integer(unsigned(highTemp));
            resultEn <= ACTIVE;
        end if;
    end process;
    
    
end T0Sampler_ARCH;
