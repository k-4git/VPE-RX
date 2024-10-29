library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity RxDecoder is
    port (
        clock   : in std_logic;
        reset   : in std_logic;
        rxWord  : in std_logic_vector(6 downto 0);       
        idleEn  : out std_logic
    );
end entity RxDecoder;

architecture behavioral of RxDecoder is

begin

    

end architecture;