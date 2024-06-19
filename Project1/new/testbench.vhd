-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- Title							: ONFI compliant NAND interface
-- File							: testbench.vhd
-- Author						: Alexey Lyashko <pradd@opencores.org>
-- License						: LGPL
-------------------------------------------------------------------------------------------------
-- Description:
-- This is the testbench file for the NAND_MASTER module
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.onfi.all;
 
entity tb is
	--port
	--(
	--);
end tb;
 
architecture test of tb is
	component nand_master
		port
		(
			-- System clock
			clk					: in	std_logic;
			-- NAND chip control hardware interface. These signals should be bound to physical pins.
			enable				    : in	std_logic := '0';
			nand_cle				: out	std_logic := '0';
			nand_ale				: out	std_logic := '0';
			nand_nwe				: out	std_logic := '1';
			nand_nwp				: out	std_logic := '0';
			nand_nce				: out	std_logic := '1';
			nand_nre				: out std_logic := '1';
			nand_rnb				: in	std_logic;
			-- NAND chip data hardware interface. These signals should be boiund to physical pins.
			nand_data			: inout	std_logic_vector(15 downto 0); 
 
			-- Component interface
			nreset				: in	std_logic := '1';
			data_out				: out	std_logic_vector(7 downto 0);
			data_in				: in	std_logic_vector(7 downto 0);
			busy					: out	std_logic := '0';
			activate				: in	std_logic := '0';
			cmd_in				: in	std_logic_vector(7 downto 0)
		);
	end component;
	-- Internal interface
	signal enable   : std_logic;
	signal nand_cle : std_logic;
	signal nand_ale : std_logic;
	signal nand_nwe : std_logic;
	signal nand_nwp : std_logic;
	signal nand_nce :	std_logic;
	signal nand_nre : std_logic;
	signal nand_rnb : std_logic := '1';
	signal nand_data: std_logic_vector(15 downto 0);
	signal nreset   : std_logic := '1';
	signal data_out : std_logic_vector(7 downto 0);
	signal data_in  : std_logic_vector(7 downto 0);
	signal busy     : std_logic;
	signal activate : std_logic;
	signal cmd_in   : std_logic_vector(7 downto 0);
	signal clk	: std_logic := '1';

begin
	NM:nand_master
	port map
	(
		clk => clk,
		enable => enable,
		nand_cle => nand_cle,
		nand_ale => nand_ale,
		nand_nwe => nand_nwe,
		nand_nwp => nand_nwp,
		nand_nce => nand_nce,
		nand_nre => nand_nre,
		nand_rnb => nand_rnb,
		nand_data=> nand_data,
		nreset   => nreset,
		data_out => data_out,
		data_in  => data_in,
		busy     => busy,
		activate => activate,
		cmd_in   => cmd_in
	);

	
   -- Nand model MT29F64G08AECABH1 Component Instantiation
   
    --nand_b0_1: nand_model
     nand_b0_1 : entity work.nand_model
        port map (
            Clk_We_n => nand_nwe,     
            Ce_n     => nand_nce,   
            Rb_n     => nand_rnb,   
            Dqs      => open,    
            Dq_Io    => nand_data(7 downto 0),     
            Cle      => nand_cle,     
            Ale      => nand_ale,
            Wr_Re_n  => nand_nre,
            Wp_n     => nand_nwp
        );   
  
         
	CLOCK:process
	begin
		clk <= '1';
		wait for 25ns;
		clk <= '0';
		wait for 25ns;
	end process;

	TP1: process
	begin
	   enable <= '0';
	   --wait for 134000ns;
	   wait for 100us;
	end process TP1;

-- start of simulation
	TP2: process
	begin
	   activate <= '0';
	   nreset <= '1';
	   wait for 250ns;
	   nreset <= '0';
	   wait for 50ns;
	   nreset <= '1';
	   wait for 50ns;
	   wait for 20000ns; -- powerup
	
	--reset the flash controller
	   wait for 400ns;
	   cmd_in <= x"00";
	   activate <= '1';
	   wait for 400ns;
	   activate <= '0';
	   wait for 10000ns;
	   --wait until busy = '0';
	
		--Enable the chip
	   --wait for 5ns;
	   cmd_in <= x"09";
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   	   	
	--We need a NAND RESET 
	   wait for 5us;
	   cmd_in <= x"01";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   wait until busy = '0'; 
	   wait for 5us;
	
   
	    --Read device(nand) ID
	    cmd_in <= x"03";
	   data_in <= x"00";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 5us; 
	   

	   --Read the bytes of the ID
	   cmd_in <= x"0E";
	   --1
	    wait for 50ns;
	   --wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --2
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
		   --3
	   activate <= '1';
	    wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   	   --4
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   	   --5
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 5us;
	 
	 	 --nand param page
	   cmd_in <= x"02";
	   data_in <= x"00";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 150us;  

	   --ONFI controller status
	   cmd_in <= x"08";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 500ns;   
     
	    --set address
	   cmd_in <= x"13";
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
		  --2 
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --3
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --4
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --5
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 100ns;
	   
	   	 	 --reset index
	   cmd_in <= x"0D";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 500ns;  
	   
	   --set data bytes
	   cmd_in <= x"11";
	   data_in <= x"01";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
		  --2 
	   data_in <= x"02";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --3
	   data_in <= x"03";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --4
	   data_in <= x"04";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --5
	   data_in <= x"05";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;   

-- nand write protect
	   cmd_in <= x"0C";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 100ns;
	   	 
	   --write to nand
	   cmd_in <= x"07";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 4ms;    
   
		-- nand write protect
	   cmd_in <= x"0B";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 100ns; 
	    
	 	 --reset index
	   cmd_in <= x"0D";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 500ns;  
	   
	 	--set address read
	   cmd_in <= x"13";
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
		  --2 
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --3
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --4
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 50ns;
	   --5
	   data_in <= x"00";
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 100ns;
	  
	  	--read from nand
	   cmd_in <= x"06";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 3.5ms;   

		--reset index
	   cmd_in <= x"0D";
	   wait for 50ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 500ns;  
	 
		--nand status
	   cmd_in <= x"05";
	   wait for 100ns;
	   activate <= '1';
	   wait for 50ns;
	   activate <= '0';
	   wait for 1us; 
	   
		wait;
	end process;
 
end test;
