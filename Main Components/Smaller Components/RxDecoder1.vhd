library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- RxDecoder: Decodes 7-bit encoded data into 4-bit nibbles
entity RxDecoder is
    port (
        clock       : in std_logic;                     -- System clock
        reset       : in std_logic;                     -- Asynchronous reset
        dataReady   : in std_logic;                     -- Input data valid signal
        rxWord      : in std_logic_vector(6 downto 0);  -- 7-bit encoded input data    
        idleEn      : out std_logic;                    -- Idle state indicator
        rxNibble    : out std_logic_vector(3 downto 0); -- Decoded 4-bit output
        nibbleReady : out std_logic                     -- Output data valid signal
    );
end entity RxDecoder;

architecture behavioral of RxDecoder is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';  -- Active state logic level

    --+++=========Signals========+++--
    signal rxWord_sig : std_logic_vector (6 downto 0);  -- Internal storage for input word

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
    
    -- Main decoder process - handles input decoding and control signals
    DECODER: process (clock, reset)
    variable nibbleReady_var : std_logic := '0';
    variable rxNibble_var : std_logic_vector(3 downto 0) := (others => '0');
    variable idleEn_var   : std_logic;
    begin
        if reset = ACTIVE then
            -- Reset all outputs
            rxNibble_var := (others => '0');
            nibbleReady_var := '0';
            idleEn <= not ACTIVE;

        elsif rising_edge(clock) then
            if rxWord = "0000000" then
                -- Detect idle condition
                idleEn_var := ACTIVE;
                
            elsif dataReady = ACTIVE and is_valid_input(rxWord) then
                -- Process valid input data
                rxNibble_var := decode_7to4(rxWord);
                nibbleReady_var := ACTIVE;
                idleEn_var := not ACTIVE;
            else
                -- Invalid or no input
                nibbleReady_var := not ACTIVE;
                idleEn_var := not ACTIVE;
            end if;
        end if;

        -- Update outputs
        idleEn <= idleEn_var;
        rxNibble <= rxNibble_var;
        nibbleReady <= nibbleReady_var;
    end process;

end architecture;