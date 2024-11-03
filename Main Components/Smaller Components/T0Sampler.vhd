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

signal highValue : integer;
signal lowValue: integer;
signal calculateEn: std_logic;

signal frameSignal: integer;
signal wordSignalMin: integer;
signal wordSignalPlus: integer;

signal lastLowSignal: integer;
signal lastHighSignal: integer;

begin
    
    SAMPLE_COUNTER: process(clock, reset)
    variable lastVpe: std_logic := not ACTIVE;
    variable lastLow: integer;
    variable lasthigh: integer;
    begin
        if(reset = ACTIVE) then
            highValue <= 0;
            lowValue <= 0;
        elsif(rising_edge (clock)) then
        
            --if vpeClean is HIGH,
            if(vpeClean = ACTIVE) then
            
                --If vpeClean is rising, then set highValue to 0
                if(vpeClean = not lastVpe) then
                    lastHigh := highValue;
                    highValue <= 0;
                    lastVpe := ACTIVE;
                else
                    --Increment highValue by 1
                    highValue <= highValue + 1;
                end if;
            
            --If vpeClean is LOW    
            elsif(vpeClean = not ACTIVE) then
                
                --If vpeClean is not falling
                if(vpeClean = lastVpe) then
                    --Incrememnt lowValue and set calculateEn to LOW
                    lowValue <= lowValue + 1;
                    calculateEn <= not ACTIVE;
                    
                    
                else
                    lastLow:= lowValue;
                    --Else, set lowValue to 0 and set calculateEn to HIGH
                    lowValue <= 0;
                    calculateEn <= ACTIVE;
                    lastVpe := not ACTIVE;
                end if;
                          
            end if;
            lastLowSignal <= lastLow;
            lastHighSignal <= lastHigh;
        end if;
    end process;
    
    CALCULATE_T0: process(clock, reset)
    variable highBit: std_logic_vector(31 downto 0);
    variable lowBit: std_logic_vector(31 downto 0);
    
    variable t0FOURx: std_logic_vector(31 downto 0);
    variable t0TWOx: std_logic_vector(31 downto 0);
    
    variable bufferTWELVE: std_logic_vector(31 downto 0);
    variable frameThresh: std_logic_vector(31 downto 0);
    
    variable adjustWordMin: std_logic_vector(31 downto 0);
    variable adjustWordPlus: std_logic_vector(31 downto 0);
    variable adjustFrame: std_logic_vector(31 downto 0);
    
    variable frameStart: std_logic;
    variable wordStart: std_logic;
    
    
    begin
    
        if(reset = ACTIVE) then
            wordStartEn <= not ACTIVE;
            frameStartEn <= not ACTIVE;
            t0Samples <= 0;
            
        elsif(rising_edge (clock)) then
            if(calculateEn = ACTIVE) then
                --Turn high and low Values to 32-Bit Words
                highBit := std_logic_vector(to_unsigned(lastHighSignal, 32));

                if(highBit(0) = '1') then
                    highBit := highBit(31 downto 1) & '0';
                end if;
                    
                lowBit := std_logic_vector(to_unsigned(lastLowSignal, 32));
                report "starting calculation with high, low being";
                report integer'image(highValue);
                report integer'image(lastLowSignal);
                --Shift highBit to create 4x and 2x
                t0FOURx := highBit(29 downto 0) & "00";
                t0TWOx := highBit(30 downto 0) & "0";
                
                --Create 12% buffer by x/8
                bufferTWELVE := "000" & highBit(31 downto 3);
                
                --Add highBit 4x and 2x to create 6x or frameTresh
                frameThresh := std_logic_vector(unsigned(t0FOURx) + unsigned(t0TWOx));
                
                --adjust word and frame Thresholds
                adjustWordMin := std_logic_vector(unsigned(highBit) - unsigned(bufferTWELVE));
                adjustWordPlus := std_logic_vector(unsigned(highBit) + unsigned(bufferTWELVE));
                adjustFrame := std_logic_vector(unsigned(frameThresh) - unsigned(bufferTWELVE));
                
                
                --If lowValue > adjustFrame, send frameStartEn
                report boolean'image(unsigned(lowBit) >= unsigned(adjustFrame));
                report boolean'image(unsigned(lowBit) <= unsigned(adjustWordPlus) and unsigned(lowBit) >= unsigned(adjustWordMin));
                if(unsigned(lowBit) >= unsigned(adjustFrame)) then
                    
                    frameStart := ACTIVE;
                    report "frame enabled";
                    --Store highValue into t0Samples
                    t0Samples <= highValue;
                    
                --Else If lowValue is between adjustWord +/-, send wordStartEn
                
                elsif(unsigned(lowBit) <= unsigned(adjustWordPlus) and unsigned(lowBit) >= unsigned(adjustWordMin)) then
                    
                    wordStart := ACTIVE;
                    report "word enabled";
                    --Store highValue into t0Samples
                    t0Samples <= highValue;
                
                --Else, set frame and word Start to LOW
                end if;
                
                
                
            else
                wordStart:= not ACTIVE;
                frameStart:= not ACTIVE;   
            end if;
            
                wordSignalPlus <= to_integer(unsigned(adjustWordPlus));
                wordSignalMin <= to_integer(unsigned(adjustWordMin));
                frameSignal <= to_integer(unsigned(adjustFrame));
                wordStartEn <= wordStart;
                frameStartEn <= frameStart;                  
        end if;
    end process;    
end T0Sampler_ARCH;
