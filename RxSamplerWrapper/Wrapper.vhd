----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley, Kahari Moore, Joshua Oey 
-- 
-- Create Date: 10/06/2024 09:28:36 PM
-- Design Name: VPE Transmitter Hardware Implementation
-- Module Name: Wrapper - Wrapper_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Target Devices: None.
-- Description: Component that contains all of the contents of the VPE Transmitter
--
-- Generics:
--      count: integer - The number of clock cycles to cycle through until the next pulse is sent.
--
-- Ports:
--           data : in STD_LOGIC_VECTOR (15 downto 0) - 16 bit word to be loaded into the transmitter.
--          loadData : in STD_LOGIC - Flag that loads the data bus information into the internal storage.
--                                    currently can store and transmit 3 words.
--                     its register to transmit.
--           sendData : in STD_LOGIC - Flag to tell the transmitter to send the words that were loaded into the
--                                     internal register.
--           clock : in STD_LOGIC - The clock signal to drive the transmitter.
--           reset : in STD_LOGIC - Resets the transmitter settings. Clears out the internal registry.
--           vpeSerial : out STD_LOGIC - The bus that transmits the data per protocol standard.
--           leds        : out STD_LOGIC_VECTOR(15 downto 0); - mirrors switch inputs as an led output
--           sevenSegs   : out std_logic_vector(6 downto 0);  - 7seg connections  
--           anodes      : out std_logic_vector(3 downto 0);  - 7seg anode connections
--
--
--
-- 
-- Dependencies: None.
-- 
-- Revision: 1.0
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity Wrapper is
    Generic(count      : integer);
    
    Port ( data        : in STD_LOGIC_VECTOR (15 downto 0);
           loadData    : in STD_LOGIC;
           sendData    : in STD_LOGIC;
           clock       : in STD_LOGIC;
           reset       : in STD_LOGIC;
           leds        : out STD_LOGIC_VECTOR(15 downto 0);
           sevenSegs   : out std_logic_vector(6 downto 0);    
           anodes      : out std_logic_vector(3 downto 0);
           vpeSerial   : out STD_LOGIC;
           RxT0En     : out std_logic;
           vpeSerialIn: in std_logic);
           
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
    
    signal readEn: std_logic;
    signal wordEndEn: std_logic;
    signal nibbleIndex: integer range 0 to 7;
    signal txMode: std_logic;
    signal dataInternal: std_logic_vector(31 downto 0);
    signal fifoCount : integer range 0 to DEPTH-1;
    
    signal vpeClean: std_logic;
    signal wordStartEn: std_logic;
    signal frameStartEn: std_logic;
    signal t0Samples: integer;
    signal t0GenMode: std_logic;
    signal idleEn : std_logic;
    signal newWord: std_logic;
    signal endFrame: std_logic;
    signal vpeBetween: std_logic;
    
    ------------------------------------------------RECEIVER
    component RxSampler is
        port -- VPE Processing inputs
        (vpeSerial   : in STD_LOGIC;       -- Input VPE serial signal
        clock       : in STD_LOGIC;           -- System clock
        reset       : in STD_LOGIC;           -- Active high reset
        idleEn      : in STD_LOGIC;                
        newWord     : out STD_LOGIC;
        endFrame    : out STD_LOGIC;
        vpeClean    : out STD_LOGIC;
        t0Sample    : out integer;
        t0En        : out STD_LOGIC);       -- T0 enable signal for sampling
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
            switches    : in STD_LOGIC_VECTOR(15 downto 0);
            fifoCount   : in integer;
            loadData    : in std_logic;
            leds        : out STD_LOGIC_VECTOR(15 downto 0);
            sevenSegs   : out std_logic_vector(6 downto 0);    --MSB=g, LSB=a
            anodes      : out std_logic_vector(3 downto 0)    --MSB=leftmost digit
        );
      end component;

begin

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
            switches => data,  
            fifoCount => fifoCount,
            loadData  => loadDataDebounced, 
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
            
            vpeSerial => vpeBetween,
            wordEndEn => wordEndEn
        );
        
        VPE_RX_SAMPLER: RxSampler
            port map(
            vpeSerial => vpeBetween,       
            clock => clock,           
            reset=> reset,        
            idleEn=> idleEn,               
            newWord=> newWord,
            endFrame=> endFrame,
            vpeClean=> vpeClean, 
            t0Sample => t0Samples,
            t0En => RxT0En);
            
        
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
