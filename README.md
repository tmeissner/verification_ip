The original repository is now located on my own git-server at [https://git.goodcleanfun.de/tmeissner/verification_ip](https://git.goodcleanfun.de/tmeissner/verification_ip)
It is mirrored to github with every push, so both should be in sync.

# verification_ip

Verification IPs for simulation & formal verification of various selected protocols. All tests are done with [GHDL](https://github.com/ghdl/ghdl) and  [SymbiYosys](https://github.com/YosysHQ/SymbiYosys), a front-end for formal verification flows based on [Yosys](https://github.com/YosysHQ/yosys).

*The components in this repository are not intended as productional code. They are created out of personal interest and to find out what one can achieve with current state of open source tools, expecially in the VHDL domain.*

### wishbone
Simple VIP for the wishbone bus protocol. First goal is functional coverage to detect valid transfer cycles and their variants. Currently support of classic single read / write cycles only.
