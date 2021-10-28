-- Simple wishbone verification IP
-- For use with GHDL only
-- Suitable for simulation & formal verification
-- Copyright 2021 by Torsten Meissner (programming@goodcleanfun.de)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package wishbone_pkg is


  type t_slv_array is array (natural range <>) of std_logic_vector;

  type t_wb_syscon is record
    Reset : std_logic;
    Clk   : std_logic;
  end record;

  type t_wb_master is record
    Cyc  : std_logic;
    Stb  : std_logic;
    We   : std_logic;
    Lock : std_logic;
    Adr  : std_logic_vector;
    Dat  : std_logic_vector;
    Sel  : std_logic_vector;
    Tgc  : std_logic_vector;
    Tga  : std_logic_vector;
    Tgd  : std_logic_vector;
  end record;

  type t_wb_slave is record
    Ack  : std_logic;
    Err  : std_logic;
    Rty  : std_logic;
    Dat  : std_logic_vector;
    Tgd  : std_logic_vector;
  end record;


  function to_string(wb : t_wb_master) return string;
  function to_string(wb : t_wb_slave) return string;

  procedure log_wishbone (signal clk : std_logic; master : t_wb_master; slave : t_wb_slave);


  procedure cycle (signal syscon : in  t_wb_syscon;
                   signal master : out t_wb_master;
                   signal slave  : in  t_wb_slave;
                          Wen    : in  std_logic;
                          Adr    : in  std_logic_vector;
                          WDat   : in  std_logic_vector;
                          RDat   : out std_logic_vector);

  procedure single_cycle (signal syscon : in  t_wb_syscon;
                          signal master : out t_wb_master;
                          signal slave  : in  t_wb_slave;
                                 Wen    : in  std_logic;
                                 Adr    : in  std_logic_vector;
                                 WDat   : in  std_logic_vector;
                                 RDat   : out std_logic_vector);

  procedure block_cycle (signal syscon : in  t_wb_syscon;
                         signal master : out t_wb_master;
                         signal slave  : in  t_wb_slave;
                                Wen    : in  std_logic;
                                Adr    : in  t_slv_array;
                                WDat   : in  t_slv_array;
                                RDat   : out t_slv_array);

end package wishbone_pkg;



package body wishbone_pkg is


  procedure cycle (signal syscon : in  t_wb_syscon;
                   signal master : out t_wb_master;
                   signal slave  : in  t_wb_slave;
                          Wen    : in  std_logic;
                          Adr    : in  std_logic_vector;
                          WDat   : in  std_logic_vector;
                          RDat   : out std_logic_vector) is
  begin
    master.Cyc <= '1';
    master.Stb <= '1';
    master.We  <= Wen;
    master.Adr <= Adr;
    master.Dat <= WDat;
    wait until rising_edge(syscon.Clk) and (slave.Ack or slave.Err or slave.Rty) = '1';
    RDat := slave.Dat;
  end procedure cycle;

  procedure single_cycle (signal syscon : in  t_wb_syscon;
                          signal master : out t_wb_master;
                          signal slave  : in  t_wb_slave;
                                 Wen    : in  std_logic;
                                 Adr    : in  std_logic_vector;
                                 WDat   : in  std_logic_vector;
                                 RDat   : out std_logic_vector) is
  begin
    cycle(syscon, master, slave, Wen, Adr, WDat, RDat);
    master.Cyc <= '0';
    master.Stb <= '0';
    master.We  <= '0';
    master.Adr <= (master.Adr'range => '0');
    master.Dat <= (master.Dat'range => '0');
    wait until rising_edge(syscon.Clk);
  end procedure single_cycle;

  procedure block_cycle (signal syscon : in  t_wb_syscon;
                         signal master : out t_wb_master;
                         signal slave  : in  t_wb_slave;
                                Wen    : in  std_logic;
                                Adr    : in  t_slv_array;
                                WDat   : in  t_slv_array;
                                RDat   : out t_slv_array) is
  begin
    assert Adr'length = WDat'length and WDat'length = RDat'length;
    for i in Adr'low to Adr'high-1 loop
      cycle(syscon, master, slave, Wen, Adr(i), WDat(i), RDat(i));
    end loop;
    single_cycle(syscon, master, slave, Wen, Adr(Adr'high), WDat(WDat'high), RDat(RDat'high));
  end procedure block_cycle;

  function to_string(wb : t_wb_master) return string is
  begin
    return "Cyc:  " & to_string(wb.Cyc)  & LF &
           "Stb:  " & to_string(wb.Stb)  & LF &
           "We:   " & to_string(wb.We)   & LF &
           "Lock: " & to_string(wb.Lock) & LF &
           "Adr:  " & to_hstring(wb.Adr)  & LF &
           "Dat:  " & to_hstring(wb.Dat)  & LF &
           "Sel:  " & to_hstring(wb.Sel)  & LF &
           "Tgc:  " & to_hstring(wb.Tgc)  & LF &
           "Tga:  " & to_hstring(wb.Tga)  & LF &
           "Tgd:  " & to_hstring(wb.Tgd);
  end function to_string;

  function to_string(wb : t_wb_slave) return string is
  begin
    return "Ack: " & to_string(wb.Ack) & LF &
           "Err: " & to_string(wb.Err) & LF &
           "Rty: " & to_string(wb.Rty) & LF &
           "Dat: " & to_hstring(wb.Dat) & LF &
           "Tgd: " & to_hstring(wb.Tgd);
  end function to_string;

  procedure log_wishbone (signal clk : std_logic; master : t_wb_master; slave : t_wb_slave) is
  begin
    wait until rising_edge(clk);
    report "Wishbone master:" & LF & to_string(master);
    report "Wishbone slave:" & LF & to_string(slave);
  end procedure log_wishbone;


end package body wishbone_pkg;
