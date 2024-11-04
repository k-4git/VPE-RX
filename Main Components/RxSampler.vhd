library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxSampler is
    Port ( 
        -- VPE Processing inputs
        vpeSerial   : in STD_LOGIC;       -- Input VPE serial signal
        clock       : in STD_LOGIC;           -- System clock
        reset       : in STD_LOGIC;           -- Active high reset
        idleEn      : in STD_LOGIC;                
        newWord     : out STD_LOGIC;
        endFrame    : out STD_LOGIC;
        vpeClean    : out STD_LOGIC;
        t0Sample    : out integer;
        t0En        : out STD_LOGIC       -- T0 enable signal for sampling
        
    );
end RxSampler;

architecture RxSampler_ARCH of RxSampler is
    --CONSTANTS
    constant ACTIVE: std_logic := '1';
    
    --INTERNAL SIGNALS FOR FILTER DISPLAY
    signal vpeTemp: integer;
    signal vpeWord: std_logic_vector(15 downto 0);
    signal vpeBit: integer;
    
    --Internal connection between filter and sampler
    signal vpeClean_sig: std_logic;
    
    --INTERNAL SIGNALS FOR T0 SAMPLER
    signal highValue : integer;
    signal lowValue: integer;
    signal calculateEn: std_logic;
    
    signal frameSignal: integer;
    signal wordSignalMin: integer;
    signal wordSignalPlus: integer;
    
    signal lastLowSignal: integer;
    signal lastHighSignal: integer;
    
    -- Internal connections between T0 Sampler and Rx Controller
    signal frameStartEn : STD_LOGIC;
    signal wordStartEn : STD_LOGIC;
    
    --RxController Signals--
    -- Internal signals for T0 Generator
    signal t0GenMode : std_logic;
    signal sampleCount : integer := 0;
    signal genPulse : std_logic := '0';
    signal t0Samples : integer;
    
    --PulseCounter Signals--
    signal rxFrame  : std_logic_vector(6 downto 0); -- Stores assembled frame
    signal t0Prev   : std_logic;                    -- Previous t0En for edge detection
    
    --Create type and signal for state machine
    type state_t is (IDLE, SAMPLE);
    signal rx_State: state_t;
begin
    
    noiseFilter: process (clock, reset)
    --VARIABLES
    variable vpeSixteen: std_logic_vector(15 downto 0);
    variable vpeBalance: integer range 0 to 15 := 0;
    variable shiftBit: integer range 0 to 1;
    begin
        if(reset = ACTIVE) then
            vpeClean_sig <= not ACTIVE;
            vpeSixteen := (others => '0');
        elsif(rising_edge (clock)) then
            --Determines if leftmost bit is 1 or 0 and stores it
            --in shiftBit
            if(vpeSixteen(15) = ACTIVE) then                                            
                shiftBit := 1;                                                          
            else
                shiftBit := 0;
            end if;
            
            --Subtracts the Leftmost bit out from the Counter
            --Shifts vpeSerial into the Rightmost bit
            vpeBalance := vpeBalance - shiftBit;                                        
            vpeSixteen := vpeSixteen(14 downto 0) & vpeSerial;                         
            
            --If vpeSerial is Active, add to Counter
            if(vpeSerial = ACTIVE) then                                                 
                vpeBalance := vpeBalance + 1;
            end if;
            
            --DISPLAY INTERNAL SIGNALS
            vpeTemp <= vpeBalance; 
            vpeWord <= vpeSixteen;
            vpeBit <= shiftBit;  
            
            --If Counter is 3/4 of total length of buffer, Output HIGH
            if(vpeBalance > 11) then                                                    
                vpeClean_sig <= ACTIVE;
            else
                vpeClean_sig <= not ACTIVE;
            end if;
        end if;
        vpeClean <= vpeClean_sig;
    end process;

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
            if(vpeClean_sig = ACTIVE) then
            
                --If vpeClean is rising, then set highValue to 0
                if(vpeClean_sig = not lastVpe) then
                    lastHigh := highValue;
                    highValue <= 0;
                    lastVpe := ACTIVE;
                else
                    --Increment highValue by 1
                    highValue <= highValue + 1;
                end if;
            
            --If vpeClean is LOW    
            elsif(vpeClean_sig = not ACTIVE) then
                
                --If vpeClean is not falling
                if(vpeClean_sig = lastVpe) then
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

    variable t0FOURv: std_logic_vector(31 downto 0);
    variable t0TWOv: std_logic_vector(31 downto 0);

    variable bufferSIXTEEN: std_logic_vector(31 downto 0);
    variable frameThresh: std_logic_vector(31 downto 0);
    
    variable adjustWordMin: std_logic_vector(31 downto 0);
    variable adjustWordPlus: std_logic_vector(31 downto 0);
    variable adjustFrame: std_logic_vector(31 downto 0);
    
    variable frameStart: std_logic;
    variable wordStart: std_logic;
    variable adjustedHighValue: integer;
    variable frameT0: std_logic_vector(31 downto 0);
    variable t0ReinforceFlag: boolean;
    begin
    
        if(reset = ACTIVE) then
            wordStartEn <= not ACTIVE;
            frameStartEn <= not ACTIVE;
            t0Samples <= 0;
            
        elsif(rising_edge (clock)) then
            if(calculateEn = ACTIVE) then
                --Turn high and low Values to 32-Bit Words
                adjustedHighValue := highValue + 8;
                highBit := std_logic_vector(to_unsigned(adjustedHighValue, 32));
               
                if(highBit(0) = '1') then
                    highBit := highBit(31 downto 1) & '0';
                end if;
                    
                lowBit := std_logic_vector(to_unsigned(lastLowSignal, 32));
                --Shift highBit to create 4x and 2x
                t0FOURx := highBit(29 downto 0) & "00";
                t0TWOx := highBit(30 downto 0) & "0";
                
                t0FOURv := "000" & highBit(31 downto 3);
                t0TWOv := "0000" & highBit(31 downto 4);

                --Create 16% buffer by x/6
                bufferSIXTEEN := std_logic_vector(unsigned(t0FOURv) + unsigned(t0TWOv));
                
                --Add highBit 4x and 2x to create 6x or frameTresh
                frameThresh := std_logic_vector(unsigned(t0FOURx) + unsigned(t0TWOx));
                
                --adjust word and frame Thresholds
                
                adjustFrame := std_logic_vector(unsigned(frameThresh) - unsigned(bufferSIXTEEN));
                
                
                --If lowValue > adjustFrame, send frameStartEn
                if(unsigned(lowBit) >= unsigned(adjustFrame)) then
                    
                    frameStart := ACTIVE;
                    --Store highValue into t0Samples
                    t0Samples <= highValue +8;
                    
                    t0ReinforceFlag := true;
                    adjustWordMin := std_logic_vector(unsigned(highBit) - unsigned(bufferSIXTEEN));
                    adjustWordPlus := std_logic_vector(unsigned(highBit) + unsigned(bufferSIXTEEN));
             
                elsif(t0reinforceFlag = true) then
                    --If lowValue is between adjustWord +/-, send wordStartEn
                
                    if(unsigned(lowBit) < unsigned(adjustWordPlus) and unsigned(lowBit) > unsigned(adjustWordMin) 
			          and unsigned(highBit) < unsigned(adjustWordPlus) and unsigned(highBit) > unsigned(adjustWordMin)) then
                    
                        wordStart := ACTIVE;
                        --Store highValue into t0Samples
                        t0Samples <= highValue +8;

                    end if;   
                end if;
                
            --Else, set frame and word Start to LOW    
            else
                wordStart:= not ACTIVE;
                frameStart:= not ACTIVE;   
            end if;
            
                wordSignalPlus <= to_integer(unsigned(adjustWordPlus));
                wordSignalMin <= to_integer(unsigned(adjustWordMin));
                frameSignal <= to_integer(unsigned(adjustFrame));
                wordStartEn <= wordStart;
                frameStartEn <= frameStart;    
                t0Sample <= t0Samples;              
        end if;
    end process;     

    RX_CONTROLLER: process(clock, reset)
    begin
        if(reset = ACTIVE) then
        
            --If Reset, Set all Outputs to not ACTIVE,
            --set State back to IDLE
            newWord <= not ACTIVE;
            endFrame <= not ACTIVE;
            t0GenMode <= not ACTIVE;
            rx_State <= IDLE;
        elsif(rising_edge (clock)) then
            case (rx_State) is
                --No pulse being decoded or sampled
                when (IDLE) =>
                
                    --Sampling Mode Control Signal is off
                    t0GenMode <= not ACTIVE;
                    endFrame <= not ACTIVE;
                    newWord <= not ACTIVE;
                    
                    --If frameStart Pulse is detected
                    if(frameStartEn = ACTIVE) then
                    
                        --Enable Sampling Mode Signal and
                        --Change State to SAMPLE
                        t0GenMode <= ACTIVE;
                        rx_State <= SAMPLE;
                    end if;
                
                --SAMPLE State is to detect different control signals
                --and outputs different Flags       
                when (SAMPLE) =>
                    
                    --Keep tGenMode on
                    t0GenMode <= ACTIVE;
                    
                    --Initially, newWord and endFalg is not ACTIVE
                    newWord <= not ACTIVE;
                    endFrame <= not ACTIVE;     
                    
                    --If Decoder sees all 0s, go back to IDLE
                    if(idleEn = ACTIVE) then
                        rx_State <= IDLE;
                        endFrame <= ACTIVE;
                    --Else, if Frame is Detected, Keep Decoding
                    --and send endFrame
                    elsif(frameStartEn = ACTIVE) then
                        endFrame <= ACTIVE;
                    --Else, if Word is detected, Send WordFlag
                    elsif(wordStartEn = ACTIVE) then
                        newWord <= ACTIVE;
                    end if;
                    
                    -- Include when others for synthesis safety
                when others =>
                    rx_State <= IDLE;
                    t0GenMode <= not ACTIVE;
                    newWord <= not ACTIVE;
                    endFrame <= not ACTIVE;       
            end case; 
        end if;   
    end process;
    
-- State register
    t0GENERATE: process (clock, reset)
        variable genCounter : integer := 0;
    begin
        if reset = ACTIVE then
            genCounter := 0;
            t0En <= not ACTIVE;
        elsif rising_edge(clock) then
            if t0GenMode = ACTIVE and t0Samples > 0 then
                -- Generate single pulse at middle of bit period
                if genCounter = (t0Samples/2) then
                    t0En <= '1';
                else
                    t0En <= '0';
                end if;
                
                -- Counter management
                if genCounter >= t0Samples-1 then
                    genCounter := 0;
                else
                    genCounter := genCounter + 1;
                end if;
            else 
                t0En <= '0';
                genCounter := 0;
            end if;
        end if;
    end process;
    
end RxSampler_ARCH;