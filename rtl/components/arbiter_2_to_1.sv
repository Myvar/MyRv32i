module arbiter_2_to_1 (
    bus_if.slave  m0_bus,  // Connects to Master 0 (e.g., Fetch Unit)
    bus_if.slave  m1_bus,  // Connects to Master 1 (e.g., LSU)
    bus_if.master s0_bus   // Connects to the slave-side (e.g., Interconnect)
);

  logic priority_reg;  // 0 = M0 has priority, 1 = M1 has priority

  logic m0_request;
  logic m1_request;
  assign m0_request = m0_bus.read || m0_bus.write;
  assign m1_request = m1_bus.read || m1_bus.write;

  logic m0_request_reg, m1_request_reg;
  always_ff @(posedge m0_bus.clk or posedge m0_bus.reset) begin
    if (m0_bus.reset) begin
      m0_request_reg <= 1'b0;
      m1_request_reg <= 1'b0;
    end else begin
      m0_request_reg <= m0_request;
      m1_request_reg <= m1_request;
    end
  end

  wire grant_m0 = m0_request_reg && (priority_reg == 1'b0 || !m1_request_reg);
  wire grant_m1 = m1_request_reg && (priority_reg == 1'b1 || !m0_request_reg);

  always_ff @(posedge m0_bus.clk or posedge m0_bus.reset) begin
    if (m0_bus.reset) begin
      priority_reg <= 1'b0;  // Default to M0 having priority
    end else begin
      if (!s0_bus.waitrequest) begin
        if (grant_m0) begin
          priority_reg <= 1'b1;  // Pass priority to M1 for the next arbitration
        end else if (grant_m1) begin
          priority_reg <= 1'b0;  // Pass priority to M0 for the next arbitration
        end
      end
    end
  end

  always_comb begin
    if (grant_m0) begin
      s0_bus.address    = m0_bus.address;
      s0_bus.writedata  = m0_bus.writedata;
      s0_bus.read       = m0_bus.read;
      s0_bus.write      = m0_bus.write;
      s0_bus.byteenable = m0_bus.byteenable;
    end else if (grant_m1) begin
      s0_bus.address    = m1_bus.address;
      s0_bus.writedata  = m1_bus.writedata;
      s0_bus.read       = m1_bus.read;
      s0_bus.write      = m1_bus.write;
      s0_bus.byteenable = m1_bus.byteenable;
    end else begin
      s0_bus.address    = 0;
      s0_bus.writedata  = 0;
      s0_bus.read       = 0;
      s0_bus.write      = 0;
      s0_bus.byteenable = 0;
    end
  end
  assign s0_bus.chipselect = grant_m0 || grant_m1;

  assign m0_bus.readdata = s0_bus.readdata;
  assign m1_bus.readdata = s0_bus.readdata;

  assign m0_bus.waitrequest = s0_bus.waitrequest;
  assign m1_bus.waitrequest = s0_bus.waitrequest;

endmodule

