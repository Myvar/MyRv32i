mkdir -p tmp
rm ./run/obj_dir/Vrv32i
cd run
verilator --relative-includes  --cc --exe --build --timing --trace-fst  --top-module rv32i -j 0 -Wno-lint -Wno-selrange -CFLAGS -fpermissive *.cpp ../rtl/*.sv ../rtl/*.v
cd ..
rm run.fst
./run/obj_dir/Vrv32i

