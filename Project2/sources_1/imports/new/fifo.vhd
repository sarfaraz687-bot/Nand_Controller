----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/13/2024 12:10:39 PM
-- Design Name: 
-- Module Name: fifo - Behavioral
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

entity fifo is
  generic(
    g_data_width : integer := 8;
    g_fifo_depth : integer := 16;
    --*
    g_fwft : boolean := true);
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
end fifo;

architecture Behavioral of fifo is

  function f_log2( depth : natural) return integer is
    variable temp    : integer := depth;
    variable ret_val : integer := 0;
  begin
    while temp > 1 loop
        ret_val := ret_val + 1;
        temp    := temp / 2;
    end loop;
    return ret_val;
  end function f_log2;
  
  type t_array_type is array(0 to g_fifo_depth-1) of std_logic_vector(g_data_width-1 downto 0);
  
  signal s_memory : t_array_type;
  
  signal s_wr_ptr : unsigned(f_log2(g_fifo_depth) downto 0);
  signal s_rd_ptr : unsigned(f_log2(g_fifo_depth) downto 0);
  signal s_ptr_diffrence : unsigned(f_log2(g_fifo_depth) downto 0);

  signal s_full_flag  : std_logic;
  signal s_empty_flag : std_logic;
begin

  fifo_full_o <= s_full_flag;
  fifo_empty_o <= s_empty_flag;
  
  
  s_empty_flag <= '1' when s_ptr_diffrence(f_log2(g_fifo_depth) downto 0) = 0 else '0';
  s_full_flag  <= '1' when s_ptr_diffrence(f_log2(g_fifo_depth) downto 0) = g_fifo_depth else '0';

  s_ptr_diffrence <= s_wr_ptr - s_rd_ptr;
  
  proc_ptr_ctrl : process(clk_i)
  begin
    if rising_edge(clk_i)then
      if rstn_i='0' then
        s_wr_ptr <= (others=>'0');
        s_rd_ptr <= (others=>'0');
      else
        
        if(s_full_flag='0')then
          if(wr_en_i='1')then
            s_wr_ptr <= s_wr_ptr + 1;
            s_memory(to_integer(s_wr_ptr(f_log2(g_fifo_depth)-1 downto 0))) <= data_i;
          end if;
        end if;

        if(s_empty_flag='0')then
          if(rd_en_i='1')then
              s_rd_ptr <= s_rd_ptr + 1;
          end if;
        end if;
        
--        if(g_fwft=true)then
--          data_o <=   s_memory(to_integer(s_rd_ptr(f_log2(g_fifo_depth)-1 downto 0)));
--        else
--          if(rd_en_i='1' and s_empty_flag='0')then
--            data_o <=   s_memory(to_integer(s_rd_ptr(f_log2(g_fifo_depth)-1 downto 0)));
--          end if;
--        end if;
      end if;
    end if;
  end process proc_ptr_ctrl;
  

  gen_read_mode : if(g_fwft=true) generate
  
    proc_read : process(clk_i)
    begin
      if rising_edge(clk_i)then 
        if(rd_en_i='1' and s_empty_flag='0')then
          data_o <=   s_memory(to_integer(s_rd_ptr(f_log2(g_fifo_depth)-1 downto 0)));
        end if;
      end if;
    end process proc_read;
    
  else generate
  
     data_o <=   s_memory(to_integer(s_rd_ptr(f_log2(g_fifo_depth)-1 downto 0)));
  
  end generate gen_read_mode;  
end Behavioral;
