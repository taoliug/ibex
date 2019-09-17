// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module core_ibex_tb_top;

  import uvm_pkg::*;
  import core_ibex_test_pkg::*;

  logic clk;
  logic rst_n;
  logic fetch_enable;

  clk_if         ibex_clk_if(.clk(clk));
  irq_if         irq_vif();
  ibex_mem_intf  data_mem_vif();
  ibex_mem_intf  instr_mem_vif();


  // DUT probe interface
  core_ibex_dut_probe_if dut_if(.clk(clk));

  // TODO(taliu) Resolve the tied-off ports
  ibex_core_tracing #(.DmHaltAddr(`BOOT_ADDR + 'h0),
                      .DmExceptionAddr(`BOOT_ADDR + 'h4)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .test_en_i(1'b1),
    .hart_id_i(32'b0),
    .boot_addr_i(`BOOT_ADDR), // align with spike boot address
    .irq_software_i(irq_vif.irq_software),
    .irq_timer_i(irq_vif.irq_timer),
    .irq_external_i(irq_vif.irq_external),
    .irq_fast_i(irq_vif.irq_fast),
    .irq_nm_i(irq_vif.irq_nm),
    .fetch_enable_i(dut_if.fetch_enable),
    .debug_req_i(dut_if.debug_req),
    .data_gnt_i(data_mem_vif.grant),
    .data_rvalid_i(data_mem_vif.rvalid),
    .data_rdata_i(data_mem_vif.rdata),
    .data_err_i(0),
    .instr_gnt_i(instr_mem_vif.grant),
    .instr_rvalid_i(instr_mem_vif.rvalid),
    .instr_rdata_i(instr_mem_vif.rdata),
    .instr_err_i(0)
  );

  // Data load/store vif connection
  assign data_mem_vif.clock    = clk;
  assign data_mem_vif.reset    = ~rst_n;
  assign data_mem_vif.request  = dut.data_req_o;
  assign data_mem_vif.we       = dut.data_we_o;
  assign data_mem_vif.be       = dut.data_be_o;
  assign data_mem_vif.addr     = dut.data_addr_o;
  assign data_mem_vif.wdata    = dut.data_wdata_o;
  // Instruction fetch vif connnection
  assign instr_mem_vif.clock   = clk;
  assign instr_mem_vif.reset   = ~rst_n;
  assign instr_mem_vif.request = dut.instr_req_o;
  assign instr_mem_vif.we      = 0;
  assign instr_mem_vif.be      = 0;
  assign instr_mem_vif.wdata   = 0;
  assign instr_mem_vif.addr    = dut.instr_addr_o;

  initial begin
    // IRQ interface
    force irq_vif.clock         = clk;
    force irq_vif.reset         = ~rst_n;
  end

  assign dut_if.ecall       = dut.u_ibex_core.id_stage_i.ecall_insn_dec;
  assign dut_if.wfi         = dut.u_ibex_core.id_stage_i.wfi_insn_dec;
  assign dut_if.ebreak      = dut.u_ibex_core.id_stage_i.ebrk_insn;
  assign dut_if.dret        = dut.u_ibex_core.id_stage_i.dret_insn_dec;
  assign dut_if.mret        = dut.u_ibex_core.id_stage_i.mret_insn_dec;
  assign dut_if.core_sleep  = dut.u_ibex_core.core_sleep_o;


  initial begin
    uvm_config_db#(virtual clk_if)::set(null, "*", "clk_if", ibex_clk_if);
    uvm_config_db#(virtual core_ibex_dut_probe_if)::set(null, "*", "dut_if", dut_if);
    uvm_config_db#(virtual ibex_mem_intf)::set(null, "*data_if_slave*", "vif", data_mem_vif);
    uvm_config_db#(virtual ibex_mem_intf)::set(null, "*instr_if_slave*", "vif", instr_mem_vif);
    uvm_config_db#(virtual irq_if)::set(null, "*", "vif", irq_vif);
    run_test();
  end

  // Generate clk
  initial begin
    clk = 1'b0;
    forever begin
      #10 clk = ~clk;
    end
  end

  // Generate reset
  initial begin
    rst_n = 1'b0;
    repeat(100) @(posedge clk);
    rst_n = 1'b1;
  end

endmodule
