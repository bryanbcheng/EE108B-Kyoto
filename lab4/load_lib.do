vmap unisims_ver /afs/ir.stanford.edu/class/ee/mentor/vsim66/modeltech/xilinx_libs/unisims_ver
vmap xilinxcorelib_ver /afs/ir.stanford.edu/class/ee/mentor/vsim66/modeltech/xilinx_libs/xilinxcorelib_ver

vsim -L xilinxcorelib_ver -L unisims_ver -t 1ps {-voptargs=+acc=bcglnprst -O0} work.MIPStest
