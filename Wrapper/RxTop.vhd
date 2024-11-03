----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/02/2024 01:59:09 PM
-- Design Name: 
-- Module Name: RxTop - RxTop_ARCH
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

entity RxTop is

    
    
    Port (
        vpeSerial: in std_logic;
        
        clock: in std_logic;
        reset: in std_logic;
        
        RxOut: out std_logic_vector(31 downto 0);
        NewWord: out std_logic;
        EndFlag: out std_logic);
    end RxTop;

architecture RxTop_ARCH of RxTop is

signal vpeClean: std_logic;
signal frameStartEn: std_logic;
signal wordStartEn: std_logic;
signal t0Samples: integer;
signal idleEn: std_logic;
signal t0GenEn: std_logic;
signal t0En: std_logic;
signal rxWord: std_logic_vector(6 downto 0);
signal dataReady: std_logic;
signal rxNibble: std_logic_vector(3 downto 0); 
signal nibbleReady: std_logic;


component vpeFilter is
    port (
        --inputs--
        vpeSerial: in std_logic;
        clock: in std_logic;
        reset: std_logic;
        
        --outputs--
        vpeClean: std_logic
    );
end component;

component t0Sampler is
    port (
        --inputs--
        vpeClean: in std_logic;
        
        clock: std_logic;
        reset: in std_logic;
        --outputs--
        wordStartEn: out std_logic;
        frameStartEn: out std_logic;
        t0Samples: out integer
    
    );
end component;

component Rx_Controller is
    port (
        --inputs
        wordStartEn : in STD_LOGIC;
        frameStartEn : in STD_LOGIC;
        idleEn : in STD_LOGIC;
        
        clock: in std_logic;
        reset: in std_logic;
        --outputs
        wordFlag : out STD_LOGIC;
        endFlag : out STD_LOGIC;
        tGenMode : out STD_LOGIC
    );
end component;

component T0GEN is
    port(
        --inputs
        t0Samples  : in integer;
        t0GenEn    : in std_logic;
        
        clock      : in std_logic;
        reset      : in std_logic;
        --outputs
        t0En       : out std_logic
    );
end component;

component  PulseCounter is
    port (
        --inputs
        vpeClean  : in std_logic;     -- Input pulse signal
        t0En      : in std_logic;     -- Enable signal for sampling
        
        clock     : in std_logic;     -- System clock
        reset     : in std_logic;     -- Reset signal
        --outputs
        dataReady : out std_logic;    -- Indicates valid frame
        rxWord    : out std_logic_vector(6 downto 0) -- Output frame
    );
end component;

component RxDecoder is
    port (
        --inputs
        dataReady   : in std_logic;                     -- Input data valid signal
        rxWord      : in std_logic_vector(6 downto 0);  -- 7-bit encoded input data 
           
        clock       : in std_logic;                     -- System clock
        reset       : in std_logic;                     -- Asynchronous reset
        --outputs
        idleEn      : out std_logic;                    -- Idle state indicator
        rxNibble    : out std_logic_vector(3 downto 0); -- Decoded 4-bit output
        nibbleReady : out std_logic                     -- Output data valid signal
    );
end component;    

component dataRegister is
    port (
        --inputs
        rxNibble   : in std_logic_vector(3 downto 0);
        nibbleReady: in std_logic;         -- Indicates valid nibble for processing
        
        clock       : in std_logic;
        reset      : in std_logic;
        
        --outputs
        RxOut      : out std_logic_vector(31 downto 0)
    );
end component;


begin

    VPE_FILTER: vpeFilter port map(
        vpeSerial => vpeSerial,          
        clock => clock,
        reset => reset,
        vpeClean => vpeClean
    );
    
    T0_SAMPLER: T0Sampler port map(
        vpeClean => vpeClean,          
        clock => clock,
        reset => reset,
        frameStartEn => frameStartEn,
        wordStartEn => wordStartEn
    );
    
    RX_CONTROLLER_COMP: Rx_Controller port map(
        idleEn => idleEn,
        frameStartEn => frameStartEn,
        wordStartEn => wordStartEn,          
        clock => clock,
        reset => reset,
        tGenMode => t0GenEn,
        wordFlag => NewWord,
        endFlag => EndFlag
    );     

    
    T0_GEN: T0Gen port map(
        t0GenEn => t0GenEn,
        t0Samples => t0Samples,          
        clock => clock,
        reset => reset,
        t0En => t0En
    );
    
    PULSE_COUNTER: PulseCounter port map(
        vpeClean => vpeClean,
        t0En => t0En,
        reset => reset,
        clock => clock,
        rxWord => rxWord,
        dataReady => dataReady
    );
    
    RX_DECODER: RxDecoder port map(
        rxWord => rxWord,
        dataReady => dataReady,
        reset => reset,
        clock => clock,
        idleEn => idleEn,
        rxNibble => rxNibble,
        nibbleReady => nibbleReady
    );
    
    DATA_REGISTER: DataRegister port map(
        rxNibble => rxNibble,
        nibbleReady => nibbleReady,
        reset => reset,
        clock => clock,
        rxOut => RxOut
    );
    
    
end RxTop_ARCH;
