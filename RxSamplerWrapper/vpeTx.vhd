library ieee; 
use ieee.std_logic_1164.all; 

----------------------------------------------------------------------------------
--* Name: Sean Graham
--* Class: CPE4490/01
--* Term: Fall 2024
--* Instructor: Dr. Scott Tippens
--* VpeTransmitter
--*     Creates a VPE transmitter for implementation on hardware.
--*     Transmitter resets to idle.
--*    
--*     When idle, seting txMode high begins a new transmission frame.
--*     At the beginning of a frame, data is latched internally.
--*
--*     Once transmission begins, it cannot be interrupted until the last pulse.
--*     
--*     On the last pulse, wordEndEn is high for the first clock cycle.
--*     Bringing txMode low will end the transmission frame, and return to idle,
--*     Otherwise if the pulse ends, will load new data and repeat.
--*     
--*     Serial output only advances on t0En.
---------------------------------------------------------------------------------- 
 
entity VpeTransmitter is 
    generic( 
        N: positive := 32 
    ); 
    port( 
        reset: in std_logic; 
        clock: in std_logic; 
         
        txMode: in std_logic; 
        t0En: in std_logic; 
        data: in std_logic_vector( N-1 downto 0 ); 
         
        vpeSerial: out std_logic; 
        wordEndEn: out std_logic 
    ); 
end entity; 
 
architecture VpeTransmitter_ARCH of VpeTransmitter is 
    ------------------------------------------------------------------- CONSTANTS -- 
    constant ACTIVE: std_logic := '1'; 
    constant NO_DATA: std_logic_vector(N downto 0) := ( N => '1', others => '0' ); 
     
    ------------------------------------------------------------------------ TYPES -- 
    type t_TX_STATES is (IDLE, SEND, SEND_LAST, FINISH); 
     
    ---------------------------------------------------------------- VPE ENCODINGS -- 
    constant VPE_IDLE       : std_logic_vector(6 downto 0) := "0000000"; 
    constant VPE_WORDSTART  : std_logic_vector(6 downto 0) := "0100000"; 
    constant VPE_0          : std_logic_vector(6 downto 0) := "0110000"; 
    constant VPE_1          : std_logic_vector(6 downto 0) := "0010000"; 
    constant VPE_2          : std_logic_vector(6 downto 0) := "0111000"; 
    constant VPE_3          : std_logic_vector(6 downto 0) := "0011000"; 
    constant VPE_4          : std_logic_vector(6 downto 0) := "0001000"; 
    constant VPE_5          : std_logic_vector(6 downto 0) := "0111100"; 
    constant VPE_6          : std_logic_vector(6 downto 0) := "0011100"; 
    constant VPE_7          : std_logic_vector(6 downto 0) := "0001100"; 
    constant VPE_8          : std_logic_vector(6 downto 0) := "0000100"; 
    constant VPE_9          : std_logic_vector(6 downto 0) := "0111110"; 
    constant VPE_10         : std_logic_vector(6 downto 0) := "0011110"; 
    constant VPE_11         : std_logic_vector(6 downto 0) := "0001110"; 
    constant VPE_12         : std_logic_vector(6 downto 0) := "0000110"; 
    constant VPE_13         : std_logic_vector(6 downto 0) := "0000010"; 
    constant VPE_14         : std_logic_vector(6 downto 0) := "0111111"; 
    constant VPE_15         : std_logic_vector(6 downto 0) := "0011111"; 
    constant VPE_NEGATIVE   : std_logic_vector(6 downto 0) := "0001111"; -- unused 
    constant VPE_RESERVED1  : std_logic_vector(6 downto 0) := "0000111"; -- unused 
    constant VPE_RESERVED2  : std_logic_vector(6 downto 0) := "0000011"; -- unused 
    constant VPE_FRAMESTART : std_logic_vector(6 downto 0) := "0000001"; 
     
    ---------------------------------------------------------------------- SIGNALS -- 
    -- state 
    signal txState: t_TX_STATES; 
     
    signal idleMode: std_logic; 
    signal frameStartEn: std_logic; 
    signal wordStartEn: std_logic; 
     
    -- data shift 
    signal dataLoadEn: std_logic; 
    signal nextNibble: std_logic_vector(3 downto 0); 
    signal lastNibbleMode: std_logic; 
     
    -- pulse encode 
    signal nextPulse: std_logic_vector(6 downto 0); 
     
    -- pulse transmit 
    signal pulseStartEn: std_logic; 
begin 
    -- state machine; see diagram for details 
    TX_CONTROL: process(reset, clock) is 
    begin 
        if reset = ACTIVE then 
            -- reset to idle 
            txState <= IDLE; 
             
            idleMode      <= ACTIVE; 
            frameStartEn  <= not ACTIVE; 
            wordStartEn   <= not ACTIVE; 
            wordEndEn     <= not ACTIVE; 
        elsif rising_edge(clock) then 
            -- set defaults 
            idleMode      <= not ACTIVE; 
            frameStartEn  <= not ACTIVE; 
            wordStartEn   <= not ACTIVE; 
            wordEndEn     <= not ACTIVE; 
             
            -- set outputs and check for any transitions 
            case txState is 
                when IDLE => 
                    -- between frames, no data should be transmitted 
                    idleMode <= ACTIVE; 
                     
                    -- start sending data as soon as transmission starts 
                    if txMode = ACTIVE then 
                        frameStartEn <= ACTIVE; 
                        txState <= SEND; 
                    end if; 
                when SEND => 
                    -- transmit all* nibbles of a word continuously 
                    -- transition at the beginning of the last pulse in the word 
                    if (lastNibbleMode = ACTIVE) and (pulseStartEn = ACTIVE) then 
                        wordEndEn <= ACTIVE; 
                        txState <= SEND_LAST; 
                    end if; 
                when SEND_LAST => 
                    -- give user chance to end frame on last nibble 
                    -- if txMode is ever low, immediately end frame 
                    if txMode /= ACTIVE then 
                        txState <= FINISH; 
                         
                    -- otherwise, after the pulse, start next word 
                    elsif pulseStartEn = ACTIVE then 
                        wordStartEn <= ACTIVE; 
                        txState <= SEND; 
                    end if; 
                when FINISH => 
                    -- frame has ended, finish the current pulse 
                    -- return to idle after the pulse 
                    if pulseStartEn = ACTIVE then 
                        txState <= IDLE; 
                    end if; 
            end case; 
        end if; 
    end process; 
     
    -- load new data on frame start and word start 
    dataLoadEn <= frameStartEn or wordStartEn; 
     
    -- latch the current word of data, shifting it out one nibble at a time until empty 
    DATA_SHIFT: process(reset, clock) is 
        variable dataRemaining: std_logic_vector(N downto 0); 
    begin 
        if reset = ACTIVE then 
            -- reset to idle 
            dataRemaining := (others => '0'); 
        elsif rising_edge(clock) then 
            if dataLoadEn = ACTIVE then 
                -- load data, with trailing 1 to mark end of word 
                dataRemaining := data & '1'; 
                 
                -- shift out all leading zeros, (max of 7 times for 32 bits) 
                for i in 0 to (N/4 - 2) loop 
                    if dataRemaining(N downto N-3) = "0000" then 
                        dataRemaining := dataRemaining(N-4 downto 0) & "0000"; 
                    end if; 
                end loop; 
            elsif pulseStartEn = ACTIVE then 
                if dataRemaining = NO_DATA then 
                    -- no data; hold idle 
                    lastNibbleMode <= not ACTIVE; 
                else 
                    -- shift out the rightmost nibble 
                    nextNibble <= dataRemaining(N downto N-3); 
                    dataRemaining := dataRemaining(N-4 downto 0) & "0000"; 
                     
                    -- check for end of data 
                    if dataRemaining = NO_DATA then 
                        lastNibbleMode <= ACTIVE; 
                    else 
                        lastNibbleMode <= not ACTIVE; 
                    end if; 
                end if; 
            end if; 
        end if; 
    end process; 
     
    -- convert the next data nibble into a pulse 
    PULSE_ENCODE: process(nextNibble) is 
    begin 
        case nextNibble is 
            when "0000" => 
                nextPulse <= VPE_0; 
            when "0001" => 
                nextPulse <= VPE_1; 
            when "0010" => 
                nextPulse <= VPE_2; 
            when "0011" => 
                nextPulse <= VPE_3; 
            when "0100" => 
                nextPulse <= VPE_4; 
            when "0101" => 
                nextPulse <= VPE_5; 
            when "0110" => 
                nextPulse <= VPE_6; 
            when "0111" => 
                nextPulse <= VPE_7; 
            when "1000" => 
                nextPulse <= VPE_8; 
            when "1001" => 
                nextPulse <= VPE_9; 
            when "1010" => 
                nextPulse <= VPE_10; 
            when "1011" => 
                nextPulse <= VPE_11; 
            when "1100" => 
                nextPulse <= VPE_12; 
            when "1101" => 
                nextPulse <= VPE_13; 
            when "1110" => 
                nextPulse <= VPE_14; 
            when "1111" => 
                nextPulse <= VPE_15; 
            when others => 
                -- not sure this will synthesize, but its good for sim 
                nextPulse <= (others => 'X'); 
        end case; 
    end process; 
     
    -- send next encoded data or control pulse as a serial output 
    -- note: currentPulse logic could probably be moved to its own block 
    PULSE_TRANSMIT: process(reset, clock) is 
        variable currentPulse: std_logic_vector(nextPulse'range); 
    begin 
        if reset = ACTIVE then 
            -- reset to idle 
            vpeSerial <= not ACTIVE; 
            pulseStartEn <= not ACTIVE; 
        elsif rising_edge(clock) then 
            -- set default 
            pulseStartEn <= not ACTIVE; 
             
            if frameStartEn = ACTIVE then 
                -- load frame start 
                currentPulse := VPE_FRAMESTART; 
                pulseStartEn <= ACTIVE; 
            elsif wordStartEn = ACTIVE then 
                -- load word start 
                currentPulse := VPE_WORDSTART; 
                pulseStartEn <= ACTIVE; 
            elsif idleMode = ACTIVE then 
                -- don't load data when idle 
                currentPulse := VPE_IDLE; 
                pulseStartEn <= ACTIVE; 
            end if; 
             
            if t0En = ACTIVE then 
                -- shift out next pulse 
                vpeSerial <= currentPulse(6); 
                currentPulse := currentPulse(5 downto 0) & '0'; 
             
                if currentPulse = VPE_IDLE then 
                    -- when pulse done, load next data pulse 
                    currentPulse := nextPulse; 
                    pulseStartEn <= ACTIVE; 
                end if; 
            end if; 
        end if; 
    end process; 
end architecture; 