import cocotb
import os
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
from cocotb.runner import get_runner
from pathlib import Path

async def reset_dut(dut):
    dut.i_rst.value = 1
    await Timer(3, units="ns")
    dut.i_rst.value = 0

@cocotb.test()
async def test_fifo_good_empty(dut):
    cocotb.start_soon(Clock(dut.i_clk, 1, units='ns').start())
    await reset_dut(dut)
    assert dut.o_empty.value == 1
    assert dut.o_full.value == 0

    await Timer(1, units="ns")
    dut.i_write_en.value = 1
    dut.i_data.value = 77
    await Timer(1, units="ns")
    assert dut.o_empty.value == 0

@cocotb.test()
async def test_fifo_good_full(dut):
    cocotb.start_soon(Clock(dut.i_clk, 1, units='ns').start())
    await reset_dut(dut)
    assert dut.o_empty.value == 1
    assert dut.o_full.value == 0

    for i in range(32):
        await Timer(1, units="ns")
        dut.i_write_en.value = 1
        dut.i_data.value = 77
    assert dut.o_empty.value == 0
    assert dut.o_full.value == 1

@cocotb.test()
async def test_fifo_good_semifull(dut):
    cocotb.start_soon(Clock(dut.i_clk, 1, units='ns').start())
    await reset_dut(dut)
    assert dut.o_empty.value == 1
    assert dut.o_full.value == 0

    for i in range(5):
        dut.i_write_en.value = 1
        dut.i_data.value = 77
        await Timer(1, units="ns")

    assert dut.o_empty.value == 0
    assert dut.o_full.value == 0

@cocotb.test()
async def test_fifo_good_io(dut):
    cocotb.start_soon(Clock(dut.i_clk, 1, units='ns').start())
    await reset_dut(dut)
    assert dut.o_empty.value == 1
    assert dut.o_full.value == 0

    for i in range(5):
        dut.i_write_en.value = 1
        dut.i_data.value = i
        await Timer(1, units="ns")
    
    await Timer(1, units="ns")

    for i in range(5):
        print(dut.o_data.value)
        #assert dut.o_data.value == i
        await Timer(1, units="ns")
        dut.i_read_en.value = 1
        await Timer(1, units="ns")
        dut.i_read_en.value = 0
    

    assert dut.o_empty.value == 0
    assert dut.o_full.value == 0


# todo negative case

def run_tests():
    top = "fifo"
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent

    sources = [proj_path / ".." / "rtl" / "components" / "fifo.sv"]
    inc = [proj_path / ".." / "rtl" ]

    # --coverage --trace --trace-fst --trace-structs
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=top,
        always=True,
        includes=inc,
        build_args=["--trace", "--trace-fst", "--trace-structs"],
        defines={"TESTING": True}
    )

    runner.test(hdl_toplevel=top, test_module=top, waves=True)


if __name__ == "__main__":
    run_tests()
