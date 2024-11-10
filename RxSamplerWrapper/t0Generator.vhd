----------------------------------------------------------------------------------
-- Company: Kennesaw State University
-- Engineer: Brett Baxley
-- 
-- Create Date: 10/01/2024 08:31:44 PM
-- Design Name: VPE Signal Transmitter.
-- Module Name: t0Generator - t0Generator_ARCH
-- Project Name: CPE 4490 - Advanced VHDL
-- Target Devices: None.
-- Description: Component used to send the t0En pulse for a single cycle to the vpeTransmitter component. Can be used
--              for test bench simulations.
--              
--  Generics:
--      count: integer - the nunber of cycles to wait before sending a t0En pulse.
--  
--  Signals:
--      clock: std_logic - the clock signal to drive the component.
--      reset: std_logic - the signal that will reset the component to initial settings.
--      t0En: std_logic - sends an ACTIVE HIGH for a single clock cycle every number of cycles. The number
--                        of cycles will depend on the value for the "count" generic.   
-- Dependencies: None.
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity t0Generator is
    Generic(count: integer);
    Port ( clock : in STD_LOGIC;
            reset: in STD_LOGIC;
            t0En : out STD_LOGIC
          );
end t0Generator;

architecture t0Generator_ARCH of t0Generator is

    constant ACTIVE: std_logic := '1';
    begin
    
    RUN: process(clock, reset)
    
        variable counter: integer := 0;
    
        begin
            if(reset = ACTIVE) then
                counter := 0;
            elsif(rising_edge(clock)) then
                if(counter = 10000) then
                    t0En <= ACTIVE;
                    counter := 0;
                else
                    t0En <= not ACTIVE;
                    counter := counter + 1;
                end if;
            end if;
        end process;
  
end t0Generator_ARCH;
