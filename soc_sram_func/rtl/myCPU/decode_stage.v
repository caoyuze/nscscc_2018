`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/02 16:27:08
// Design Name: 
// Module Name: decode_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.h"
module decode_stage(
    input wire clk,resetn,
    input wire[31:0] pc,inst,
    output reg[12:0] controls,
    output reg[4:0] alucontrol,
    output wire[4:0] rs,rt,rd,
    output reg[31:0] pc_next,
    input wire[31:0] rf_outa,rf_outb,
    output wire[31:0] srca,srcb,extend_imm

    );

    wire[5:0] op,funct;
	// wire [4:0] rs,rt,rd;
	assign op = inst[31:26];
	assign funct = inst[5:0];
	assign rs = inst[25:21];
	assign rt = inst[20:16];
	assign rd = inst[15:11];

    //to exe stage
    assign extend_imm = (op[3:2] == 2'b11)? {{16{1'b0}},inst[15:0]} : {{16{inst[15]}},inst[15:0]};
    assign srca = rf_outa;
    assign srcb = rf_outb;

    always @(posedge clk) begin
        if (~resetn) begin
            pc_next <= 32'hbfc00000;
        end else begin
            pc_next <= pc;
        end
      
    end

    //  controller decode
    //  controls[12:0]
    //	regwrite,regdst,alusrc,branch,memen,memtoreg,jump,jal,jr,bal,memwrite,next_is_in_slot,invalid

    //main decode
	always @(*) begin
		case (op)
			`R_TYPE:case (funct)
				`JR:controls <= 13'b0_0_0_0_0_0_1_0_1_0_0_1_0;
				`JALR:controls <= 13'b1_1_0_0_0_0_0_0_1_0_0_1_0;
				`SYSCALL,`BREAK:controls <= 13'b00000000_0_0_0_0_0;
				`MULT,`MULTU,`DIV,`DIVU:controls <= 13'b0_1_0_0_0_0_0_0_0_0_0_0_0;
				default: controls <= 13'b1_1_0_0_0_0_0_0_0_0_0_0_0;//R-TYRE
			endcase
			`LW,`LB,`LBU,`LH,`LHU:controls <= 13'b1_0_1_0_1_1_0_0_0_0_0_0_0;//LW
			`SW,`SB,`SH:controls <= 13'b0_0_1_0_1_0_0_0_0_0_1_0_0;//SW
			//B-inst
			`BEQ:controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;//BEQ
			`BNE:controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
			`BGTZ:begin 
				if(rt == 5'b00000) begin
					/* code */
					controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`BLEZ:begin 
				if(rt == 5'b00000) begin
					/* code */
					controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`REGIMM_INST:case (rt)
				`BLTZ:begin 
					if(rt == 5'b00000) begin
						/* code */
						controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`BLTZAL:begin 
					if(rt == 5'b10000) begin
						/* code */
						controls <= 13'b1_0_0_1_0_0_0_0_0_1_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`BGEZ:begin 
					if(rt == 5'b00001) begin
						/* code */
						controls <= 13'b0_0_0_1_0_0_0_0_0_0_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
				`BGEZAL:begin 
					if(rt == 5'b10001) begin
						/* code */
						controls <= 13'b1_0_0_1_0_0_0_0_0_1_0_1_0;
					end else begin 
						controls <= 13'b00000000_0_0_0_0_1;
					end
				end
			
				default : /* default */controls <= 13'b00000000_0_0_0_0_1;
			endcase
			//I-TYPE
			`ORI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;//ORI
			`ANDI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`XORI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`LUI:begin 
				if(rs == 5'b00000) begin
					/* code */
					controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
				end else begin 
					controls <= 13'b00000000_0_0_0_0_1;
				end
			end
			`ADDI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`ADDIU:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`SLTI:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			`SLTIU:controls <= 13'b1_0_1_0_0_0_0_0_0_0_0_0_0;
			//J-TYPE
			`J:controls <= 13'b0_0_0_0_0_0_1_0_0_0_0_1_0;//J
			`JAL:controls <= 13'b1_0_0_0_0_0_0_1_0_0_0_1_0;

			default:  controls <= 13'b00000000_0_0_0_0_1;//illegal op
		endcase
		if(inst[31:21] == 13'b010000_00000 && inst[10:0] == 13'b00000_000000) begin
			/* code */
			controls <= 13'b1_0_0_0_0_0_0_0_0_0_0_0_0;
		end else if(inst[31:21] == 13'b010000_00100 && inst[10:0] == 13'b00000_000000) begin
			/* code */
			controls <= 13'b0_1_0_0_0_0_0_0_0_0_0_0_0;
		end

		if(inst == `ERET) begin
			/* code */
			controls <= 13'b00000000_0_0_0_0_0;
		end else if(inst == 32'b0) begin
			/* code */
			controls <= 13'b00000000_0_0_0_0_0;
		end
	end
    // alu decode
    always @(*) begin
		case (op)
			//memory inst
			`LB,`LBU,`LH,`LHU,`LW,`SB,`SH,`SW:alucontrol <= `ADD_CONTROL;
			//logic inst imm
			`ORI: alucontrol <= `OR_CONTROL;
			`ANDI: alucontrol <= `AND_CONTROL;
			`XORI: alucontrol <= `XOR_CONTROL;
			`LUI: alucontrol <= `LUI_CONTROL;
			`ADDI:alucontrol <= `ADD_CONTROL;
			`ADDIU:alucontrol <= `ADDU_CONTROL;
			`SLTI:alucontrol <= `SLT_CONTROL; //slt
			`SLTIU:alucontrol <= `SLTU_CONTROL;
			// 2'b00: alucontrol <= 3'b010;//add (for lw/sw/addi)
			// 2'b01: alucontrol <= 3'b110;//sub (for beq)
			// 2'b10: alucontrol <= 3'b001;
			`R_TYPE : case (funct)
				//arithmetic inst special
				`ADD:alucontrol <= `ADD_CONTROL; //add
				`ADDU:alucontrol <= `ADDU_CONTROL;
				`SUB:alucontrol <= `SUB_CONTROL; //sub
				`SUBU:alucontrol <= `SUBU_CONTROL;
				`SLT:alucontrol <= `SLT_CONTROL; //slt
				`SLTU:alucontrol <= `SLTU_CONTROL;
				`MULT:alucontrol <= `MULT_CONTROL;
				`MULTU:alucontrol <= `MULTU_CONTROL;
				`DIV:alucontrol <= `DIV_CONTROL;
				`DIVU:alucontrol <= `DIVU_CONTROL;
				//logic inst special
				`AND:alucontrol <= `AND_CONTROL; //and
				`OR:alucontrol <= `OR_CONTROL; //or
				`XOR:alucontrol <= `XOR_CONTROL; //xor
				`NOR:alucontrol <= `NOR_CONTROL; //nor
				//shift inst special
				`SLL:alucontrol <= `SLL_CONTROL;
				`SRL:alucontrol <= `SRL_CONTROL;
				`SRA:alucontrol <= `SRA_CONTROL;
				`SLLV:alucontrol <= `SLLV_CONTROL;
				`SRLV:alucontrol <= `SRLV_CONTROL;
				`SRAV:alucontrol <= `SRAV_CONTROL;
				//move inst special
				// `MFHI:alucontrol <= `MFHI_CONTROL;
				// `MTHI:alucontrol <= `MTHI_CONTROL;
				// `MFLO:alucontrol <= `MFLO_CONTROL;
				// `MTLO:alucontrol <= `MTLO_CONTROL;
				
				default:  alucontrol <= `NO_CONTROL;
			endcase
			default:  alucontrol <= `NO_CONTROL;
		endcase
		// if(inst[31:21] == 11'b010000_00000 && inst[10:0] == 11'b00000_000000) begin
		// 	/* code */
		// 	alucontrol <= `MFC0_CONTROL;
		// end else if(inst[31:21] == 11'b010000_00100 && inst[10:0] == 11'b00000_000000) begin
		// 	/* code */
		// 	alucontrol <= `MTC0_CONTROL;
		// end
	end

    


endmodule
