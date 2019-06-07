-- Company: 			Dossytronics
-- Engineer: 			Dominic Beesley
-- 
-- Create Date:    	3/6/2019
-- Design Name: 
-- Module Name:    	dcjimapi
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 		Top level for RetroClinic datacentre modified to follow
--							JIM interop API
-- Dependencies: 
--
-- Revision: 			4.00		- new JIM API
-- Additional Comments: 
-- Licence:				GPL v3
--

----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;


--use work.mk1board_types.all;

entity dcjimapi is
	generic (
		DEVNO					: std_logic_vector(7 downto 0) := x"DC"				-- DataCentre device number
	);
	port(

		-- 1M bus interface 

		BUS1M_CLK_1M		:	in 	std_logic;
		BUS1M_A				:	in		std_logic_vector(7 downto 0);
		BUS1M_D				:	inout	std_logic_vector(7 downto 0);
		BUS1M_nIRQ			:  out	std_logic;
		BUS1M_nPGFC			: 	in		std_logic;
		BUS1M_nPGFD			: 	in		std_logic;
		BUS1M_nRST			: 	in		std_logic;
		BUS1M_RnW			: 	in		std_logic;

		-- SRAM chip

		RAM_A					:	out	std_logic_vector(19 downto 8);				-- note: LSB of address connected to 1M bus
		RAM_nCE				:  out	std_logic;
		RAM_nOE				:  out	std_logic;
		RAM_nWE				:  out	std_logic;

		-- IDE interface

		IDE_DRQa				:	out	std_logic;
		IDE_D					:	inout	std_logic_vector(15 downto 8);				-- note: LSB direct from 1M bus
		IDE_nCS0				:  out	std_logic;
		IDE_nCS1				:  out	std_logic;
		IDE_nRD				:  out	std_logic;
		IDE_nWR				:  out	std_logic;
		IDE_nIRQ				: 	in		std_logic;

		-- Vinculum USB

		VINC_nDACK			: 	in		std_logic;
		VINC_nDREQ			:	out	std_logic;
		VINC_nRD				:	out	std_logic;
		VINC_WR				:	out	std_logic;
		VINC_nRXF			:	in		std_logic;
		VINC_nTXE			:	in		std_logic;

		-- serial EEPROM

		EEPROM_SCL			: 	out	std_logic;
		EEPROM_SDA			: 	inout	std_logic

	);
end dcjimapi;

architecture rtl of dcjimapi is

	signal	i_CnPGFC				: std_logic;
	signal	i_CnPGFD				: std_logic;

	signal	r_RAM_A				: std_logic_vector(19 downto 8) := (others => '0');

	signal	i_sel_FCF8x			: std_logic;
	signal	i_sel_FCFF			: std_logic;
	signal	i_sel_FCFE			: std_logic;
	signal	i_sel_FCFD			: std_logic;
	signal	i_sel_FCFC			: std_logic;
	signal	i_sel_FCFB			: std_logic;
	signal	i_sel_FCFA			: std_logic;
	signal	i_sel_FCF9			: std_logic;
	signal	i_sel_FCF8			: std_logic;

	signal	i_sel_xx4x			: std_logic;
	signal	i_sel_xx40_7		: std_logic;
	signal	i_sel_xx48_B		: std_logic;
	signal	i_sel_xx4C_F		: std_logic;

	signal	r_VINC_DREQ			: std_logic;
	signal	r_VINC_IRQen		: std_logic;

	signal	r_IDE_H_wr			: std_logic_vector(15 downto 8);
	signal	l_IDE_H_rd  		: std_logic_vector(15 downto 8);

	signal	i_IDE_nRD			: std_logic;
	signal	i_IDE_nWR			: std_logic;

	signal	r_EEPROM_SDA		: std_logic;
	signal	r_EEPROM_SDA_dir	: std_logic;
	signal	r_EEPROM_SCL		: std_logic;

	signal	r_jim_DEVSEL		: std_logic;

begin

	-- note: original schematic project had unused D pins set to Z - this caused the fit to
	-- fail with the extra signals, no all unused are set to '1' which does fit

	BUS1M_D <= 	DEVNO xor x"FF" 
								when i_sel_FCFF = '1' and BUS1M_RnW = '1' and r_jim_DEVSEL = '1' else
					r_RAM_A(15 downto 8) -- page lo
								when i_sel_FCFE = '1' and BUS1M_RnW = '1' and r_jim_DEVSEL = '1' else
					"1111" & r_RAM_A(19 downto 16) -- page hi
								when i_sel_FCFD = '1' and BUS1M_RnW = '1' and r_jim_DEVSEL = '1' else
					(7 => VINC_nRXF, 6 => VINC_nTXE, 0 => VINC_nDACK, others => '1') 
								when i_sel_FCF9 = '1' and BUS1M_RnW = '1' else
					l_IDE_H_rd
								when i_sel_xx48_B = '1' and i_CnPGFC = '0' and BUS1M_RnW = '1' else
					(0 => EEPROM_SDA, others => '1')
								when i_sel_FCFA = '1' and BUS1M_RnW = '1' else								
					(others => 'Z');

	e_clean_pgfc:entity work.pgfx_clean
	port map (
		clk_i => BUS1M_CLK_1M,
		d_i => BUS1M_nPGFC,
		q_o => i_CnPGFC
		);

	e_clean_pgfd:entity work.pgfx_clean
	port map (
		clk_i => BUS1M_CLK_1M,
		d_i => BUS1M_nPGFD,
		q_o => i_CnPGFD
		);

	-- address decode

	i_sel_FCF8x <=	'1' when BUS1M_A(7 downto 3) = "11111" and i_CnPGFC = '0' else
						'0';

	i_sel_FCFF <= 	'1' when BUS1M_A(2 downto 0) = "111" and i_sel_FCF8x = '1' else
						'0';
	i_sel_FCFE <= 	'1' when BUS1M_A(2 downto 0) = "110" and i_sel_FCF8x = '1' else
						'0';
	i_sel_FCFD <= 	'1' when BUS1M_A(2 downto 0) = "101" and i_sel_FCF8x = '1' else
						'0';

	i_sel_FCFC <= 	'1' when BUS1M_A(2 downto 0) = "100" and i_sel_FCF8x = '1' else
						'0';
	i_sel_FCFB <= 	'1' when BUS1M_A(2 downto 0) = "011" and i_sel_FCF8x = '1' else
						'0';
	i_sel_FCFA <= 	'1' when BUS1M_A(2 downto 0) = "010" and i_sel_FCF8x = '1' else
						'0';
	i_sel_FCF9 <= 	'1' when BUS1M_A(2 downto 0) = "001" and i_sel_FCF8x = '1' else
						'0';

	i_sel_FCF8 <= 	'1' when BUS1M_A(2 downto 0) = "000" and i_sel_FCF8x = '1' else
						'0';


	-- note these aren't qualified by CnPGFC because of need to setup CS0/1 before
	-- nRD/nWR
	i_sel_xx4x <= 	'1' when BUS1M_A(7 downto 4) = x"4" else '0'; 
	i_sel_xx40_7 <= '1' when BUS1M_A(3) = '0' and i_sel_xx4x = '1' else '0';
	i_sel_xx48_B <= '1' when BUS1M_A(3) = '1' and BUS1M_A(2) = '0' and i_sel_xx4x = '1' else '0';
	i_sel_xx4C_F <= '1' when BUS1M_A(3) = '1' and BUS1M_A(2) = '1' and i_sel_xx4x = '1' else '0';

	-- eeprom

	EEPROM_SDA <= r_EEPROM_SDA when r_EEPROM_SDA_dir = '1' else 'Z';
	EEPROM_SCL <= r_EEPROM_SCL;

	p_fcfa:process(BUS1M_nRST, i_sel_FCFA, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_EEPROM_SDA <= '0';
		elsif falling_edge(BUS1M_CLK_1M) then
			if i_sel_FCFA = '1' and BUS1M_RnW = '0' then
				r_EEPROM_SDA <= BUS1M_D(0);
			end if;
		end if;

	end process;

	p_fcfb:process(BUS1M_nRST, i_sel_FCFA, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_EEPROM_SDA_dir <= '0';
		elsif falling_edge(BUS1M_CLK_1M) then
			if i_sel_FCFB = '1' and BUS1M_RnW = '0' then
				r_EEPROM_SDA_dir <= BUS1M_D(0);
			end if;
		end if;
	end process;

	p_fcfc:process(BUS1M_nRST, i_sel_FCFA, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_EEPROM_SCL <= '0';
		elsif falling_edge(BUS1M_CLK_1M) then
			if i_sel_FCFC = '1' and BUS1M_RnW = '0' then
				r_EEPROM_SCL <= BUS1M_D(0);
			end if;
		end if;
	end process;

	-- ide

	IDE_nWR <= i_IDE_nWR;
	IDE_nRD <= i_IDE_nRD;
	IDE_nCS0 <= '0' when i_CnPGFC = '0' and i_sel_xx40_7 = '1' else '1';
	IDE_nCS1 <= '0' when i_CnPGFC = '0' and i_sel_xx4C_F = '1' else '1';

	IDE_D <= r_IDE_H_wr when i_IDE_nWR = '0' else
				(others => 'Z');

	i_IDE_nRD <= '0' when (i_sel_xx40_7 = '1' or i_sel_xx4C_F = '1') and i_CnPGFC = '0' and BUS1M_RnW = '1' else
					 '1';
	i_IDE_nWR <= '0' when (i_sel_xx40_7 = '1' or i_sel_xx4C_F = '1') and i_CnPGFC = '0' and BUS1M_RnW = '0' else
					 '1';

	p_ide_dh_wr:process(BUS1M_CLK_1M, BUS1M_nRST, i_CnPGFC, i_sel_xx48_B, BUS1M_RnW, BUS1M_D)
	begin
		if BUS1M_nRST = '0' then
			r_IDE_H_wr <= (others => '0');
		elsif falling_edge(BUS1M_CLK_1M) then
			if i_sel_xx48_B = '1' and BUS1M_RnW = '0' and i_CnPGFC = '0' then
				r_IDE_H_wr <= BUS1M_D;
			end if;
		end if;
	end process;

	p_ide_dh_rd:process(i_IDE_nRD, IDE_D)
	begin
		if i_IDE_nRD = '0' then
			l_IDE_H_rd <= IDE_D;
		end if;
	end process;

	-- vinc interface

	VINC_nDREQ <= not r_VINC_DREQ;

	BUS1M_nIRQ <= 	'0' when VINC_nRXF = '0' and r_VINC_IRQen = '1' else
						'Z';

	VINC_WR <= 	'1' when i_sel_FCF8 = '1' and BUS1M_RnW = '0' else
					'0';
	VINC_nRD <= '0' when i_sel_FCF8 = '1' and BUS1M_RnW = '1' else
					'1';

	p_vinc_stat_dreq:process(BUS1M_nRST, i_sel_FCF9, BUS1M_CLK_1M, BUS1M_D)
	begin
		if BUS1M_nRST = '0' then
			r_VINC_DREQ <= '0';
		elsif falling_edge(BUS1M_CLK_1M) and i_sel_FCF9 = '1' and BUS1M_RnW = '0' then
			r_VINC_DREQ <= BUS1M_D(0);
		end if;
	end process;

	p_vinc_stat_irqen:process(BUS1M_nRST, i_sel_FCF9, BUS1M_CLK_1M, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_VINC_IRQen <= '0';
		elsif falling_edge(BUS1M_CLK_1M) then
			if i_sel_FCF9 = '1' and BUS1M_RnW = '0' then
				r_VINC_IRQen <= BUS1M_D(7);
			elsif i_sel_FCF8 = '1' and BUS1M_RnW = '1' then
				r_VINC_IRQen <= '0';
			end if;
		end if;
	end process;

	-- jim device enable

	p_jimsel:process(BUS1M_nRST, i_sel_FCFF, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_jim_DEVSEL <= '0';
		elsif falling_edge(BUS1M_CLK_1M) and i_sel_FCFF = '1' and BUS1M_RnW = '0' then
			if BUS1M_D = DEVNO then
				r_jim_DEVSEL <= '1';
			else
				r_jim_DEVSEL <= '0';
			end if;
		end if;
	end process;

	-- ram interface

	RAM_A <= r_RAM_A;
	RAM_nWE <= BUS1M_RnW;	
	RAM_nOE <= not BUS1M_RnW;
	RAM_nCE <= i_CnPGFD when r_jim_DEVSEL = '1' else '1';

	p_ram_A_15_8:process(BUS1M_nRST, i_sel_FCFE, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_RAM_A(15 downto 8) <= (others => '0');
		elsif falling_edge(BUS1M_CLK_1M) and i_sel_FCFE = '1' and BUS1M_RnW = '0' then
			r_RAM_A(15 downto 8) <= BUS1M_D;
		end if;
	end process;

	p_ram_A_19_16:process(BUS1M_nRST, i_sel_FCFD, BUS1M_CLK_1M, BUS1M_D, BUS1M_RnW)
	begin
		if BUS1M_nRST = '0' then
			r_RAM_A(19 downto 16) <= (others => '0');
		elsif falling_edge(BUS1M_CLK_1M) and i_sel_FCFD = '1' and BUS1M_RnW = '0' then
			r_RAM_A(19 downto 16) <= BUS1M_D(3 downto 0);
		end if;
	end process;


end rtl;