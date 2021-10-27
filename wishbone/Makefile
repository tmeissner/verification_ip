.PHONY: sim clean

wishbone_tb: wishbone_pkg.vhd wishbone_vip.vhd wishbone_tb.vhd
	ghdl -a --std=08 --work=wishbone wishbone_pkg.vhd wishbone_vip.vhd
	ghdl -a --std=08 wishbone_tb.vhd
	ghdl -e --std=08 wishbone_tb

sim: wishbone_tb
	./wishbone_tb --wave=$<.ghw --psl-report=$<.json

clean:
	rm -rf *.o *.cf *.ghw *.json
	rm -rf wishbone_tb
