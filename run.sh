#!/bin/zsh
./build_frimware.sh
python automation/rom.py ./firmware/obj_dir/test.bin > rtl/core/rom/rom.svh
rm ./run/obj_dir/Vrv32i
cd run
svFiles=(
  ../rtl/rv32i.sv
  ../rtl/core/core.sv
  ../rtl/core/decode.sv
  ../rtl/core/execute.sv
  ../rtl/core/fetch.sv
  ../rtl/core/local_ram.sv
  ../rtl/core/lsu.sv
  ../rtl/core/alu.sv
  ../rtl/core/regs.sv
  ../rtl/core/rom/core_rom.sv
  ../rtl/components/interconnect_1_to_4.sv
  ../rtl/components/arbiter_2_to_1.sv
  ../rtl/components/fifo.sv
)
vFiles=(../rtl/**/*.v)
allFiles=("${svFiles[@]}" "${vFiles[@]}")
verilator -I../rtl/ -relative-includes --cc --exe --build --timing --trace-fst --top-module rv32i -j 0 -Wno-lint -Wno-selrange -CFLAGS -fpermissive *.cpp ${allFiles[@]} -DTESTING=1
built=$?
cd ..
wait
if [ $built -eq 0 ]; then
    #python3.13 talk.py -H localhost -p 8880 --retry-interval 5 --minor-pause 0.0 --major-pause 0.0 --write --check Off -f firmware/obj_dir/main.bin --start-address 0x00000000 -o Fatal,Error,Status,Progress &
    ./run/obj_dir/Vrv32i
    wait
fi
