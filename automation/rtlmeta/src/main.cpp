#define _YOSYS_
#include <kernel/yosys.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {

  if (argc != 2) {
    printf("Please provide an rtl directory and output path\n");
    return -1;
  }

  auto rtl = argv[1];

  // Yosys::log_streams.push_back(&std::cout);
  // Yosys::log_error_stderr = true;
  Yosys::yosys_setup();

  Yosys::yosys_design = new Yosys::RTLIL::Design;

  {
    char buf[255] = {0};
    sprintf(buf, "read_verilog %s/*.v", rtl);
    Yosys::run_pass(buf);
  }

  {
    char buf[255] = {0};
    sprintf(buf, "read -sv %s/*.sv", rtl);
    Yosys::run_pass(buf);
  }

  Yosys::run_pass("prep");
  Yosys::run_pass("opt -full");

  printf("{\n");
  for (auto module : Yosys::yosys_design->modules()) {
    if (module->name.begins_with("$paramod"))
      continue;

    printf("\t{\n");
    printf("\t\t\"name\": \"%s\",\n", module->name.c_str() + 1);

    auto ports = module->ports;

    printf("\t\t\"ports\": [\n");
    for (auto port : ports) {
      auto *w = module->wire(port);

      printf("\t\t\t{\n");
      printf("\t\t\t\t\"name\": \"%s\",\n", port.c_str() + 1);
      printf("\t\t\t\t\"width\": \%d,\n", w->width);
      // this does not account for inout ports but not now
      printf("\t\t\t\t\"input\": \%s\n", w->port_input ? "true" : "false");
      printf("\t\t\t},\n");
    }
    printf("\t\t]\n");
    printf("\t},\n");
  }

  printf("]\n");
  return EXIT_SUCCESS;
}
