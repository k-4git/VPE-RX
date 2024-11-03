library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity VpeProcessor is
    Port ( 
        vpeSerial : in STD_LOGIC;
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        frameStartEn : out STD_LOGIC;
        wordStartEn : out STD_LOGIC;
        t0Samples: out integer
    );
end VpeProcessor;

architecture VpeProcessor_ARCH of VpeProcessor is
    constant ACTIVE: std_logic := '1';
    
    -- Internal signals from vpeFilter
    signal vpeClean: std_logic;
    signal vpeTemp: integer;
    signal vpeWord: std_logic_vector(15 downto 0);
    signal vpeBit: integer;
    
    -- Internal signals from T0Sampler
    signal highValue : integer;
    signal lowValue: integer;
    signal calculateEn: std_logic;
    signal frameSignal: integer;
    signal wordSignalMin: integer;
    signal wordSignalPlus: integer;
    signal lastLowSignal: integer;
    signal lastHighSignal: integer;

begin
    -- Original vpeFilter process
    noiseFilter: process (clock, reset)
    variable vpeSixteen: std_logic_vector(15 downto 0);
    variable vpeBalance: integer range 0 to 15 := 0;
    variable shiftBit: integer range 0 to 1;
    begin
        if(reset = ACTIVE) then
            vpeClean <= not ACTIVE;
            vpeSixteen := (others => '0');
        elsif(rising_edge (clock)) then
            if(vpeSixteen(15) = ACTIVE) then                                            
                shiftBit := 1;                                                          
            else
                shiftBit := 0;
            end if;
            
            vpeBalance := vpeBalance - shiftBit;                                        
            vpeSixteen := vpeSixteen(14 downto 0) & vpeSerial;                         
            
            if(vpeSerial = ACTIVE) then                                                 
                vpeBalance := vpeBalance + 1;
            end if;
            
            vpeTemp <= vpeBalance; 
            vpeWord <= vpeSixteen;
            vpeBit <= shiftBit;  
            
            if(vpeBalance > 11) then                                                    
                vpeClean <= ACTIVE;
            else
                vpeClean <= not ACTIVE;
            end if;
        end if;
    end process;

    -- Original T0Sampler SAMPLE_COUNTER process
    SAMPLE_COUNTER: process(clock, reset)
    variable lastVpe: std_logic := not ACTIVE;
    variable lastLow: integer;
    variable lasthigh: integer;
    begin
        if(reset = ACTIVE) then
            highValue <= 0;
            lowValue <= 0;
        elsif(rising_edge (clock)) then
            if(vpeClean = ACTIVE) then
                if(vpeClean = not lastVpe) then
                    lastHigh := highValue;
                    highValue <= 0;
                    lastVpe := ACTIVE;
                else
                    highValue <= highValue + 1;
                end if;
            
            elsif(vpeClean = not ACTIVE) then
                if(vpeClean = lastVpe) then
                    lowValue <= lowValue + 1;
                    calculateEn <= not ACTIVE;
                else
                    lastLow:= lowValue;
                    lowValue <= 0;
                    calculateEn <= ACTIVE;
                    lastVpe := not ACTIVE;
                end if;
            end if;
            lastLowSignal <= lastLow;
            lastHighSignal <= lastHigh;
        end if;
    end process;
    
    -- Original T0Sampler CALCULATE_T0 process
    CALCULATE_T0: process(clock, reset)
    variable highBit: std_logic_vector(31 downto 0);
    variable lowBit: std_logic_vector(31 downto 0);
    
    variable t0FOURx: std_logic_vector(31 downto 0);
    variable t0TWOx: std_logic_vector(31 downto 0);

    variable t0FOURv: std_logic_vector(31 downto 0);
    variable t0TWOv: std_logic_vector(31 downto 0);

    variable bufferSIXTEEN: std_logic_vector(31 downto 0);
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
                
                t0FOURv := "0" & highBit(31 downto 1);
                t0TWOv := "00" & highBit(31 downto 2);

                --Create 16% buffer by x/6
                bufferSIXTEEN := std_logic_vector(unsigned(t0FOURv) + unsigned(t0TWOv));
                
                --Add highBit 4x and 2x to create 6x or frameTresh
                frameThresh := std_logic_vector(unsigned(t0FOURx) + unsigned(t0TWOx));
                
                --adjust word and frame Thresholds
                adjustWordMin := std_logic_vector(unsigned(highBit) - unsigned(bufferSIXTEEN));
                adjustWordPlus := std_logic_vector(unsigned(highBit) + unsigned(bufferSIXTEEN));
                adjustFrame := std_logic_vector(unsigned(frameThresh) - unsigned(bufferSIXTEEN));
                
                
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

end VpeProcessor_ARCH;