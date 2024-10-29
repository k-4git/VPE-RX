----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/28/2024 04:02:10 PM
-- Design Name: 
-- Module Name: T0Sampler - T0Sampler_ARCH
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity T0Sampler is
        
    Port ( vpeClean : in STD_LOGIC;
           frameStartEn : out STD_LOGIC;
           wordStartEn : out STD_LOGIC;
           clock : in STD_LOGIC;
           reset : in STD_LOGIC);
end T0Sampler;

architecture T0Sampler_ARCH of T0Sampler is
constant ACTIVE: std_logic := '1';
type sample_t is (LOWCOUNT, HIGHCOUNT, CALCULATE);

signal lowTime: integer;
signal highTime: integer;

signal t0Sampled: integer;

signal SampleState: sample_t;

signal lowCountEn: std_logic;
signal highCountEn: std_logic;
signal calculateEn: std_logic;
signal t0PushEn: std_logic;
begin


    SAMPLE_CONTROLLER: process(clock, reset)
    variable risingFlag: std_logic := not ACTIVE;
    begin
        if(reset = ACTIVE) then
            risingFlag := not ACTIVE;
            sampleState <= LOWCOUNT;
            lowCountEn <= not ACTIVE;
            highCountEn <= not ACTIVE;
        elsif(rising_edge (clock)) then
            case (SampleState) is
            
            --LOWCOUNT State, Will count in Background until vpeClean goes HIGH
            --Afterward, will send lowCountEn to stop count and Transition into HIGHCOUNT
            when LOWCOUNT =>
                if(vpeClean = not risingFlag) then
                    sampleState <= HIGHCOUNT;
                    lowCountEn <= ACTIVE;
                end if;
            
            --HIGHCOUNT, will count in Background after vpeClean goes HIGH
            --Will send highCountEn to stop count when vpeClean goes low and transition
            --into CALCULATE
            when HIGHCOUNT =>
                if(vpeClean = not risingFlag) then
                    sampleState <= CALCULATE;
                    highCountEn <= ACTIVE;
                end if;
                
            --will calculate t0 and receive t0PushEn when done, transitions back into LOWCOUNT
            when CALCULATE =>
                if(t0PushEn = ACTIVE) then
                    sampleState <= LOWCOUNT;
                end if;
            end case;
        end if;
    end process;
    
    LOW_COUNT: process(clock, reset)
    variable lowClock: integer;
    begin
        if(reset = ACTIVE) then
            lowTime <= 0;
        elsif(rising_edge (clock)) then
            if(lowCountEn = ACTIVE) then
                lowTime <= lowClock;
                lowClock := 0;
            else
                lowClock := lowClock + 1;    
            end if;
        end if;
    end process;
    
    HIGH_COUNT: process(clock, reset)
    variable highClock: integer;
    begin
        if(reset = ACTIVE) then
            highTime <= 0;
        elsif(rising_edge (clock)) then
            if(highCountEn = ACTIVE) then
                highTime <= highClock;
                highClock := 0;
            else
                highClock := highClock + 1;    
            end if;
        end if;
    end process;
    
    
end T0Sampler_ARCH;
