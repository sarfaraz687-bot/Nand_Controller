----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/17/2024 11:00:59 PM
-- Design Name: 
-- Module Name: nan_flash_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity nand_flash_controller is
  generic(
  g_fifo_depth : integer := 256);
    Port ( 
           -- active low reset
           rstn_i : in std_logic;
           --* controller clock
           clk_i   : in std_logic;
           
           -- address for the NAND FLASH
           col_add_1_i  : in std_logic_vector(7 downto 0);
           col_add_2_i  : in std_logic_vector(7 downto 0);
           row_add_1_i  : in std_logic_vector(7 downto 0);
           row_add_2_i  : in std_logic_vector(7 downto 0);
           row_add_3_i  : in std_logic_vector(7 downto 0);
           
           --*******************************************
           -- write ports:
    
           -- write data to be written in the flash memory
           wr_data_i    : in std_logic_vector(7 downto 0);
           wr_rqst_i    : in std_logic;
           wr_fifo_full_i : out std_logic;
           wr_busy_o   : out std_logic;
           
            --*******************************************
           -- read ports:          
           
           rd_size_i    : in std_logic_vector(31 downto 0);
           rd_cmd_i       : in std_logic;
           rd_byte_i      : in std_logic;
           rd_fifo_empty_o : out std_logic;
           rd_data_o   : out std_logic_vector(7 downto 0);
           rd_busy_o   : out std_logic;
  
           --*******************************************
           -- erase ports:             
           
           erase_block_i  : in std_logic;
           erase_busy_o : out std_logic;
           
           -- Memory ID
           memory_id_o : out std_logic_vector(47 downto 0);
           
           
           -- controller initialization done
           init_done_o : out std_logic;
           
           -- nand flash interface ports
           dq_io_i   : in  std_logic_vector(7 downto 0); 
           dq_oe_o   : out std_logic;   
           dq_io_o   : out std_logic_vector(7 downto 0);   
           cle_o     : out std_logic;     
           ale_o     : out std_logic;     
           clk_We_n_o: out std_logic; 
           wr_Re_n_o : out std_logic;  
           --Dqs     
           ce_n_o     : out std_logic;    
           wp_n_o     : out std_logic;    
           rb_n_i     : in std_logic    
           );
end nand_flash_controller;

architecture Behavioral of nand_flash_controller is

  component fifo is
  generic(
    g_data_width : integer := 8;
    g_fifo_depth : integer := 256;
    --*
    g_fwft : boolean := false);
  port ( 
    clk_i : in std_logic;
    rstn_i : in std_logic;
    wr_en_i : in std_logic;
    rd_en_i : in std_logic;
    data_i : in std_logic_vector(g_data_width-1 downto 0);
    
    fifo_full_o : out std_logic;
    fifo_empty_o : out std_logic;
    data_o : out std_logic_vector(g_data_width-1 downto 0)
    );
  end component fifo;


  signal s_delay_cnt : integer range 0 to 15 := 0;
  
  signal s_tx_fifo_rd_ena : std_logic;
--  signal s_wr_fifo_full   : std_logic;
  signal s_tx_fifo_data_i : std_logic_vector(7 downto 0);
  
  signal s_tx_fifo_empty  : std_logic;
--  signal tx_fifo_full_i   : std_logic;
  signal s_rx_fifo_wr_ena   : std_logic;
  signal s_rx_fifo_full     : std_logic;
  
  signal s_tx_fifo_data_o : std_logic_vector(7 downto 0);
  signal s_rx_fifo_data_i : std_logic_vector(7 downto 0);
  
  type t_address_type is array(0 to 5) of std_logic_vector(7 downto 0);
  
  signal s_address : t_address_type;
  
  signal s_id_register : std_logic_vector(47 downto 0);
  signal s_rd_cnt  : unsigned(31 downto 0);
  signal s_address_index : integer range 0 to 5;
  type t_state_type is (idle_st, init_st, reset_cmd_s0_st,
  reset_cmd_s1_st, reset_cmd_s2_st, reset_cmd_s3_st, 
  rd_id_s0_st, rd_id_s1_st, rd_id_s2_st, rd_id_s3_st, 
  rd_id_s4_st,
  wait_op_st,
  prog_page_start_st, wr_address_st, prog_page_close_st, wr_data_st, 
  wait_rb_s0_st, wait_rb_s1_st,
  rd_page_start_st, rd_page_close_st, rd_address_st,
  erase_block_start_st, erase_block_close_st,
  erase_address_st,
  rd_data_st
  );
  
  signal s_state, s_nxt_state : t_state_type;
begin
 -- trnsmit fifo
 inst_tx_fifo: fifo
    generic map(
      g_data_width => 8,
      g_fifo_depth => g_fifo_depth,
      g_fwft       => true 
    )
    port map(
      clk_i       => clk_i,
      rstn_i      => rstn_i,
      wr_en_i     => wr_rqst_i,
      rd_en_i     => s_tx_fifo_rd_ena,
      data_i      => wr_data_i,
      fifo_full_o => wr_fifo_full_i,
      fifo_empty_o=> s_tx_fifo_empty,
      data_o      => s_tx_fifo_data_o
    );
    
 -- receive fifo
 inst_rx_fifo: fifo
    generic map(
      g_data_width => 8,
      g_fifo_depth => 1024,
      g_fwft       => false 
    )
    port map(
      clk_i       => clk_i,
      rstn_i      => rstn_i,
      wr_en_i     => s_rx_fifo_wr_ena,
      rd_en_i     => rd_byte_i,
      data_i      => s_rx_fifo_data_i,
      fifo_full_o => s_rx_fifo_full,
      fifo_empty_o=> rd_fifo_empty_o,
      data_o      => rd_data_o
    );
    
    -- prepare the address for the fsm
    s_address(0) <= col_add_1_i;
    s_address(1) <= col_add_2_i;
    s_address(2) <= row_add_1_i;
    s_address(3) <= row_add_2_i;
    s_address(4) <= row_add_3_i;
    
    memory_id_o <= s_id_register;
    
    proc_fsm : process(clk_i)
    begin
    
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        s_state <= idle_st;
      else
        case s_state is
          when idle_st =>
            s_address_index <= 0;
            wr_busy_o <= '0';
            rd_busy_o <= '0';
            erase_busy_o <= '0';
            s_delay_cnt <= 0;
            init_done_o <= '0';
            s_tx_fifo_rd_ena <= '0';
            ale_o   <= '0';
	          ce_n_o  <= '1';
	          cle_o   <= '0';
	          clk_We_n_o <= '1';
	          wp_n_o     <= '1';
	          wr_Re_n_o  <= '1';
	          if(rb_n_i/='1')then
	            s_state <= init_st;
	          end if;
	          
	        when init_st =>
	          if(rb_n_i='1')then
	            s_state <= reset_cmd_s0_st;
	          end if;	          
	        
	        --**********************************
	        --     send reset command states
	        --**********************************
	        when reset_cmd_s0_st =>
	          dq_oe_o   <= '1'; -- control the tri state buffer to be output
	          dq_io_o   <= x"ff"; -- set command to FF
	          ce_n_o  <= '0';
	          cle_o   <= '1';	      
	          clk_We_n_o <= '0';
	          if(s_delay_cnt=6)then -- time delay
	            s_delay_cnt <= 0;
	            s_state <= reset_cmd_s1_st;
	          else
	            s_delay_cnt <= s_delay_cnt + 1;
	          end if;
          
	        when reset_cmd_s1_st =>    
	          clk_We_n_o <= '1'; -- set clk to 1
	          if(s_delay_cnt=4)then
	            s_delay_cnt <= 0;
	            s_state <= reset_cmd_s2_st;
	          else
	            s_delay_cnt <= s_delay_cnt + 1;
	          end if;

	        when reset_cmd_s2_st =>  
	          dq_oe_o <= '0';
	          cle_o   <= '0';	 
	          if(rb_n_i/='1')then -- wait the memory to be busy
	            s_state <= reset_cmd_s3_st;
	          end if;
	          
	        when reset_cmd_s3_st =>  
	          if(rb_n_i='1')then -- wait the memory to be idle
	            
--	            s_state <= wait_op_st;
	            s_state <= rd_id_s0_st;
	          end if;
	        
	        --**********************************
	        --       read ID states
	        --**********************************	        
	        when rd_id_s0_st =>
	         cle_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"90"; -- ID command
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= rd_id_s1_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         if(s_delay_cnt < 5) then -- generate we clock
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	         
	        when rd_id_s1_st =>
	         cle_o   <= '0';
	         ale_o   <= '1'; -- apply address control signal
	         dq_oe_o <= '1';
	         dq_io_o     <= x"00"; -- ID ADDRESS
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= rd_id_s2_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;

	      when rd_id_s2_st =>
	         cle_o   <= '0';
	         ale_o   <= '0';
	         dq_oe_o <= '0';
	         if(s_delay_cnt=9)then -- time delay
	           s_delay_cnt <= 0;
	           s_state <= rd_id_s3_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;	
	         
	      when rd_id_s3_st =>
	         cle_o   <= '0';
	         ale_o   <= '0';
	         dq_oe_o <= '0';
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_address_index=5)then
	             s_address_index <= 0;
	             s_state <= rd_id_s4_st;
	           else
	             s_address_index <= s_address_index + 1;
	           end if;	
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;	
           -- shift in the ID bytes that is read
	         if(s_delay_cnt=5)then
	           s_id_register <= dq_io_i & s_id_register(47 downto 8);
	         end if;
	         -- generate read clock
	         if(s_delay_cnt < 5) then
	           wr_Re_n_o <= '0';
	         else
	           wr_Re_n_o <= '1';
	         end if; 

	      when rd_id_s4_st =>
	         cle_o   <= '0';
	         ale_o   <= '0';
	         dq_oe_o <= '0';
	         if(s_delay_cnt=15)then
	           s_delay_cnt <= 0;
	           init_done_o <= '1';
	           s_state <= wait_op_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;	

	        --**********************************
	        --   wait for operation from host
	        --**********************************	         	         	         	           
	        when wait_op_st =>
	          wr_busy_o <= '0';
	          rd_busy_o <= '0';
	          erase_busy_o <= '0';
	          if(erase_block_i='1')then -- erase block request from host
	            erase_busy_o <= '1';
	            s_address_index <= 2;
	            s_state <= erase_block_start_st;
	          elsif(s_tx_fifo_empty='0')then -- data in transmit fifo available for page program
	            wr_busy_o <= '1';
	            s_state <= prog_page_start_st;
	          elsif(rd_cmd_i='1')then -- read page request from host
	            rd_busy_o <= '1';
	            s_rd_cnt <= unsigned(rd_size_i); -- number of bytes required to be read
	            s_state <= rd_page_start_st;
	          end if;
	          
	        --**********************************
	        --       programe page states
	        --**********************************		          
	        when prog_page_start_st =>
	         cle_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"80"; -- programe page command
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= wr_address_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
          
          -- send the address for the page to be programmed
	        when wr_address_st =>
	         cle_o   <= '0';
	         ale_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= s_address(s_address_index);
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_address_index=4)then
	             s_address_index <= 0;
	             s_state <= wr_data_st;
	           else
	             s_address_index <= s_address_index + 1;
	           end if;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	        
	        -- send the data of the page to be programmed 
	        when wr_data_st =>
	         cle_o   <= '0';
	         ale_o   <= '0';
	         dq_oe_o <= '1';
	         dq_io_o     <= s_tx_fifo_data_o;
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_tx_fifo_empty='1')then
	             s_state <= prog_page_close_st;
	           end if;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt=1 and s_tx_fifo_empty='0')then
	           s_tx_fifo_rd_ena <= '1';
	         else
	           s_tx_fifo_rd_ena <= '0';
	         end if;
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	       
	       -- program page close command  
	       when prog_page_close_st =>
	         cle_o   <= '1';
	         ale_o   <= '0';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"10";
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= wait_rb_s0_st;
	           s_nxt_state <= wait_op_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	         
	       when wait_rb_s0_st =>
            cle_o   <= '0';
	          ale_o   <= '0';
	          dq_oe_o <= '0';
	          if(rb_n_i/='1')then
	            s_state <= wait_rb_s1_st;
	          end if;

	       when wait_rb_s1_st =>
	          if(rb_n_i='1')then
	            s_state <= s_nxt_state;
	          end if;	          
	        --**********************************
	        --     read page states
	        --**********************************	
	        when rd_page_start_st =>
	         cle_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"00";
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= rd_address_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;

	        when rd_address_st =>
	         cle_o   <= '0';
	         ale_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= s_address(s_address_index);
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_address_index=4)then
	             s_address_index <= 0;
	             s_state <= rd_page_close_st;
	           else
	             s_address_index <= s_address_index + 1;
	           end if;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	      
	      --* read page close command
	      when rd_page_close_st =>
	         cle_o   <= '1';
	         ale_o   <= '0';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"30";
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= wait_rb_s0_st;
	           s_nxt_state <= rd_data_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;	 
	         
	      when rd_data_st =>
	         cle_o   <= '0';
	         ale_o   <= '0';
	         dq_oe_o <= '0';
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_rd_cnt=0)then
	             s_state <= wait_op_st;
	           else
	             s_rd_cnt <= s_rd_cnt - 1;
	           end if;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;	
	         
	         if(s_delay_cnt=5)then
	           s_rx_fifo_data_i <= dq_io_i;
	           s_rx_fifo_wr_ena <= '1';
	         else
	           s_rx_fifo_wr_ena <= '0';
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           wr_Re_n_o <= '0';
	         else
	           wr_Re_n_o <= '1';
	         end if;      
	         
	        --**********************************
	        --     Erase Block states
	        --**********************************	         
	        when erase_block_start_st =>
	         cle_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"60"; -- erase block command
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= erase_address_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;   
	        
	        -- send erase address (3 rows) 
	        when erase_address_st =>
	         cle_o   <= '0';
	         ale_o   <= '1';
	         dq_oe_o <= '1';
	         dq_io_o     <= s_address(s_address_index);
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           if(s_address_index=4)then
	             s_address_index <= 0;
	             s_state <= erase_block_close_st;
	           else
	             s_address_index <= s_address_index + 1;
	           end if;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;
	      
	      -- erase block close command
	      when erase_block_close_st =>
	         cle_o   <= '1';
	         ale_o   <= '0';
	         dq_oe_o <= '1';
	         dq_io_o     <= x"D0";
	         if(s_delay_cnt=9)then
	           s_delay_cnt <= 0;
	           s_state <= wait_rb_s0_st;
	           s_nxt_state <= wait_op_st;
	         else
	           s_delay_cnt <= s_delay_cnt + 1;
	         end if;
	         
	         if(s_delay_cnt < 5) then
	           clk_We_n_o <= '0';
	         else
	           clk_We_n_o <= '1';
	         end if;	    	       
	      when others => s_state <= idle_st;        	         
        end case;
      end if;
    end if;
    end process;
end Behavioral;