library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxDecoder is
    port (
        clock       : in std_logic;
        reset       : in std_logic;
        vpeClean    : in std_logic;
        t0En        : in std_logic;
        t0Sample    : in integer;
        idleEn      : out std_logic;
        rxOut       : out std_logic_vector(31 downto 0)
    );
end entity RxDecoder;

architecture behavioral of RxDecoder is
    constant ACTIVE : std_logic := '1';
    -- Synchronization chains
    signal vpeClean_sync1 : std_logic;
    signal vpeClean_sync2 : std_logic;
    signal t0En_sync1     : std_logic;
    signal t0En_sync2     : std_logic;

    --PulseCounter Signals--
    signal rxWord  : std_logic_vector(6 downto 0); -- Stores assembled frame
    signal t0Prev   : std_logic;                    -- Previous t0En for edge detection
    signal dataReady: std_logic;
    
    --Decoder Signals--
    signal nibbleReady : std_logic := '0';
    signal rxNibble    : std_logic_vector(3 downto 0) := (others => '0');
    
    --DataRegister Signals--
    signal rxOut_sig: std_logic_vector(31 downto 0); 

    --+++=========functions========+++--
    -- Decodes 7-bit input to 4-bit output according to encoding scheme
    function decode_7to4 (input : std_logic_vector(6 downto 0)) return std_logic_vector is
        begin
            case input is
                -- Mapping of 7-bit codes to 4-bit values (0-F)
                when "1111011" => return "0000"; when "1111001" => return "0001"; when "1110111" => return "0010";
                when "1110011" => return "0011"; when "1110001" => return "0100"; when "1110111" => return "0101";
                when "1100111" => return "0110"; when "1100011" => return "0111"; when "1100001" => return "1000";
                when "1011111" => return "1001"; when "1001111" => return "1010"; when "1000111" => return "1011";
                when "1000011" => return "1100"; when "1000001" => return "1101"; when "0111111" => return "1110";
                when "0011111" => return "1111"; when others => return "XXXX";    -- Invalid input returns XXXX
            end case;
        end function;

    -- Checks if input matches any valid 7-bit code
    function is_valid_input(input : std_logic_vector(6 downto 0)) return boolean is
        begin
            return (input = "1111011" or input = "1111001" or input = "1110111" or
                    input = "1110011" or input = "1110001" or input = "1110111" or
                    input = "1100111" or input = "1100011" or input = "1100001" or
                    input = "1011111" or input = "1001111" or input = "1000111" or
                    input = "1000011" or input = "1000001" or input = "0111111" or
                    input = "0011111");
        end function;

begin

    PULSECOUNTER: process (clock, reset)
    variable rxWord_var: std_logic_vector(6 downto 0);  -- Shift register for frame assembly
    variable t0Sample_prev: integer := 0;  -- Previous value of t0Sample
    begin
        if reset = ACTIVE then
            rxWord <= (others => '1');
            rxWord_var := (others => '1');
            t0Sample_prev := t0Sample;
            
        elsif rising_edge(clock) then
            dataReady <= not ACTIVE;          
            
            -- Reset rxWord when t0Sample changes
            if t0Sample /= t0Sample_prev then
                rxWord <= (others => '1');
                rxWord_var := (others => '1');
            end if;
            
            -- Sample on rising edge of synchronized t0En
            if t0En = ACTIVE and t0prev = '0' then              
                -- Check for frame completion (vpeClean=0 and LSB=1)
                if vpeClean = '0' and rxWord_var(0) = '1' then
                    rxWord <= rxWord_var;        -- Save completed frame
                    rxWord_var := "1111111";     -- Reset shift register
                    dataReady <= ACTIVE;         -- Signal frame complete
                -- Add specific check for all zeros pattern
                elsif rxWord_var = "0000000" then
                    rxWord <= rxWord_var;        -- Save all zeros frame
                    rxWord_var := "1111111";     -- Reset shift register
                    dataReady <= ACTIVE;         -- Signal frame complete
                end if;
                -- Shift in new bit
                rxWord_var := rxWord_var(5 downto 0) & vpeClean;
            end if;            
          
            t0Prev <= t0En;
            t0Sample_prev := t0Sample;  -- Update previous value
        end if;    
    end process;

    DECODER: process (clock, reset)
    variable nibbleReady_var : std_logic := '0';
    variable rxNibble_var : std_logic_vector(3 downto 0) := (others => '0');
    variable idleEn_var   : std_logic := '0';
    begin
        if reset = ACTIVE then
            -- Reset all outputs
            rxNibble_var := (others => '0');
            nibbleReady_var := '0';
            idleEn <= not ACTIVE;
            idleEn_var := not ACTIVE;
    
        elsif rising_edge(clock) then
            -- Default state - ensure idleEn goes low after one cycle
            idleEn_var := not ACTIVE;
            nibbleReady_var := not ACTIVE;
    
            if dataReady = ACTIVE then
                if rxWord = "0000000" then
                    -- Set idleEn for just this clock cycle
                    idleEn_var := ACTIVE;
                elsif is_valid_input(rxWord) then
                    -- Process valid input data
                    rxNibble_var := decode_7to4(rxWord);
                    nibbleReady_var := ACTIVE;
                end if;
            end if;
    
            -- Update outputs
            idleEn <= idleEn_var;
            rxNibble <= rxNibble_var;
            nibbleReady <= nibbleReady_var;
        end if;
    end process;
    
    DATA_OUT: process (clock, reset)
    -- Tracks received nibbles (0-8)
    variable nibbleCnt: integer := 0;
    -- Builds 32-bit word as nibbles arrive
    variable rxOut_var: std_logic_vector(31 downto 0);
    begin
        if reset = ACTIVE then
            nibbleCnt := 0;
            rxOut_var := (others => '0');
            rxOut_sig <= (others => '0'); 
            
        elsif rising_edge(clock) then
            if nibbleCnt = 8 then
                rxOut_sig <= rxOut_var;
                nibbleCnt := 0;  
                rxOut_var := (others => '0');  
            else
                if nibbleReady = ACTIVE then
                    -- Build word from right to left, MSB will be first nibble received
                    rxOut_var := rxOut_var(27 downto 0) & rxNibble;
                    nibbleCnt := nibbleCnt + 1;
                end if;
            end if;
        end if;
        RxOut <= rxOut_sig;
    end process;

end architecture;