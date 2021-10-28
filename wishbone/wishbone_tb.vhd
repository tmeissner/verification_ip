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

  constant C_CLOCK_PERIOD : time := 2 ns;

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

  alias s_clk   is s_wb_syscon.Clk;
  alias s_reset is s_wb_syscon.Reset;


begin


  s_clk   <= not s_clk after C_CLOCK_PERIOD / 2;
  s_reset <= '0' after 4 ns;

  wb_master_p : process is
    subtype t_wb_array is t_slv_array(0 to 7)(open);
    variable v_wb_adr   : t_wb_array(open)(C_WB_ADDR_WIDTH-1 downto 0);
    variable v_wb_wdata : t_wb_array(open)(C_WB_DATA_WIDTH-1 downto 0);
    variable v_wb_rdata : t_wb_array(open)(C_WB_DATA_WIDTH-1 downto 0);
  begin
    s_wb_master.Cyc <= '0';
    s_wb_master.Stb <= '0';
    wait until s_reset = '0';
    -- single read cycles
    for wait_cycles in 0 to 3 loop
      single_cycle(s_wb_syscon, s_wb_master, s_wb_slave, '0', v_wb_adr(0), v_wb_wdata(0), v_wb_rdata(0));
    end loop;
    -- single write cycles
    for wait_cycles in 0 to 3 loop
      single_cycle(s_wb_syscon, s_wb_master, s_wb_slave, '1', v_wb_adr(0), v_wb_wdata(0), v_wb_rdata(0));
    end loop;
    -- block cycles
    block_cycle(s_wb_syscon, s_wb_master, s_wb_slave, '0', v_wb_adr, v_wb_wdata, v_wb_rdata);
    block_cycle(s_wb_syscon, s_wb_master, s_wb_slave, '1', v_wb_adr, v_wb_wdata, v_wb_rdata);
    wait for 10 ns;
    stop(0);
  end process wb_master_p;


  wb_slave_p : process is
  begin
    s_wb_slave.Rty <= '0';
    s_wb_slave.Err <= '0';
    s_wb_slave.Ack <= '0';
    wait until s_reset = '0';
    loop
      for wait_cycles in 0 to 3 loop
        wait until rising_edge(s_clk) and (s_wb_master.Cyc and s_wb_master.Stb) = '1';
        if wait_cycles /= 0 then
          wait for C_CLOCK_PERIOD * wait_cycles - 1 ps;
          wait until rising_edge(s_clk);
        end if;
        s_wb_slave.Ack <= '1';
        wait until rising_edge(s_clk);
        s_wb_slave.Ack <= '0';
      end loop;
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