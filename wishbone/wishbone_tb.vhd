-- Simple wishbone verification IP
-- For use with GHDL only
-- Suitable for simulation & formal verification
-- Copyright 2021 by Torsten Meissner (programming@goodcleanfun.de)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;

library wishbone;
use wishbone.wishbone_pkg.all;



entity wishbone_tb is
end entity wishbone_tb;



architecture testbench of wishbone_tb is


  constant C_WB_ADDR_WIDTH : positive := 32;
  constant C_WB_DATA_WIDTH : positive := 32;
  constant C_WB_SEL_WIDTH  : positive := 4;
  constant C_WB_TGA_WIDTH  : positive := 4;
  constant C_WB_TGC_WIDTH  : positive := 4;
  constant C_WB_TGD_WIDTH  : positive := 4;

  signal s_wb_syscon : t_wb_syscon := ('1', '1');
  signal s_wb_master : t_wb_master(Adr(C_WB_ADDR_WIDTH-1 downto 0),
                                   Dat(C_WB_DATA_WIDTH-1 downto 0),
                                   Sel(C_WB_SEL_WIDTH-1 downto 0),
                                   Tgc(C_WB_TGC_WIDTH-1 downto 0),
                                   Tga(C_WB_TGA_WIDTH-1 downto 0),
                                   Tgd(C_WB_TGD_WIDTH-1 downto 0));
  signal s_wb_slave : t_wb_slave(Dat(C_WB_DATA_WIDTH-1 downto 0),
                                 Tgd(C_WB_TGD_WIDTH-1 downto 0));

  signal s_wb_slave_resp : std_logic_vector(2 downto 0);

  alias s_clk   is s_wb_syscon.Clk;
  alias s_reset is s_wb_syscon.Reset;

begin


  s_clk   <= not s_clk after 1 ns;
  s_reset <= '0' after 4 ns;

  s_wb_slave_resp <= s_wb_slave.Rty & s_wb_slave.Err & s_wb_slave.Ack;

  wb_master_p : process is
  begin
    s_wb_master.Cyc <= '0';
    s_wb_master.Stb <= '0';
    wait until s_reset = '0';
    -- simple reads
    for i in 0 to 2 loop
      wait until rising_edge(s_clk);
      s_wb_master.Cyc <= '1';
      s_wb_master.Stb <= '1';
      s_wb_master.We  <= '0';
      wait until s_wb_slave_resp(i) = '1' and rising_edge(s_clk);
      report "Master: end simple read cycle";
      s_wb_master.Cyc <= '0';
      s_wb_master.Stb <= '0';
    end loop;
    wait for 10 ns;
    stop(0);
  end process wb_master_p;


  wb_slave_p : process is
    variable v_resp : std_logic_vector(2 downto 0) := "000";
  begin
    (s_wb_slave.Rty, s_wb_slave.Err, s_wb_slave.Ack) <= v_resp;
    wait until s_reset = '0';
    -- simple read
    for i in 0 to 2 loop
      wait until (s_wb_master.Cyc and s_wb_master.Stb) = '1' and rising_edge(s_clk);
      v_resp(i) := '1';
      (s_wb_slave.Rty, s_wb_slave.Err, s_wb_slave.Ack) <= v_resp;
      wait until not s_wb_master.Stb;
       v_resp(i) := '0';
      (s_wb_slave.Rty, s_wb_slave.Err, s_wb_slave.Ack) <= v_resp;
    end loop;
    wait;
  end process wb_slave_p;


  i_wishbone_vip : entity wishbone.wishbone_vip
    generic map (
      MODE => "CLASSIC"
    )
    port map (
      WbSysCon => s_wb_syscon, 
      WbMaster => s_wb_master,
      WbSlave  => s_wb_slave
    );


end testbench;