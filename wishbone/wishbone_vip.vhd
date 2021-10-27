-- Simple wishbone verification IP
-- For use with GHDL only
-- Suitable for simulation & formal verification
-- Copyright 2021 by Torsten Meissner (programming@goodcleanfun.de)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library wishbone;
use wishbone.wishbone_pkg.all;



entity wishbone_vip is
  generic (
    MODE     : string  := "CLASSIC";
    ASSERTS  : boolean := true;
    COVERAGE : boolean := true
  );
  port (
    -- syscon signals
    WbSysCon : in t_wb_syscon;
    -- master signals
    WbMaster : in t_wb_master;
    -- slave signals
    WbSlave  : in t_wb_slave
  );
end entity wishbone_vip;



architecture verification of wishbone_vip is


  function count_ones (data : in std_logic_vector) return natural is
    variable v_return : natural := 0;
  begin
    for i in data'range loop
      if (to_x01(data(i)) = '1') then
        v_return := v_return + 1;
      end if;
    end loop;
    return v_return;
  end function count_ones;

  function one_hot (data : in std_logic_vector) return boolean is
  begin
    return count_ones(data) = 1;
  end function one_hot;

  function one_hot_0 (data : in std_logic_vector) return boolean is
  begin
    return count_ones(data) <= 1;
  end function one_hot_0;

  alias Clk is WbSysCon.Clk;
  alias Reset is WbSysCon.Reset;

  signal s_wb_slave_resp : std_logic_vector(2 downto 0);


begin


  s_wb_slave_resp <= WbSlave.Rty & WbSlave.Err & WbSlave.Ack;

  -- Static interface checks
  -- Always enabled, regardless of generic ASSERTS setting

  MODE_a : assert MODE = "CLASSIC"
    report "ERROR: Unsupported mode"
    severity failure;

  DATA_MS_WIDTH_a : assert WbMaster.Dat'length = 8 or WbMaster.Dat'length = 16 or
                           WbMaster.Dat'length = 32 or WbMaster.Dat'length = 64
    report "ERROR: Invalid Master Data length"
    severity failure;

  DATA_SM_WIDTH_a : assert WbSlave.Dat'length = 8 or WbSlave.Dat'length = 16 or
                           WbSlave.Dat'length = 32 or WbSlave.Dat'length = 64
    report "ERROR: Invalid Slave Data length"
    severity failure;

  DATA_EQUAL_WIDTH_a : assert WbMaster.Dat'length = WbSlave.Dat'length
    report "ERROR: Master & Slave Data don't have equal length"
    severity failure;


  default clock is rising_edge(Clk);

  ASSERTS_G : if ASSERTS generate

    signal s_wb_master : t_wb_master(Adr(WbMaster.Adr'range),
                                     Dat(WbMaster.Dat'range),
                                     Sel(WbMaster.Sel'range),
                                     Tgc(WbMaster.Tgc'range),
                                     Tga(WbMaster.Tga'range),
                                     Tgd(WbMaster.Tgd'range));
    signal s_wb_slave : t_wb_slave(Dat(WbSlave.Dat'range),
                                   Tgd(WbSlave.Tgd'range));

  begin

    -- Create copies of bus signals
    process (Clk) is
    begin
      if rising_edge(Clk) then
        s_wb_master <= WbMaster;
        s_wb_slave  <= WbSlave;
      end if;
    end process;

    -- RULE 3.20
    STB_RESET_a : assert always Reset -> not WbMaster.Stb;
    CYC_RESET_a : assert always Reset -> not WbMaster.Cyc;
  
    -- RULE 3.25
    STB_CYC_a : assert always WbMaster.Stb -> WbMaster.Cyc;
  
    -- RULE 3.45
    ACK_ERR_RTY_ONEHOT_a : assert always one_hot_0(s_wb_slave_resp);
  
    -- RULE 3.50
    ACK_ERR_RTY_STB_a : assert always or s_wb_slave_resp -> WbMaster.Stb;

    DAT_STABLE_STB_a : assert always WbMaster.Stb and s_wb_slave_resp = "000" ->
      next (WbMaster.Dat = s_wb_master.Dat);

  end generate ASSERTS_G;


  COVERAGE_G : if COVERAGE generate

    sequence s_single_read (boolean resp) is {
      not WbMaster.Cyc;
      WbMaster.Cyc and not WbMaster.Stb[*];
      {s_wb_slave_resp = "000"[*]; resp} &&
      {WbMaster.Cyc and WbMaster.Stb and not WbMaster.We}[+]
    };

    sequence s_single_write (boolean resp) is {
      not WbMaster.Cyc;
      WbMaster.Cyc and not WbMaster.Stb[*];
      {s_wb_slave_resp = "000"[*]; resp} &&
      {WbMaster.Cyc and WbMaster.Stb and WbMaster.We}[+]
    };

    SINGLE_READ_ACKED_c : cover s_single_read(WbSlave.Ack)
      report "Single read with ack finished";

    SINGLE_READ_ERROR_c : cover s_single_read(WbSlave.Err)
      report "Single read with error finished";

    SINGLE_READ_RETRY_c : cover s_single_read(WbSlave.Rty)
      report "Single read with retry finished";

    SINGLE_WRITE_ACKED_c : cover s_single_write(WbSlave.Ack)
      report "Single read with ack finished";

    SINGLE_WRITE_ERROR_c : cover s_single_write(WbSlave.Err)
      report "Single read with error finished";

    SINGLE_WRITE_RETRY_c : cover s_single_write(WbSlave.Rty)
      report "Single read with retry finished";

  end generate COVERAGE_G;


end architecture verification;
