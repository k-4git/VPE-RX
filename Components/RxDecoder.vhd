library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxDecoder is
    port (
        clock     : in std_logic;
        reset     : in std_logic;
        dataReady : in std_logic;
        rxWord    : in std_logic_vector(6 downto 0);    
        idleEn    : out std_logic;
        rxNibble  : out std_logic_vector(3 downto 0);  
        nibbleReady: out std_logic
    );
end entity RxDecoder;

architecture behavioral of RxDecoder is
    --+++=========Constants========+++--
    constant ACTIVE : std_logic := '1';
    --+++=========Signals========+++--
    signal rxWord_sig : std_logic_vector (6 downto 0);

    --+++=========functions========+++--
    function decode_7to4 (input : std_logic_vector(6 downto 0)) return std_logic_vector is
        begin
            case input is
                when "1111011" => return "0000"; when "1111001" => return "0001"; when "1110111" => return "0010";
                when "1110011" => return "0011"; when "1110001" => return "0100"; when "1110111" => return "0101";
                when "1100111" => return "0110"; when "1100011" => return "0111"; when "1100001" => return "1000";
                when "1011111" => return "1001"; when "1001111" => return "1010"; when "1000111" => return "1011";
                when "1000011" => return "1100"; when "1000001" => return "1101"; when "0111111" => return "1110";
                when "0011111" => return "1111"; when others => return "XXXX";
            end case;
        end function;

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
    
    DECODER: process (clock, reset)
    variable nibbleReady_var : std_logic := '0';
    variable rxNibble_var : std_logic_vector(3 downto 0) := (others => '0');
    variable idleEn_var   : std_logic;
    begin
        if reset = ACTIVE then
            rxNibble_var := (others => '0');
            nibbleReady_var := '0';
            idleEn <= not ACTIVE;

        elsif rising_edge(clock) then
            if rxWord = "0000000" then
                idleEn_var := ACTIVE;
                
            elsif dataReady = ACTIVE and is_valid_input(rxWord) then
                rxNibble_var := decode_7to4(rxWord);
                nibbleReady_var := ACTIVE;
                idleEn_var := not ACTIVE;
            else
                nibbleReady_var := not ACTIVE;
                idleEn_var := not ACTIVE;
            end if;
        end if;
    idleEn <= idleEn_var;
    rxNibble <= rxNibble_var;
    nibbleReady <= nibbleReady_var;
    end process;

end architecture;