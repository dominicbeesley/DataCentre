-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	3/6/2019
-- Design Name: 
-- Module Name:    	pgfx_clean
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		clean nPGFC/nPFGD signals
-- Dependencies: 
--
-- Revision: 
-- Additional Comments: 
-- Licence:				
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;

entity pgfx_clean is
	port(
		clk_i		:	in		std_logic;
		d_i		:	in		std_logic;
		q_o		: 	out	std_logic
	);
end pgfx_clean;

architecture rtl of pgfx_clean is
	signal 	r	: std_logic;
begin

	process(clk_i)
	begin
		if rising_edge(clk_i) then
			r <= d_i;
		end if;
	end process;

	q_o <= '1' when clk_i = '0' else
			 r;

end rtl;
