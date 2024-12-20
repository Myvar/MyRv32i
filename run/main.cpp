#include "Vrv32i.h"
#include "uartsim.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <cstdio>
Vrv32i *top;
VerilatedContext *contextp;
VerilatedFstC *tfp;

UARTSIM *uart;

void step() {
  // contextp->timeInc(1);
  top->eval();
  // tfp->dump(contextp->time());
}

int main(int argc, char **argv) {
  contextp = new VerilatedContext;
  Verilated::traceEverOn(true);
  contextp->commandArgs(argc, argv);
  tfp = new VerilatedFstC;
  top = new Vrv32i{contextp};
  top->trace(tfp, 99);

  uart = new UARTSIM(8880);
  uart->setup(0x005161);

  top->i_clk = 0;
  step();

  top->i_clk = !top->i_clk;
  step();

  top->i_clk = !top->i_clk;
  step();

  top->i_rst = 1;
  top->i_clk = !top->i_clk;
  step();

  top->i_clk = !top->i_clk;
  step();
  top->i_clk = !top->i_clk;
  step();
  top->i_clk = !top->i_clk;
  step();

  top->i_rst = 0;
  top->i_clk = 0;

  top->i_clk = !top->i_clk;
  step();

  top->i_clk = !top->i_clk;
  step();
  top->i_clk_en = 1;
  top->i_clk = !top->i_clk;
  step();

  tfp->open("run.fst");

  /*while (!top->booted) {
    top->i_clk = 1;
    top->eval();

    top->i_clk = 0;
    top->eval();

    top->rx = (*uart)(top->tx);

    // contextp->timeInc(1);
    // tfp->dump(contextp->time());
  }*/
  // while (!top->booted) {
  //   top->i_clk = !top->i_clk;
  //   top->rx = (*uart)(top->tx);

  //   top->eval();
  //   tfp->dump(contextp->time());
  //   contextp->timeInc(1);
  // }

  // printf("Booted\n");

  // while (!contextp->gotFinish()) {
  // while (true) {
  for (int i = 0; i < 10000; i++) {
    top->i_clk = 1;
    top->eval();
    if (top->o_booted)
      tfp->dump(contextp->time());
    if (top->o_booted)
      contextp->timeInc(1);

    top->i_clk = 0;
    top->eval();
    if (top->o_booted)
      tfp->dump(contextp->time());
    if (top->o_booted)
      contextp->timeInc(1);

    top->i_rx = (*uart)(top->o_tx);
  }

  tfp->close();

  delete top;
  delete contextp;
  return 0;
}
