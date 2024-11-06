#!/bin/zsh
./build_frimware.sh
python automation/rom.py ./firmware/obj_dir/main.bin > rtl/core/rom/rom.svh
rm ./run/obj_dir/Vrv32i
cd run
svFiles=(
    ../rtl/core/*.sv
    ../rtl/core/rom/*.sv
    ../rtl/core/generated/*.sv
    ../rtl/components/*.sv
    ../rtl/*.sv
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
