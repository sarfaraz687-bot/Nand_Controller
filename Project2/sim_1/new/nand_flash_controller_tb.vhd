library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity nand_flash_controller_tb is
end entity nand_flash_controller_tb;

architecture behavior of nand_flash_controller_tb is

  -- Constants
  constant c_fifo_depth : integer := 256;
  constant c_clk_period : time := 10 ns;

  -- Signals for nand_flash_controller
  signal rstn_i          : std_logic := '0';
  signal clk_i           : std_logic := '0';
  signal col_add_1_i     : std_logic_vector(7 downto 0) := (others => '0');
  signal col_add_2_i     : std_logic_vector(7 downto 0) := (others => '0');
  signal row_add_1_i     : std_logic_vector(7 downto 0) := (others => '0');
  signal row_add_2_i     : std_logic_vector(7 downto 0) := (others => '0');
  signal row_add_3_i     : std_logic_vector(7 downto 0) := (others => '0');
  signal wr_data_i       : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_size_i       : std_logic_vector(31 downto 0) := (others => '0');
  signal wr_rqst_i       : std_logic := '0';
  signal wr_fifo_full_i  : std_logic;
  signal rd_rqst_i       : std_logic := '0';
  signal rd_fifo_empty_o : std_logic;
  signal erase_block_i   : std_logic;
  signal rd_data_o       : std_logic_vector(7 downto 0);
  signal wr_busy_o       : std_logic;
  signal rd_busy_o       : std_logic;
  signal erase_busy_o    : std_logic;
  signal init_done_o     : std_logic;
  
  -- Signals for nand_model
  signal dq_io_i   : std_logic_vector(7 downto 0) := (others => 'Z');
  signal memory_id_o   : std_logic_vector(47 downto 0) := (others => 'Z');
  signal dq_io     : std_logic_vector(7 downto 0) := (others => 'Z');
  signal dq_oe_o   : std_logic;
  signal dq_io_o   : std_logic_vector(7 downto 0);
  signal cle_o     : std_logic;
  signal ale_o     : std_logic;
  signal clk_We_n_o: std_logic;
  signal wr_Re_n_o : std_logic;
  signal ce_n_o    : std_logic;
  signal wp_n_o    : std_logic;
  signal rb_n_i    : std_logic;
  signal rd_cmd_i    : std_logic;

begin

  -- Clock generation
  clk_process : process
  begin
    while true loop
      clk_i <= '0';
      wait for c_clk_period / 2;
      clk_i <= '1';
      wait for c_clk_period / 2;
    end loop;
  end process clk_process;

  -- Instantiate the nand_flash_controller component
  uut: entity work.nand_flash_controller
    generic map(
      g_fifo_depth => c_fifo_depth
    )
    port map(
      rstn_i           => rstn_i,
      clk_i            => clk_i,
      col_add_1_i      => col_add_1_i,
      col_add_2_i      => col_add_2_i,
      row_add_1_i      => row_add_1_i,
      row_add_2_i      => row_add_2_i,
      row_add_3_i      => row_add_3_i,
      wr_data_i        => wr_data_i,
      rd_size_i        => rd_size_i,
      wr_rqst_i        => wr_rqst_i,
      wr_fifo_full_i   => wr_fifo_full_i,
      rd_byte_i        => rd_rqst_i,
      rd_cmd_i         => rd_cmd_i,
      erase_block_i    => erase_block_i,
      rd_fifo_empty_o  => rd_fifo_empty_o,
      memory_id_o      => memory_id_o,
      rd_data_o        => rd_data_o,
      wr_busy_o        => wr_busy_o,
      rd_busy_o        => rd_busy_o,
      erase_busy_o     => erase_busy_o,
      init_done_o      => init_done_o,
      dq_io_i          => dq_io_i,
      dq_oe_o          => dq_oe_o,
      dq_io_o          => dq_io_o,
      cle_o            => cle_o,
      ale_o            => ale_o,
      clk_We_n_o       => clk_We_n_o,
      wr_Re_n_o        => wr_Re_n_o,
      ce_n_o           => ce_n_o,
      wp_n_o           => wp_n_o,
      rb_n_i           => rb_n_i
    );
  
  dq_io <= dq_io_o when dq_oe_o='1' else "ZZZZZZZZ";
  
  dq_io_i <= dq_io when dq_oe_o='0' else "00000000";
  -- Instantiate the nand_model component
  nand_memory: entity work.nand_model
    port map(
      Dq_Io   => dq_io,
      Dqs     => open,
      Cle     => cle_o,
      Ale     => ale_o,
      Clk_We_n=> clk_We_n_o,
      Wr_Re_n => wr_Re_n_o,
      Ce_n    => ce_n_o,
      Wp_n    => wp_n_o,
      Rb_n    => rb_n_i
    );

  -- Stimulus process
  stimulus: process
  begin
    -- Reset the nand_flash_controller
    rstn_i <= '0';
    wait for 100 ns;
    rstn_i <= '1';
    wait for 100 ns;
    
    -- wait until the memory controller initialize the nand flash
    wait until init_done_o='1';
    
    -- set a col/row address to the controller
    col_add_1_i <= x"00";
    col_add_2_i <= x"00";
    row_add_1_i <= x"00";
    row_add_2_i <= x"01";
    row_add_3_i <= x"01";
    
    -- fill the transmit fifo with 256 bytes
    for i in 0 to 1023 loop
      --* if the fifo is full wait until it is not full then continue writing to the fifo
      while(wr_fifo_full_i='1')loop
        wr_rqst_i <= '0';
        wait until rising_edge(clk_i);
      end loop;
      wr_data_i <= std_logic_vector(to_unsigned(i, 8));
      wr_rqst_i <= '1';
      wait until rising_edge(clk_i);
    end loop;
    wr_rqst_i <= '0';
    wait until wr_busy_o ='0';
    
    -- send command and read  bytes in fifo
    rd_size_i <= std_logic_vector(to_unsigned(1024, 32));
    rd_cmd_i <= '1';
    wait until rd_busy_o = '1';
    rd_cmd_i <= '0';
    wait until rd_busy_o = '0';
    wait until rising_edge(clk_i);
    
    for i in 0 to 255 loop
      rd_rqst_i <= '1';
      wait until rising_edge(clk_i);
    end loop;
    rd_rqst_i <= '0';
    
    -- erase operation
    erase_block_i <= '1';
    wait until erase_busy_o = '1';
    erase_block_i <= '0';
    
    wait until erase_busy_o = '0';
    
    -- send read request to read again from memory
    rd_cmd_i <= '1';
    wait until rd_busy_o = '1';
    rd_cmd_i <= '0';
    wait until rd_busy_o = '0';
    wait until rising_edge(clk_i);
    
    -- read the values from receive fifo
    for i in 0 to 255 loop
      rd_rqst_i <= '1';
      wait until rising_edge(clk_i);
    end loop;
    rd_rqst_i <= '0';
    stop;
    wait;
  end process stimulus;

end architecture behavior;
