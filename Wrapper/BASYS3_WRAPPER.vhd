library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity Wrapper is
    Generic(count      : integer := 10000);
    
    Port ( data        : in STD_LOGIC_VECTOR (15 downto 0);
           loadData    : in STD_LOGIC;
           sendData    : in STD_LOGIC;
           clock       : in STD_LOGIC;
           modeChange  : in STD_LOGIC;
           reset       : in STD_LOGIC;
           vpeSerialIn : in std_logic;
           leds        : out STD_LOGIC_VECTOR(15 downto 0);
           sevenSegs   : out std_logic_vector(6 downto 0);    
           anodes      : out std_logic_vector(3 downto 0);
           vpeSerial   : out STD_LOGIC);
           
end Wrapper;

architecture Wrapper_ARCH of Wrapper is
    constant ACTIVE: std_logic := '1';
    constant WIDTH: natural := 32;
    constant DEPTH: integer := 3;
    constant BUTTON_DEBOUNCE_LENGTH: integer := 2;
    
    type state_t is (LOAD_DATA, READ_DATA, SEND_DATA);
    
    signal currentState: state_t;
    
    signal t0En: std_logic;
    signal dataOut: std_logic_vector(WIDTH-1 downto 0);
    signal fifoFull: std_logic;
    signal fifoEmpty: std_logic;
    signal loadEn: std_logic;
    signal writeEn: std_logic;
    signal loadDataDebounced: std_logic;
    signal sendDataDebounced: std_logic;
    signal modeChangeDebounced : std_logic;
    signal modeSwitch : std_logic;
   
    signal rxOut :std_logic_vector( 15 downto 0);
    signal readEn: std_logic;
    signal wordEndEn: std_logic;
    signal nibbleIndex: integer range 0 to 7;
    signal txMode: std_logic;
    signal dataInternal: std_logic_vector(31 downto 0);
    signal fifoCount : integer range 0 to DEPTH-1;
    
    component VpeRxTop 
        port (
            vpeSerial   : in STD_LOGIC;       -- Input VPE serial signal
            clock       : in STD_LOGIC;       -- System clock
            reset       : in STD_LOGIC;       -- Active high reset
            rxOut      : out STD_LOGIC_VECTOR(15 downto 0)  -- Final decoded 32-bit output
            );
     end component;
     
     component Debouncer_Toggle 
        Port ( 
        modeChange: in std_logic;
        clock: in std_logic;
        reset: in std_logic;
        
        modeSwitch: out std_logic);
    end component;
    
    component VpeTxTop is
        Port (data : in STD_LOGIC_VECTOR (31 downto 0); 
              t0En : in STD_LOGIC;
              txMode : in STD_LOGIC; 
              loadEn: in STD_LOGIC; 
              clock : in STD_LOGIC;
              reset : in STD_LOGIC;
              
              vpeSerial : out STD_LOGIC;
              wordEndEn : out STD_LOGIC);
    end component;
    
     component Fifo
        generic (
            WIDTH:  natural;    --size of each fifo register
            DEPTH:  integer     --number of registers in the fifo
            ); 
        port (
            reset:   in std_logic;
            clock:   in std_logic;
            writeEn: in  std_logic;    --initiates write to fifo
            readEn:  in  std_logic;    --removes next fifo data value
            dataIn:  in  std_logic_vector(WIDTH-1 downto 0);
            fifoFull:   out std_logic;    --fifo is full
            fifoEmpty:  out std_logic;    --fifo is empty
            dataOut:    out std_logic_vector(WIDTH-1 downto 0);
            fifoCount: out integer range 0 to DEPTH-1
            );
    end component;
    
    component t0Generator is
        Generic(count: integer);
        Port (clock : in STD_LOGIC;
              reset: in STD_LOGIC;
              t0En : out STD_LOGIC
               );
     end component;
     
     component ButtonDebouncer is
      generic ( DEBOUNCE_CYCLES : integer);  -- For 100 MHz clock (100MHz * 5ms)
            
      Port ( 
            buttonIn: in std_logic;
            pulseOut: out std_logic;
            clock: in std_logic;
            reset: in std_logic );
      end component;
      
      component DisplayDataDriver is
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            rxOut       : in std_logic_vector( 15 downto 0);
            switches    : in STD_LOGIC_VECTOR(15 downto 0);
            fifoCount   : in integer;
            modeSwitch  : in std_logic;
            loadData    : in std_logic;
            leds        : out STD_LOGIC_VECTOR(15 downto 0);
            sevenSegs   : out std_logic_vector(6 downto 0);    --MSB=g, LSB=a
            anodes      : out std_logic_vector(3 downto 0)    --MSB=leftmost digit
        );
      end component;

begin
    DeBouncer: Debouncer_Toggle
    port map(
        modeChange => modeChangeDebounced,
        clock => clock,
        reset => reset, 
        modeSwitch => modeSwitch
    );
    
    VPE_RX: VpeRxTop
    port map(
         vpeSerial => vpeSerialIn,
         clock => clock,
         reset => reset,  
         rxOut => rxOut   
    );
    
    COUNTER: t0Generator 
    generic map (count)
    port map (
        clock => clock,
        reset => reset,
        t0En => t0En
    );


     LOAD_DATA_DEBOUNCER: ButtonDebouncer 
      generic map(BUTTON_DEBOUNCE_LENGTH)  -- For 100 MHz clock (100MHz * 5ms)
            
      Port map ( 
            buttonIn => loadData,
            pulseOut => loadDataDebounced,
            clock => clock,
            reset=> reset );

      SEND_DATA_DEBOUNCER: ButtonDebouncer 
      generic map(BUTTON_DEBOUNCE_LENGTH)  -- For 100 MHz clock (100MHz * 5ms)
            
      Port map ( 
            buttonIn => sendData,
            pulseOut => sendDataDebounced,
            clock => clock,
            reset=> reset );
            
      MODE_CHANGE_DEBOUNCER: ButtonDebouncer 
      generic map(BUTTON_DEBOUNCE_LENGTH)  -- For 100 MHz clock (100MHz * 5ms)
            
      Port map ( 
            buttonIn => modeChange ,
            pulseOut => modeChangeDebounced,
            clock => clock,
            reset=> reset );

    FIFO_COMPONENT: Fifo
        generic map (WIDTH, DEPTH)
        port map (
            reset  => reset,
            clock  => clock,
            writeEn => writeEn,
            readEn  => readEn,
            dataIn  => dataInternal,--x"0000" & data,
            fifoFull => fifoFull,
            fifoEmpty => fifoEmpty,
            fifoCount => fifoCount,
            dataOut   => dataOut
        );    
    DISPLAY_DATA_DRIVER:DisplayDataDriver
        port map (
            clock => clock,
            reset => reset, 
            rxOut => rxOut,     
            modeSwitch => modeSwitch,
            switches => data,  
            fifoCount => fifoCount,
            loadData  => loadData, 
            leds =>  leds, 
            sevenSegs => sevenSegs,
            anodes => anodes    
        );
        
    VPE_TX: VpeTxTop
        port map (
            data => dataOut,
            t0En => t0En,
            txMode => txMode,
            loadEn => loadEn,
            clock => clock,
            reset => reset,
            
            vpeSerial => vpeSerial,
            wordEndEn => wordEndEn
        );
        
    PROCESS_DATA: process(clock, reset)
        variable firstLoad: std_logic := not ACTIVE;
        variable count: integer := 0;
        begin
            if (reset = ACTIVE) then
                loadEn <= not ACTIVE;
                currentState <= LOAD_DATA;
                dataInternal <= (others => not ACTIVE);
            elsif(rising_edge(clock)) then
                dataInternal <= x"0000" & data;
                readEn <= not ACTIVE;
                loadEn <= not ACTIVE;
                writeEn <= not ACTIVE;
                case currentState is
                    when LOAD_DATA =>
                        writeEn <= not ACTIVE;
                        readEn <= not ACTIVE;
                        if(loadDataDebounced = ACTIVE) then
                            writeEn <= ACTIVE;
                        elsif(sendDataDebounced = ACTIVE) then
                            txMode <= ACTIVE;
                            currentState <= READ_DATA;
                            --loadEn <= ACTIVE;
                        end if;
                    when READ_DATA =>
                            loadEn <=  ACTIVE;
                            readEn <=  ACTIVE;
                            currentState <= SEND_DATA;
                    when SEND_DATA =>
                        txMode <= ACTIVE;
                        readEn <= not ACTIVE;
                        loadEn <= not ACTIVE;
                        if(wordEndEn = ACTIVE) then
                            if(fifoEmpty = ACTIVE) then
                                txMode <= not ACTIVE;
                                currentState <= LOAD_DATA;
                            else
                                loadEn <= ACTIVE;
                                readEn <= ACTIVE;
                            end if;
                        end if;

                end case;
            end if;  
    end process;

end Wrapper_ARCH;
