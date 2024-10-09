`include "types.svh"

// 2 STATES: BOOT; RUN
// BOOT = listening for commands
// RUN = stops listening for commands and simply forwards rx and tx directly to cpu gpio system

// BOOT MODE COMMANDS
// ===========================
// nop; does nothing will be zero
// boot; enters into boot mode
// rst; triger internal reset of cpu
// echo; writes back a simple ping responce
// write; write to ram
//      writesize writeaddr data
// read; read from ram
//      readsize readaddr


 // 2^6 = 64 max states
typedef enum logic [5:0] {  
    ST_START,
    ST_ERROR,

    ST_NOP_O,
    ST_NOP_P
} state_t;

typedef enum logic [3:0] {  
    BIOS_ER_UNKNOWN,
    BIOS_ER_BADCMD
} error_code_t;

typedef struct packed {
    state_t state;
    error_code_t error;
} fsm_state_t;

module bios(
    input clk,
    input clk_en,
    input rst,

    input [7:0] rx_data,
    input rx_valid,
    input rx_ready
);

wire step_en = rx_valid & rx_ready & clk_en;

fsm_state_t fsm;
always_ff @(posedge clk)
    if(step_en)
        case (fsm.state)
            ST_START: 
                case (rx_data)
                    ASCII_LOWER_n: //nop 
                        fsm <= {ST_NOP_O, BIOS_ER_UNKNOWN};
                    ASCII_LOWER_b: //boot
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD};
                    ASCII_LOWER_r: //rst
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD};
                    ASCII_LOWER_e: //echo
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD};
                    ASCII_LOWER_w: //write
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD};
                    ASCII_LOWER_r: //write
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD}; // report bad cmd error
                endcase
            ST_NOP_O:
                case (rx_data)
                    ASCII_LOWER_o: //nop 
                        fsm <= {ST_NOP_P, BIOS_ER_UNKNOWN};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD}; // report bad cmd error
                endcase
            ST_NOP_P:
                case (rx_data)
                    ASCII_LOWER_p: //nop 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD}; // report bad cmd error
                endcase
            default:
                fsm <= {ST_START, BIOS_ER_UNKNOWN};
        endcase

`ifdef TESTING1
    always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
    end
`endif

endmodule
