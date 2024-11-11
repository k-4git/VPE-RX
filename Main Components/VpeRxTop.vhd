library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VpeRxTop is
    Port ( 
        -- Top-level inputs
        vpeSerial   : in STD_LOGIC;       -- Input VPE serial signal
        clock       : in STD_LOGIC;       -- System clock
        reset       : in STD_LOGIC;       -- Active high reset
        
        -- Top-level outputs
        rxOut      : out STD_LOGIC_VECTOR(15 downto 0)  -- Final decoded 32-bit output
    );
end VpeRxTop;

architecture VpeRxTop_ARCH of VpeRxTop is
    -- Component declarations
    component RxSampler is
        Port ( 
            vpeSerial   : in STD_LOGIC;
            clock       : in STD_LOGIC;
            reset       : in STD_LOGIC;
            idleEn      : in STD_LOGIC;
            t0Sample    : out INTEGER;
            newWord     : out std_logic;
            endFrame    : out std_logic;
            vpeClean    : out STD_LOGIC;
            t0En        : out STD_LOGIC
        );
    end component;

    component RxDecoder is
        Port (
            clock     : in STD_LOGIC;
            reset     : in STD_LOGIC;
            vpeClean  : in STD_LOGIC;
            t0En      : in STD_LOGIC;
            t0Sample  : in INTEGER;
            newWord   : in std_logic;
            endFrame  : in std_logic;
            idleEn    : out STD_LOGIC;
            rxOut     : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Internal signals for connecting the modules
    signal vpeClean    : STD_LOGIC;
    signal t0En        : STD_LOGIC;
    signal idleEn      : STD_LOGIC;
    signal t0Sample    : INTEGER;
    signal newWord     : std_logic;
    signal endFrame    : std_logic;

begin
    -- Instantiate RxSampler
    SAMPLER: RxSampler
    port map (
        vpeSerial   => vpeSerial,
        clock       => clock,
        reset       => reset,
        t0Sample    => t0Sample,
        idleEn      => idleEn,
        newWord     => newWord,
        endFrame    => endFrame,
        vpeClean    => vpeClean,
        t0En        => t0En
    );

    -- Instantiate RxDecoder
    DECODER: RxDecoder
    port map (
        clock       => clock,
        reset       => reset,
        vpeClean    => vpeClean,
        t0Sample    => t0Sample,
        newWord     => newWord,
        endFrame    => endFrame,
        t0En        => t0En,
        idleEn      => idleEn,
        rxOut       => rxOut
    );

end VpeRxTop_ARCH;