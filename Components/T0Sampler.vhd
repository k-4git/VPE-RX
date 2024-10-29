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


    Sample_Controller: process(clock, reset)
    variable risingFlag: std_logic := not ACTIVE;
    begin
    if(reset = ACTIVE) then
        risingFlag := not ACTIVE;
        sampleState <= LOWCOUNT;
        lowCountEn <= not ACTIVE;
        highCountEn <= not ACTIVE;
    elsif(rising_edge (clock)) then
        case (SampleState) is
        
        when LOWCOUNT =>
            if(vpeClean = not risingFlag) then
                sampleState <= HIGHCOUNT;
                lowCountEn <= ACTIVE;
            end if;
        when HIGHCOUNT =>
            if(vpeClean = not risingFlag) then
                sampleState <= CALCULATE;
                highCountEn <= ACTIVE;
            end if;
        when CALCULATE =>
            if(t0PushEn = ACTIVE) then
                sampleState <= LOWCOUNT;
            end if;
end T0Sampler_ARCH;
