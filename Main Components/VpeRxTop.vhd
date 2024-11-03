library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VpeRxTop is
    Port ( 
        -- Top-level inputs
        vpeSerial   : in STD_LOGIC;       -- Input VPE serial signal
        clock       : in STD_LOGIC;       -- System clock
        reset       : in STD_LOGIC;       -- Active high reset
        
        -- Top-level outputs
        rxOut      : out STD_LOGIC_VECTOR(31 downto 0);  -- Final decoded 32-bit output
        newWord    : out STD_LOGIC;       -- Indicates new word is being processed
        endFrame   : out STD_LOGIC        -- Indicates end of frame
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
            newWord     : out STD_LOGIC;
            endFrame    : out STD_LOGIC;
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
            idleEn    : out STD_LOGIC;
            rxOut     : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    -- Internal signals for connecting the modules
    signal vpeClean    : STD_LOGIC;
    signal t0En        : STD_LOGIC;
    signal idleEn      : STD_LOGIC;

begin
    -- Instantiate RxSampler
    SAMPLER: RxSampler
    port map (
        vpeSerial   => vpeSerial,
        clock       => clock,
        reset       => reset,
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
        t0En        => t0En,
        idleEn      => idleEn,
        rxOut       => rxOut
    );

end VpeRxTop_ARCH;