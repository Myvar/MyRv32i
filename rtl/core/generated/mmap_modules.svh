local_rom u_local_rom (
.i_clk(i_clk),
.i_clk_en(i_clk_en),
.i_rst(i_rst),

.i_read_addr(local_rom_read_addr),
.o_read_data(local_rom_read_data),

.i_write_en(local_rom_write_en),
.i_byte_en(local_rom_byte_en),
.i_write_addr(local_rom_write_addr),
.i_write_data(local_rom_write_data)
);

wire [AW-1:0] local_rom_read_addr;
wire [DW-1:0] local_rom_read_data;

wire local_rom_write_en;
wire [3:0] local_rom_byte_en;
wire [AW-1:0]local_rom_write_addr;
wire [DW-1:0]local_rom_write_data;
local_ram #(
.ADDR_COUNT(1024)
)
 u_local_ram (
.i_clk(i_clk),
.i_clk_en(i_clk_en),
.i_rst(i_rst),

.i_read_addr(local_ram_read_addr),
.o_read_data(local_ram_read_data),

.i_write_en(local_ram_write_en),
.i_byte_en(local_ram_byte_en),
.i_write_addr(local_ram_write_addr),
.i_write_data(local_ram_write_data)
);

wire [AW-1:0] local_ram_read_addr;
wire [DW-1:0] local_ram_read_data;

wire local_ram_write_en;
wire [3:0] local_ram_byte_en;
wire [AW-1:0]local_ram_write_addr;
wire [DW-1:0]local_ram_write_data;
