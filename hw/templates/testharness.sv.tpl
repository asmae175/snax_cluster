// Copyright 2024 KU Leuven.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`include "axi/typedef.svh"

module testharness import ${cfg["cluster"]["name"]}_pkg::*; (
  input logic clk_i,
  input logic rst_ni
);

  import "DPI-C" function void clint_tick(
    output byte msip[]
  );

  narrow_in_req_t   narrow_in_req;
  narrow_in_resp_t  narrow_in_resp;
  narrow_out_req_t  narrow_out_req;
  narrow_out_resp_t narrow_out_resp;
% if 'use_ax_bw_converter' in cfg['cluster']:
  % if cfg['cluster']['use_ax_bw_converter']:
  lowbw_wide_out_req_t  wide_out_req;
  lowbw_wide_out_resp_t wide_out_resp;
  lowbw_wide_in_req_t   wide_in_req;
  lowbw_wide_in_resp_t  wide_in_resp;
  % else:
  wide_out_req_t    wide_out_req;
  wide_out_resp_t   wide_out_resp;
  wide_in_req_t     wide_in_req;
  wide_in_resp_t    wide_in_resp;
  % endif
% else:
  wide_out_req_t    wide_out_req;
  wide_out_resp_t   wide_out_resp;
  wide_in_req_t     wide_in_req;
  wide_in_resp_t    wide_in_resp;
% endif
 

  logic [${cfg["cluster"]["name"]}_pkg::NrCores-1:0] msip;

  ${cfg["cluster"]["name"]}_wrapper i_${cfg["cluster"]["name"]} (
    .clk_i                ( clk_i           ),
    .rst_ni               ( rst_ni          ),
    .hart_base_id_i       ( HartBaseID      ),
    .cluster_base_addr_i  ( ClusterBaseAddr ),
    .boot_addr_i          ( BootAddr        ),
    .debug_req_i          ( '0              ),
    .meip_i               ( '0              ),
    .mtip_i               ( '0              ),
    .msip_i               ( msip            ),
    .narrow_in_req_i      ( narrow_in_req   ),
    .narrow_in_resp_o     ( narrow_in_resp  ),
    .narrow_out_req_o     ( narrow_out_req  ),
    .narrow_out_resp_i    ( narrow_out_resp ),
    .wide_out_req_o       ( wide_out_req    ),
    .wide_out_resp_i      ( wide_out_resp   ),
    .wide_in_req_i        ( wide_in_req     ),
    .wide_in_resp_o       ( wide_in_resp    )
  );

  // Tie-off unused input ports.
  assign narrow_in_req = '0;
  assign wide_in_req   = '0;

  // Narrow port into simulation memory.
  tb_memory_axi #(
    .AxiAddrWidth ( AddrWidth         ),
    .AxiDataWidth ( NarrowDataWidth   ),
    .AxiIdWidth   ( NarrowIdWidthOut  ),
    .AxiUserWidth ( NarrowUserWidth   ),
    .req_t        ( narrow_out_req_t  ),
    .rsp_t        ( narrow_out_resp_t )
  ) i_mem (
    .clk_i        ( clk_i             ),
    .rst_ni       ( rst_ni            ),
    .req_i        ( narrow_out_req    ),
    .rsp_o        ( narrow_out_resp   )
  );

  // Wide port into simulation memory.
  tb_memory_axi #(
    .AxiAddrWidth ( AddrWidth       ),
    .AxiDataWidth ( WideDataWidth   ),
    .AxiIdWidth   ( WideIdWidthOut  ),
    .AxiUserWidth ( WideUserWidth   ),
% if 'use_ax_bw_converter' in cfg['cluster']:
  % if cfg['cluster']['use_ax_bw_converter']:
    .req_t        ( lowbw_wide_out_req_t  ),
    .rsp_t        ( lowbw_wide_out_resp_t )
  % else:
    .req_t        ( wide_out_req_t  ),
    .rsp_t        ( wide_out_resp_t )
  % endif
% else:
    .req_t        ( wide_out_req_t  ),
    .rsp_t        ( wide_out_resp_t )
% endif
  ) i_dma (
    .clk_i        ( clk_i           ),
    .rst_ni       ( rst_ni          ),
    .req_i        ( wide_out_req    ),
    .rsp_o        ( wide_out_resp   )
  );

  // CLINT
  // verilog_lint: waive-start always-ff-non-blocking
  localparam int NumCores = ${cfg["cluster"]["name"]}_pkg::NrCores;
  always_ff @(posedge clk_i) begin
    automatic byte msip_ret[NumCores];
    if (rst_ni) begin
      clint_tick(msip_ret);
      for (int i = 0; i < NumCores; i++) begin
        msip[i] = msip_ret[i];
      end
    end
  end
  // verilog_lint: waive-stop always-ff-non-blocking

endmodule
