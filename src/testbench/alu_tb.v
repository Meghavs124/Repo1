module alu_tb;

    parameter N = 4;

    // --------------------------------------------------------------
    //  DUT INPUTS
    // --------------------------------------------------------------
    reg              clk;
    reg              RST;
    reg              CE;
    reg              MODE;
    reg              CIN;
    reg  [1:0]       INP_VALID;
    reg  [N-1:0]     OPA;
    reg  [N-1:0]     OPB;
    reg  [N-1:0]     CMD;

    // --------------------------------------------------------------
    //  DUT OUTPUTS
    // --------------------------------------------------------------
    wire [(2*N)-1:0] RES_DUT;
    wire             COUT_DUT, OFLOW_DUT;
    wire             G_DUT, E_DUT, L_DUT, ERR_DUT;

    // --------------------------------------------------------------
    //  REFERENCE MODEL OUTPUTS
    // --------------------------------------------------------------
    wire [(2*N)-1:0] RES_REF;
    wire             COUT_REF, OFLOW_REF;
    wire             G_REF, E_REF, L_REF, ERR_REF;

    // --------------------------------------------------------------
    //  SCOREBOARD CONTROL
    // --------------------------------------------------------------
    integer pass_count = 0;
    integer fail_count = 0;
    reg     sb_enable  = 0;   

    initial clk = 0;
    always  #5 clk = ~clk;

    // --------------------------------------------------------------
    //  DUT INSTANTIATION
    // --------------------------------------------------------------
    FOUR_bit_ALU_rtl_design #(
        .N(N)
    ) dut (
        .OPA(OPA),
        .OPB(OPB),
        .INP_VALID(INP_VALID),
        .CIN(CIN),
        .CLK(clk),
        .RST(RST),
        .CMD(CMD),
        .CE(CE),
        .MODE(MODE),
        .COUT(COUT_DUT),
        .OFLOW(OFLOW_DUT),
        .RES(RES_DUT),
        .G(G_DUT),
        .E(E_DUT),
        .L(L_DUT),
        .ERR(ERR_DUT)
    );

    // --------------------------------------------------------------
    //  REFERENCE MODEL INSTANTIATION
    // --------------------------------------------------------------
    alu_reference_model #(N) REF (
        .MODE     (MODE),
        .CIN      (CIN),
        .INP_VALID(INP_VALID),
        .OPA      (OPA),
        .OPB      (OPB),
        .CMD      (CMD),
        .RES      (RES_REF),
        .COUT     (COUT_REF),
        .OFLOW    (OFLOW_REF),
        .G        (G_REF),
        .E        (E_REF),
        .L        (L_REF),
        .ERR      (ERR_REF)
    );

    // --------------------------------------------------------------
    //  SCOREBOARD TASK
    // --------------------------------------------------------------
    task compare_outputs;
        input [63:0] test_id;
        input [127:0] test_name; 
        begin
            if (!sb_enable) begin
                $display("[SKIP] t=%0t  Scoreboard disabled (reset/CE off)", $time);
            end else if (
                (RES_DUT   !== RES_REF)   ||
                (COUT_DUT  !== COUT_REF)  ||
                (OFLOW_DUT !== OFLOW_REF) ||
                (G_DUT     !== G_REF)     ||
                (E_DUT     !== E_REF)     ||
                (L_DUT     !== L_REF)     ||
                (ERR_DUT   !== ERR_REF)
            ) begin
                $display("------------------------------------------------");
                $display("[FAIL] TEST %0d | TIME=%0t", test_id, $time);
                $display("  CMD=%b MODE=%b OPA=%0d OPB=%0d INP_VALID=%b CIN=%b",
                         CMD, MODE, OPA, OPB, INP_VALID, CIN);
                $display("  DUT: RES=%0d COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                         RES_DUT, COUT_DUT, OFLOW_DUT, G_DUT, E_DUT, L_DUT, ERR_DUT);
                $display("  REF: RES=%0d COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                         RES_REF, COUT_REF, OFLOW_REF, G_REF, E_REF, L_REF, ERR_REF);
                $display("------------------------------------------------");
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] TEST %0d | t=%0t CMD=%b MODE=%b OPA=%0d OPB=%0d RES=%0d",
                         test_id, $time, CMD, MODE, OPA, OPB, RES_DUT);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Helper task
    task apply_and_check;
        input [63:0]       tid;
        input              mode_in;
        input [3:0]        cmd_in;
        input [N-1:0]      opa_in;
        input [N-1:0]      opb_in;
        input [1:0]        valid_in;
        input              cin_in;
        begin
            @(posedge clk);
            MODE      = mode_in;
            CMD       = cmd_in;
            OPA       = opa_in;
            OPB       = opb_in;
            INP_VALID = valid_in;
            CIN       = cin_in;
            @(posedge clk); #1;
            compare_outputs(tid, "");
        end
    endtask

    // --------------------------------------------------------------
    //  4-BIT FEC COVERAGE BOOST TASK
    // --------------------------------------------------------------
    task fec_coverage_boost;
        integer i;
        begin
            $display("=== BOOSTING FEC COVERAGE ===");
            
            // 1. Hammer INP_VALID OR conditions
            for (i = 0; i < 16; i = i + 1) begin
                apply_and_check(1000+i, 0, i, 4'hA, 4'h5, 2'b00, 0);
                apply_and_check(1020+i, 0, i, 4'hA, 4'h5, 2'b01, 0);
                apply_and_check(1040+i, 0, i, 4'hA, 4'h5, 2'b10, 0);
                apply_and_check(1060+i, 0, i, 4'hA, 4'h5, 2'b11, 0);
                
                apply_and_check(1080+i, 1, i, 4'hA, 4'h5, 2'b00, 0);
                apply_and_check(1100+i, 1, i, 4'hA, 4'h5, 2'b01, 0);
                apply_and_check(1120+i, 1, i, 4'hA, 4'h5, 2'b10, 0);
                apply_and_check(1140+i, 1, i, 4'hA, 4'h5, 2'b11, 0);
            end

            // 2. Hammer ROL/ROR specific bit conditions for 4-bit ERR logic (OPB[3] != 0 triggers ERR)
            apply_and_check(2000, 0, 4'd12, 4'hA, 4'b1000, 2'b11, 0); 
            apply_and_check(2001, 0, 4'd12, 4'hA, 4'b1001, 2'b11, 0);
            apply_and_check(2002, 0, 4'd13, 4'hA, 4'b1000, 2'b11, 0); 
            apply_and_check(2003, 0, 4'd13, 4'hA, 4'b1010, 2'b11, 0);

            // 3. Hammer Signed Arithmetic OFLOW conditions mapped for 4-bit ranges
            apply_and_check(3000, 1, 4'd11, 4'h3, 4'h5, 2'b11, 0); // Pos(3) + Pos(5) = OFLOW (+8 wraps to -8)
            apply_and_check(3001, 1, 4'd11, 4'h8, 4'hF, 2'b11, 0); // Neg(-8) + Neg(-1) = OFLOW (-9 wraps to +7)
            apply_and_check(3002, 1, 4'd12, 4'h7, 4'h8, 2'b11, 0); // Pos(7) - Neg(-8) = OFLOW (+15 wraps to -1)
            apply_and_check(3003, 1, 4'd12, 4'h8, 4'h1, 2'b11, 0); // Neg(-8) - Pos(1) = OFLOW (-9 wraps to +7)

            // 4. Random Bomb
            $display("=== MASSIVE RANDOM BOMB FOR RESIDUAL FEC ===");
            for (i = 0; i < 2000; i = i + 1) begin
                apply_and_check(4000+i, $random, $random, $random, $random, $random, $random);
            end
        end
    endtask

    // --------------------------------------------------------------
    //  MAIN STIMULUS
    // --------------------------------------------------------------
    initial begin
        RST       = 1;
        CE        = 1;
        MODE      = 0;
        CIN       = 0;
        OPA       = 0;
        OPB       = 0;
        CMD       = 0;
        INP_VALID = 0;
        sb_enable = 0;

        $display("=== RESET ===");
        #12;
        RST       = 0;
        sb_enable = 1;

        $display("=== ARITHMETIC DIRECT CASES ===");
        apply_and_check(1,  1, 4'b0000, 4'd5,  4'd3,  2'b11, 0);
        apply_and_check(2,  1, 4'b0000, 4'd15, 4'd15, 2'b11, 0);
        apply_and_check(3,  1, 4'b0000, 4'd0,  4'd0,  2'b11, 0);
        apply_and_check(4,  1, 4'b0000, 4'd0,  4'd15, 2'b11, 0);
        apply_and_check(5,  1, 4'b0000, 4'd15, 4'd1,  2'b11, 0);
        apply_and_check(6,  1, 4'b0001, 4'd10, 4'd3,  2'b11, 0);
        apply_and_check(7,  1, 4'b0001, 4'd2,  4'd7,  2'b11, 0);
        apply_and_check(8,  1, 4'b0001, 4'd0,  4'd0,  2'b11, 0);
        apply_and_check(9,  1, 4'b0001, 4'd0,  4'd15, 2'b11, 0);
        apply_and_check(10, 1, 4'b0010, 4'd5,  4'd6,  2'b11, 1);
        apply_and_check(11, 1, 4'b0010, 4'd15, 4'd15, 2'b11, 1);
        apply_and_check(12, 1, 4'b0011, 4'd9,  4'd2,  2'b11, 1);
        apply_and_check(13, 1, 4'b0011, 4'd0,  4'd0,  2'b11, 1);
        apply_and_check(14, 1, 4'b0100, 4'd8,  4'd0,  2'b01, 0);
        apply_and_check(15, 1, 4'b0100, 4'd15, 4'd0,  2'b01, 0);
        apply_and_check(16, 1, 4'b0101, 4'd8,  4'd0,  2'b01, 0);
        apply_and_check(17, 1, 4'b0101, 4'd0,  4'd0,  2'b01, 0);
        apply_and_check(18, 1, 4'b0110, 4'd0,  4'd7,  2'b10, 0);
        apply_and_check(19, 1, 4'b0110, 4'd0,  4'd15, 2'b10, 0);
        apply_and_check(20, 1, 4'b0111, 4'd0,  4'd7,  2'b10, 0);
        apply_and_check(21, 1, 4'b0111, 4'd0,  4'd0,  2'b10, 0);

        $display("=== COMPARE ===");
        apply_and_check(22, 1, 4'b1000, 4'd9,  4'd4,  2'b11, 0);
        apply_and_check(23, 1, 4'b1000, 4'd2,  4'd10, 2'b11, 0);
        apply_and_check(24, 1, 4'b1000, 4'd5,  4'd5,  2'b11, 0);
        apply_and_check(25, 1, 4'b1000, 4'd0,  4'd0,  2'b11, 0);
        apply_and_check(26, 1, 4'b1000, 4'hA,  4'h5,  2'b11, 0);
        apply_and_check(27, 1, 4'b1000, 4'h3,  4'hA,  2'b11, 0);

        $display("=== SIGNED OPS ===");
        apply_and_check(28, 1, 4'b1011, 4'b1110, 4'b0010, 2'b11, 0); // -2 + 2 = 0
        apply_and_check(29, 1, 4'b1011, 4'b0111, 4'b0111, 2'b11, 0); // +7 + +7 = OFLOW
        apply_and_check(30, 1, 4'b1011, 4'b1000, 4'b1111, 2'b11, 0); // -8 + -1 = OFLOW
        apply_and_check(31, 1, 4'b1100, 4'b1000, 4'b0010, 2'b11, 0); // -8 - +2 = OFLOW
        apply_and_check(32, 1, 4'b1100, 4'b0011, 4'b0101, 2'b11, 0); // +3 - +5 = -2
        apply_and_check(33, 1, 4'b1100, 4'b0101, 4'b0101, 2'b11, 0); // +5 - +5 = 0

        $display("=== MULTI-CYCLE CMD 9 and 10 ===");
        @(posedge clk);
        MODE      = 1; CMD = 4'b1001; OPA = 4'd2; OPB = 4'd3; INP_VALID = 2'b11;
        repeat(3) @(posedge clk); #1; compare_outputs(34, "");

        @(posedge clk);
        MODE      = 1; CMD = 4'b1010; OPA = 4'd4; OPB = 4'd2; INP_VALID = 2'b11;
        repeat(3) @(posedge clk); #1; compare_outputs(35, "");

        $display("=== MODE CHANGE DURING MULTI-CYCLE ===");
        sb_enable = 0;
        @(posedge clk); MODE=1; CMD=4'b1001; OPA=4'd2; OPB=4'd3; INP_VALID=2'b11;
        @(posedge clk); MODE = 0;
        @(posedge clk); #1;
        $display("[INFO-T36] MODE changed mid CMD9 | DUT: RES=%0d ERR=%b", RES_DUT, ERR_DUT);
        sb_enable = 1;

        sb_enable = 0;
        @(posedge clk); MODE=1; CMD=4'b1010; OPA=4'd4; OPB=4'd2; INP_VALID=2'b11;
        @(posedge clk); @(posedge clk); MODE = 0; #1;
        $display("[INFO-T37] MODE changed on cycle3 of CMD10 | DUT: RES=%0d ERR=%b", RES_DUT, ERR_DUT);
        sb_enable = 1;

        $display("=== LOGICAL  BOTH OPERANDS ===");
        apply_and_check(38, 0, 4'b0000, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(39, 0, 4'b0001, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(40, 0, 4'b0010, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(41, 0, 4'b0011, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(42, 0, 4'b0100, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(43, 0, 4'b0101, 4'b1010, 4'b1100, 2'b11, 0);
        apply_and_check(44, 0, 4'b0000, 4'hF, 4'hF, 2'b11, 0);
        apply_and_check(45, 0, 4'b0000, 4'h0, 4'hF, 2'b11, 0);
        apply_and_check(46, 0, 4'b0010, 4'h0, 4'h0, 2'b11, 0);
        apply_and_check(47, 0, 4'b0100, 4'hA, 4'hA, 2'b11, 0);
        apply_and_check(48, 0, 4'b0101, 4'hA, 4'hA, 2'b11, 0);

        $display("=== LOGICAL  SINGLE OPERAND ===");
        apply_and_check(49, 0, 4'b0110, 4'hA, 4'd0,    2'b01, 0);
        apply_and_check(50, 0, 4'b0111, 4'd0, 4'h5,    2'b10, 0);
        apply_and_check(51, 0, 4'b1000, 4'hA, 4'd0,    2'b01, 0);
        apply_and_check(52, 0, 4'b1001, 4'hA, 4'd0,    2'b01, 0);
        apply_and_check(53, 0, 4'b1010, 4'd0, 4'hC,    2'b10, 0);
        apply_and_check(54, 0, 4'b1011, 4'd0, 4'h3,    2'b10, 0);

        $display("=== ROTATE  VALID ===");
        apply_and_check(55, 0, 4'b1100, 4'hB, 4'h2, 2'b11, 0);
        apply_and_check(56, 0, 4'b1101, 4'hB, 4'h1, 2'b11, 0);
        apply_and_check(57, 0, 4'b1100, 4'hB, 4'h0, 2'b11, 0);
        apply_and_check(58, 0, 4'b1101, 4'hA, 4'h3, 2'b11, 0);

        $display("=== ROTATE  INVALID ===");
        apply_and_check(59, 0, 4'b1100, 4'hB, 4'h9, 2'b11, 0);
        apply_and_check(60, 0, 4'b1101, 4'hB, 4'hA, 2'b11, 0);
        apply_and_check(61, 0, 4'b1100, 4'hB, 4'hF, 2'b11, 0);
        apply_and_check(62, 0, 4'b1101, 4'hC, 4'h8, 2'b11, 0);

        $display("=== INP_VALID CORNERS ===");
        apply_and_check(63, 1, 4'b0000, 4'd5, 4'd3, 2'b00, 0);
        apply_and_check(64, 1, 4'b0000, 4'd5, 4'd3, 2'b01, 0);
        apply_and_check(65, 1, 4'b0000, 4'd5, 4'd3, 2'b10, 0);
        apply_and_check(66, 1, 4'b0100, 4'd5, 4'd3, 2'b10, 0);
        apply_and_check(67, 1, 4'b0110, 4'd5, 4'd3, 2'b01, 0);
        apply_and_check(68, 0, 4'b0000, 4'd5, 4'd3, 2'b00, 0);
        apply_and_check(69, 0, 4'b0110, 4'hA, 4'd0, 2'b10, 0);
        apply_and_check(70, 0, 4'b0111, 4'd0, 4'h5, 2'b01, 0);

        $display("=== CE DISABLE ===");
        apply_and_check(71, 1, 4'b0000, 4'd5, 4'd3, 2'b11, 0);
        @(posedge clk);
        CE        = 0; sb_enable = 0; CMD=4'b0001; OPA=4'd15; OPB=4'd1; INP_VALID=2'b11;
        @(posedge clk); #1;
        $display("[INFO-T72] CE=0 | DUT: RES=%0d (should be frozen from T71)", RES_DUT);
        CE        = 1; sb_enable = 1;

        $display("=== ASYNC RESET TEST ===");
        sb_enable = 0;
        @(posedge clk);
        MODE=1; CMD=4'b0000; OPA=4'd7; OPB=4'd6; INP_VALID=2'b11;
        #3 RST = 1; 
        #2;
        $display("[INFO-T73] During RST | DUT: RES=%0d (expect 0)", RES_DUT);
        RST = 0; sb_enable = 1;

        $display("=== RANDOM TESTS ===");
        repeat(50) begin
            @(posedge clk);
            MODE      = $random;
            CMD       = $random;
            OPA       = $random;
            OPB       = $random;
            CIN       = $random;
            INP_VALID = $random;
            @(posedge clk); #1;
            compare_outputs($time, "");
        end

        fec_coverage_boost();

        #50;
        $display("================================================");
        $display("  SIMULATION COMPLETE");
        $display("  PASS : %0d", pass_count);
        $display("  FAIL : %0d", fail_count);
        $display("================================================");
        $finish;

    end 

endmodule
