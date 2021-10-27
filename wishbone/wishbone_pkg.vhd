-- Simple wishbone verification IP
-- For use with GHDL only
-- Suitable for simulation & formal verification
-- Copyright 2021 by Torsten Meissner (programming@goodcleanfun.de)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package wishbone_pkg is

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

end package wishbone_pkg;
