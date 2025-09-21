module interconnect_1_to_4 #(
    // Slave 0: Base 0x0, Size 4096 Bytes (4KB). Range: 0x0000 to 0x0FFF
    parameter int SLAVE0_BASE_ADDR = 32'd0,
    parameter int SLAVE0_ADDR_SPAN = 4096,

    // Slave 1: Base 4096, Size 4096 Bytes (4KB). Range: 0x1000 to 0x1FFF
    parameter int SLAVE1_BASE_ADDR = 32'd4097,
    parameter int SLAVE1_ADDR_SPAN = 4096,

    // Slaves 2 and 3 are unchanged
    parameter int SLAVE2_BASE_ADDR = 32'h8193,
    parameter int SLAVE2_ADDR_SPAN = 4096,

    parameter int SLAVE3_BASE_ADDR = 32'd12289,
    parameter int SLAVE3_ADDR_SPAN = 4096
) (
    bus_if.slave m0_bus,  // Single port for the master

    // One port for each slave
    bus_if.master s0_bus,
    bus_if.master s1_bus,
    bus_if.master s2_bus,
    bus_if.master s3_bus
);

  assign s0_bus.chipselect = (m0_bus.address >= SLAVE0_BASE_ADDR) && (m0_bus.address < (SLAVE0_BASE_ADDR + SLAVE0_ADDR_SPAN));
  assign s1_bus.chipselect = (m0_bus.address >= SLAVE1_BASE_ADDR) && (m0_bus.address < (SLAVE1_BASE_ADDR + SLAVE1_ADDR_SPAN));
  assign s2_bus.chipselect = (m0_bus.address >= SLAVE2_BASE_ADDR) && (m0_bus.address < (SLAVE2_BASE_ADDR + SLAVE2_ADDR_SPAN));
  assign s3_bus.chipselect = (m0_bus.address >= SLAVE3_BASE_ADDR) && (m0_bus.address < (SLAVE3_BASE_ADDR + SLAVE3_ADDR_SPAN));


  assign s0_bus.address = m0_bus.address - SLAVE0_BASE_ADDR;
  assign s0_bus.write = m0_bus.write;
  assign s0_bus.read = m0_bus.read;
  assign s0_bus.writedata = m0_bus.writedata;
  assign s0_bus.byteenable = m0_bus.byteenable;

  assign s1_bus.address = m0_bus.address - SLAVE1_BASE_ADDR;
  assign s1_bus.write = m0_bus.write;
  assign s1_bus.read = m0_bus.read;
  assign s1_bus.writedata = m0_bus.writedata;
  assign s1_bus.byteenable = m0_bus.byteenable;

  assign s2_bus.address = m0_bus.address - SLAVE2_BASE_ADDR;
  assign s2_bus.write = m0_bus.write;
  assign s2_bus.read = m0_bus.read;
  assign s2_bus.writedata = m0_bus.writedata;
  assign s2_bus.byteenable = m0_bus.byteenable;

  assign s3_bus.address = m0_bus.address - SLAVE3_BASE_ADDR;
  assign s3_bus.write = m0_bus.write;
  assign s3_bus.read = m0_bus.read;
  assign s3_bus.writedata = m0_bus.writedata;
  assign s3_bus.byteenable = m0_bus.byteenable;


  always_comb begin
    case (1'b1)
      s0_bus.chipselect: m0_bus.readdata = s0_bus.readdata;
      s1_bus.chipselect: m0_bus.readdata = s1_bus.readdata;
      s2_bus.chipselect: m0_bus.readdata = s2_bus.readdata;
      s3_bus.chipselect: m0_bus.readdata = s3_bus.readdata;
      default:           m0_bus.readdata = 'x;  // Drive 'x' if no slave is selected
    endcase
  end

  assign m0_bus.waitrequest = (s0_bus.chipselect & s0_bus.waitrequest) |
                                (s1_bus.chipselect & s1_bus.waitrequest) |
                                (s2_bus.chipselect & s2_bus.waitrequest) |
                                (s3_bus.chipselect & s3_bus.waitrequest);

endmodule
