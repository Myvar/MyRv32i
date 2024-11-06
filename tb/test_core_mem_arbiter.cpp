#include "Vcore_mem_arbiter.h"
#include "verilated.h"
#include <iostream>
#include <vector>
#include <random>
#include <ctime>
#include <cassert>

#define CLK_PERIOD 10  // Clock period in time units

vluint64_t main_time = 0;  // Current simulation time
double sc_time_stamp() {
    return main_time;  // Called by $time in Verilog
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instantiate the DUT (Device Under Test)
    Vcore_mem_arbiter* dut = new Vcore_mem_arbiter;

    // Initialize random number generator
    std::mt19937 rng;
    rng.seed(std::time(nullptr));

    // Constants
    const int AW = 32;
    const int DW = 32;
    const int rom_size = 512;
    const int ram_size = 4096;
    const int total_size = rom_size + ram_size;

    // Data storage for comparison
    std::vector<uint32_t> expected_ram(ram_size / 4, 0);
    std::vector<uint32_t> expected_rom(rom_size / 4);

    // Preload ROM with known data
    for (auto& data : expected_rom) {
        data = rng();
    }

    // Simulation variables
    bool clk = false;

    // Reset
    dut->i_clk = clk;
    dut->i_clk_en = 1;
    dut->i_rst = 1;
    dut->i_fetch_read = 0;
    dut->i_lsu_read = 0;
    dut->i_lsu_write = 0;
    dut->i_debug_read = 0;
    dut->i_debug_write = 0;
    dut->eval();

    // Toggle clock for reset
    for (int i = 0; i < 2; ++i) {
        main_time += CLK_PERIOD / 2;
        clk = !clk;
        dut->i_clk = clk;
        dut->eval();
    }
    dut->i_rst = 0;

    // Helper function to toggle clock
    auto tick = [&]() {
        for (int i = 0; i < 2; ++i) {
            main_time += CLK_PERIOD / 2;
            clk = !clk;
            dut->i_clk = clk;
            dut->eval();
        }
    };

    // Test cases

    // 1. Write to RAM via LSU port and read back via LSU port
    for (int addr_offset = 560; addr_offset < ram_size; addr_offset += 4) {
        uint32_t addr = rom_size + addr_offset;
        uint32_t data = rng();
        expected_ram[addr_offset / 4] = data;

        // Write to RAM
        dut->i_lsu_write = 1;
        dut->i_w_lsu_addr = addr;
        dut->i_w_lsu_byte_en = 0b1111;
        dut->i_w_lsu_data = data;
        tick();
        dut->i_lsu_write = 0;
        tick();

        // Read back from RAM
        dut->i_lsu_read = 1;
        dut->i_r_lsu_addr = addr;
        tick();
        tick();  // Assuming one clock cycle delay
        uint32_t read_data = dut->o_r_lsu_data;
        dut->i_lsu_read = 0;

        if (read_data != data) {
            std::cerr << "LSU Read/Write Mismatch at address " << addr
                      << ": expected " << data << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 2. Read from ROM via Fetch port
    for (int addr_offset = 0; addr_offset < rom_size; addr_offset += 4) {
        uint32_t addr = addr_offset;
        uint32_t expected_data = expected_rom[addr_offset / 4];

        // Read from ROM
        dut->i_fetch_read = 1;
        dut->i_fetch_addr = addr;
        tick();
        tick();  // Assuming one clock cycle delay
        uint32_t read_data = dut->o_fetch_data;
        dut->i_fetch_read = 0;

        if (read_data != expected_data) {
            std::cerr << "Fetch Read Mismatch at address " << addr
                      << ": expected " << expected_data << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 3. Write to RAM via Debug port and read back via Debug port
    for (int addr_offset = 0; addr_offset < ram_size; addr_offset += 4) {
        uint32_t addr = rom_size + addr_offset;
        uint32_t data = rng();
        expected_ram[addr_offset / 4] = data;

        // Write to RAM
        dut->i_debug_write = 1;
        dut->i_w_debug_addr = addr;
        dut->i_w_debug_byte_en = 0b1111;
        dut->i_w_debug_data = data;
        tick();
        dut->i_debug_write = 0;
        tick();

        // Read back from RAM
        dut->i_debug_read = 1;
        dut->i_r_debug_addr = addr;
        tick();
        tick();  // Assuming one clock cycle delay
        uint32_t read_data = dut->o_r_debug_data;
        dut->i_debug_read = 0;

        if (read_data != data) {
            std::cerr << "Debug Read/Write Mismatch at address " << addr
                      << ": expected " << data << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 4. Fetch Read from RAM (should return zero)
    for (int addr_offset = 0; addr_offset < ram_size; addr_offset += 4) {
        uint32_t addr = rom_size + addr_offset;

        // Read from RAM via Fetch port
        dut->i_fetch_read = 1;
        dut->i_fetch_addr = addr;
        tick();
        tick();
        uint32_t read_data = dut->o_fetch_data;
        dut->i_fetch_read = 0;

        // Assuming Fetch port cannot access RAM, expect zero
        if (read_data != 0) {
            std::cerr << "Fetch Read from RAM address " << addr
                      << " returned non-zero data: " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 5. Simultaneous operations on different ports
    // Write via LSU, Read via Debug
    for (int addr_offset = 0; addr_offset < ram_size; addr_offset += 4) {
        uint32_t addr = rom_size + addr_offset;
        uint32_t data_lsu = rng();
        uint32_t data_debug = rng();
        expected_ram[addr_offset / 4] = data_debug;  // Last write via Debug port

        // Write via LSU port
        dut->i_lsu_write = 1;
        dut->i_w_lsu_addr = addr;
        dut->i_w_lsu_byte_en = 0b1111;
        dut->i_w_lsu_data = data_lsu;

        // Write via Debug port (overwrites LSU data)
        dut->i_debug_write = 1;
        dut->i_w_debug_addr = addr;
        dut->i_w_debug_byte_en = 0b1111;
        dut->i_w_debug_data = data_debug;

        tick();
        dut->i_lsu_write = 0;
        dut->i_debug_write = 0;

        // Read back via Debug port
        dut->i_debug_read = 1;
        dut->i_r_debug_addr = addr;
        tick();
        tick();
        uint32_t read_data = dut->o_r_debug_data;
        dut->i_debug_read = 0;

        if (read_data != data_debug) {
            std::cerr << "Simultaneous Write/Read Mismatch at address " << addr
                      << ": expected " << data_debug << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 6. Read from invalid addresses
    std::vector<uint32_t> invalid_addresses = {total_size + 100, total_size + 200};
    for (auto addr : invalid_addresses) {
        // Read via LSU port
        dut->i_lsu_read = 1;
        dut->i_r_lsu_addr = addr;
        tick();
        tick();
        uint32_t read_data = dut->o_r_lsu_data;
        dut->i_lsu_read = 0;

        // Assuming invalid addresses return zero
        if (read_data != 0) {
            std::cerr << "Read from invalid address " << addr
                      << " returned non-zero data: " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 7. Write to ROM (should have no effect)
    for (int addr_offset = 0; addr_offset < rom_size; addr_offset += 4) {
        uint32_t addr = addr_offset;
        uint32_t data = rng();

        // Attempt to write to ROM via Debug port
        dut->i_debug_write = 1;
        dut->i_w_debug_addr = addr;
        dut->i_w_debug_byte_en = 0b1111;
        dut->i_w_debug_data = data;
        tick();
        dut->i_debug_write = 0;

        // Read back via Fetch port
        dut->i_fetch_read = 1;
        dut->i_fetch_addr = addr;
        tick();
        tick();
        uint32_t read_data = dut->o_fetch_data;
        dut->i_fetch_read = 0;

        uint32_t expected_data = expected_rom[addr_offset / 4];
        if (read_data != expected_data) {
            std::cerr << "Write to ROM address " << addr
                      << " altered data: expected " << expected_data << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // 8. Randomized operation sequences
    for (int i = 0; i < 100; ++i) {
        std::vector<std::string> operations = {"lsu_read", "lsu_write", "fetch_read", "debug_read", "debug_write"};
        std::string operation = operations[rng() % operations.size()];
        uint32_t addr = rng() % total_size;

        if (operation == "lsu_read") {
            dut->i_lsu_read = 1;
            dut->i_r_lsu_addr = addr;
            tick();
            tick();
            uint32_t read_data = dut->o_r_lsu_data;
            dut->i_lsu_read = 0;

            // Determine expected data
            uint32_t expected_data = 0;
            if (addr < rom_size) {
                expected_data = expected_rom[addr / 4];
            } else if (addr < total_size) {
                expected_data = expected_ram[(addr - rom_size) / 4];
            }

            if (read_data != expected_data) {
                std::cerr << "Random LSU Read Mismatch at address " << addr
                          << ": expected " << expected_data << ", got " << read_data << std::endl;
                delete dut;
                exit(EXIT_FAILURE);
            }

        } else if (operation == "lsu_write") {
            uint32_t data = rng();
            dut->i_lsu_write = 1;
            dut->i_w_lsu_addr = addr;
            dut->i_w_lsu_byte_en = 0b1111;
            dut->i_w_lsu_data = data;
            tick();
            dut->i_lsu_write = 0;

            // Update expected data if address is in RAM
            if (addr >= rom_size && addr < total_size) {
                expected_ram[(addr - rom_size) / 4] = data;
            }

        } else if (operation == "fetch_read") {
            dut->i_fetch_read = 1;
            dut->i_fetch_addr = addr;
            tick();
            tick();
            uint32_t read_data = dut->o_fetch_data;
            dut->i_fetch_read = 0;

            uint32_t expected_data = 0;
            if (addr < rom_size) {
                expected_data = expected_rom[addr / 4];
            }

            if (read_data != expected_data) {
                std::cerr << "Random Fetch Read Mismatch at address " << addr
                          << ": expected " << expected_data << ", got " << read_data << std::endl;
                delete dut;
                exit(EXIT_FAILURE);
            }

        } else if (operation == "debug_read") {
            dut->i_debug_read = 1;
            dut->i_r_debug_addr = addr;
            tick();
            tick();
            uint32_t read_data = dut->o_r_debug_data;
            dut->i_debug_read = 0;

            uint32_t expected_data = 0;
            if (addr < rom_size) {
                expected_data = expected_rom[addr / 4];
            } else if (addr < total_size) {
                expected_data = expected_ram[(addr - rom_size) / 4];
            }

            if (read_data != expected_data) {
                std::cerr << "Random Debug Read Mismatch at address " << addr
                          << ": expected " << expected_data << ", got " << read_data << std::endl;
                delete dut;
                exit(EXIT_FAILURE);
            }

        } else if (operation == "debug_write") {
            uint32_t data = rng();
            dut->i_debug_write = 1;
            dut->i_w_debug_addr = addr;
            dut->i_w_debug_byte_en = 0b1111;
            dut->i_w_debug_data = data;
            tick();
            dut->i_debug_write = 0;

            // Update expected data if address is in RAM
            if (addr >= rom_size && addr < total_size) {
                expected_ram[(addr - rom_size) / 4] = data;
            }
        }
    }

    // Final check: Verify RAM contents match expected data
    for (int addr_offset = 0; addr_offset < ram_size; addr_offset += 4) {
        uint32_t addr = rom_size + addr_offset;

        // Read via Debug port
        dut->i_debug_read = 1;
        dut->i_r_debug_addr = addr;
        tick();
        tick();
        uint32_t read_data = dut->o_r_debug_data;
        dut->i_debug_read = 0;

        uint32_t expected_data = expected_ram[addr_offset / 4];
        if (read_data != expected_data) {
            std::cerr << "Final RAM Content Mismatch at address " << addr
                      << ": expected " << expected_data << ", got " << read_data << std::endl;
            delete dut;
            exit(EXIT_FAILURE);
        }
    }

    // Simulation passed
    std::cout << "All tests passed successfully." << std::endl;

    // Clean up and exit
    dut->final();
    delete dut;
    exit(EXIT_SUCCESS);
}
