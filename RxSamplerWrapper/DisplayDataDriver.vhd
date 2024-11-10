library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--      Seven Segment is used to display the data 
--      leds is used to display switch position and also has blinking led functionality.
--      
--

entity DisplayDataDriver is
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
end entity;

architecture DisplayDataDriver_ARCH of DisplayDataDriver is

    --================Components====================--
    --Seven Segs Driver--
    component SevenSegmentDriver
    port (
            reset: in std_logic;
            clock: in std_logic;

            digit3: in std_logic_vector(3 downto 0);    --leftmost digit
            digit2: in std_logic_vector(3 downto 0);    --2nd from left digit
            digit1: in std_logic_vector(3 downto 0);    --3rd from left digit
            digit0: in std_logic_vector(3 downto 0);    --rightmost digit

            blank3: in std_logic;                       --leftmost digit
            blank2: in std_logic;                       --2nd from left digit
            blank1: in std_logic;                       --3rd from left digit
            blank0: in std_logic;                       --rightmost digit

            sevenSegs: out std_logic_vector(6 downto 0);    --MSB=g, LSB=a
            anodes:    out std_logic_vector(3 downto 0)    --MSB=leftmost digit
        );
    end component;

     --================Constants====================--
     constant ACTIVE: std_logic := '1';  
     constant BLINK_LIMIT : integer := 50000000;  -- 0.5 seconds at 100 MHz
     constant CLOCK_FREQ : integer := 100000000;  -- Assuming 100 MHz clock
     constant ONE_SECOND : integer := CLOCK_FREQ - 1;
     signal delay_counter : integer range 0 to ONE_SECOND := 0;
    --=================Signals=====================--
    --Seven Segment Signals--
    signal digit3: std_logic_vector(3 downto 0);    --leftmost digit
    signal digit2: std_logic_vector(3 downto 0);    --2nd from left digit
    signal digit1: std_logic_vector(3 downto 0);    --3rd from left digit
    signal digit0: std_logic_vector(3 downto 0);    --rightmost digit
                    --All leds enabled--
    signal blank3: std_logic := '0';                       --leftmost digit
    signal blank2: std_logic := '0';                       --2nd from left digit
    signal blank1: std_logic := '0';                       --3rd from left digit
    signal blank0: std_logic := '0';                       --rightmost digit

    --Blinking LED Signals-
    signal blinkCounter   : integer range 0 to BLINK_LIMIT := 0;  -- 0.5s at 100MHz
    signal blinkState     : std_logic := '0';
    
    --State Machine--
    type state_t is (INPUT_DATA, SENT_DATA);
    signal currentState: state_t;
    
    
    --led function--
    function Assign_LEDs(
                         loadData_in : std_logic;
                         switches_in : STD_LOGIC_VECTOR(15 downto 0);
                         blink_st : std_logic) return STD_LOGIC_VECTOR is
        variable leds_temp : STD_LOGIC_VECTOR(15 downto 0);
    begin
        if loadData_in = ACTIVE then
            leds_temp := (others => blink_st);  -- All LEDs set to blink_state
        else
            leds_temp := switches_in;            -- LEDs mirror switch states
        end if;
        return leds_temp;
    end function;

    
    

begin
   --=====================Driver Processes======================
   --===== LED Driver Process Using Function =====--
   LED_DRIVER: process (clock, reset)
   begin
       if reset = ACTIVE then
           leds <= (others => '0');  -- Turn off all LEDs on reset
       elsif rising_edge(clock) then
           leds <= Assign_LEDs(loadData, switches, blinkState);  -- Assign LEDs via function
       end if;
   end process LED_DRIVER;

   BLINK_DRIVER: process (clock, reset)
   begin
    if reset = ACTIVE then
        blinkCounter <= 0;
        blinkState <= '0';
    elsif rising_edge(clock) then
        if loadData = ACTIVE then
            if blinkCounter < BLINK_LIMIT -1 then  -- Count up to 49,999,999
                blinkCounter <= blinkCounter + 1;
            else
                blinkCounter <= 0;
                blinkState   <= not blinkState;  -- Toggle LED state
            end if;
        else
            -- If loadData is not active, reset counter and turn off LED
            blinkCounter <= 0;
            blinkState   <= '0';
        end if;     
    end if;
   end process;

   DISPLAY_DRIVER: process (clock, reset)
   begin
    if reset = ACTIVE then
        digit0 <= "0000";
        currentState <= INPUT_DATA;
    elsif rising_edge(clock) then
        
        case( currentState ) is
            -- When inputing data into fifo show the 16 bits in hex on the 7seg display
            when INPUT_DATA =>
                --All data is from switches--
                digit0 <= switches( 3 downto 0);
                digit1 <= switches( 7 downto 4);
                digit2 <= switches( 11 downto 8);
                digit3 <= switches( 15 downto 12);

                -- change states when loading data
                if loadData = ACTIVE then
                    currentState <= SENT_DATA;                  
                end if ;

            -- When data is sent, show the dataset from the fifo on the 7seg display
            when SENT_DATA =>
                digit0 <= STD_LOGIC_VECTOR(to_unsigned(fifoCount,4));
                digit1 <= "0000";
                digit2 <= "0000";
                digit3 <= "0000";
                if delay_counter = ONE_SECOND then
                        currentState <= INPUT_DATA;
                        delay_counter <= 0;
                    else
                        delay_counter <= delay_counter + 1;
                    end if;
                    
            when others =>
                currentState <= INPUT_DATA;
        end case ;
        
    end if;
   end process;

    --=====================SevenSegmentDriver Instantiation======================
    SevenSeg_Inst: SevenSegmentDriver
        port map (
            reset     => reset,
            clock     => clock,
            digit3    => digit3,
            digit2    => digit2,
            digit1    => digit1,
            digit0    => digit0,
            blank3    => blank3,
            blank2    => blank2,
            blank1    => blank1,
            blank0    => blank0,
            sevenSegs => sevenSegs,
            anodes    => anodes
         );
    

end architecture;