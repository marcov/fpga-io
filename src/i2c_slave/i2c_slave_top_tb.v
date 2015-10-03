
`timescale 1ns / 1ps


module i2c_slave_top_testbench;
    reg  scl;
    wire sda;
    reg  sda_out;
    wire slave_sda_oe;
    reg  enable_scl;
    reg  slave_ack;
    reg       ack;

    reg  clk;
    reg  rst_n;
    integer i;
    reg [7:0] wr_buffer [7:0];
    reg [7:0] rd_buffer [7:0];
    integer mem_offset;


    // SDA_OUT = 1 => high impedance.
    // SDA_OUT = 0 =>  drive SDA low.
    assign sda = sda_out ? 1'bz: 'b0;
    
    wire sda_in;

    assign sda_in = !(sda === 0);

    i2c_slave_top i2c_slave_top_iut(
                              .in_ext_osc(clk),
                              .in_reset_n(rst_n),
                              .in_scl(scl),
                              .io_sda(sda));

    //66MHz
	always #7.5 clk = !clk; 

    always #100 if (enable_scl) scl = !scl;

    initial
    begin
        $dumpfile("i2c_slave_top_tb.lxt");
        $dumpvars(0, i2c_slave_top_testbench);

		// Initialize 
		#0
		clk        = 0;
		rst_n      = 1;
        sda_out    = 1;
        scl        = 1;
        enable_scl = 0;

		#10
		rst_n = 0;
		
		#50
		rst_n = 1;
        
        #200
        wr_buffer[0] = 'h00;
        wr_buffer[1] = 'h01;
        mem_offset = (wr_buffer[0] << 8) | wr_buffer[1];
        i2c_write_transaction(2);

        i2c_read_transaction(4);
        
        for (i = 0; i < 4; i = i + 1)
        begin            
            if (rd_buffer[i] != i2c_slave_top_iut.rom_mem_inst.mem[mem_offset + i])
            begin
                $display("======= ERROR ======= ");
                $display("Read data mismatch: rd=%x - expected=%x", 
                         rd_buffer[i], i2c_slave_top_iut.rom_mem_inst.mem[mem_offset + i]);
                $finish;        
            end    
        end


        #200
        wr_buffer[0] = 'hAA;
        wr_buffer[1] = 'hCC;
        mem_offset = (wr_buffer[0] << 8) | wr_buffer[1];
        i2c_write_transaction(2);

        i2c_read_transaction(8);

        for (i = 0; i < 4; i = i + 1)
        begin            
            if (rd_buffer[i] != i2c_slave_top_iut.rom_mem_inst.mem[mem_offset + i])
            begin
                $display("======= ERROR ======= ");
                $display("Read data mismatch: rd=%x - expected=%x", 
                         rd_buffer[i], i2c_slave_top_iut.rom_mem_inst.mem[mem_offset + i]);
                $finish;        
            end    
        end

        #1000
        $finish;
    end


    task i2c_read_transaction;
        input [7:0] nbytes;
    begin
        $display("I2C read transaction nbytes=%d", nbytes);
        i2c_ll_start_cond();
        
        i2c_ll_wr_i2c_address('h50, 1, slave_ack);
        $display("Ack is %d", slave_ack);
       
        for (i = 0; i < nbytes; i = i + 1)
        begin
            // Nack last read
            i2c_ll_read_byte( (i + 1 == nbytes) ? 1 : 0, rd_buffer[i]);
            $display("Read byte is %x", rd_buffer[i]);
        end

        I2C_Stop();
    end
    endtask

    task i2c_write_transaction;
        input [7:0] nbytes;
    begin
        $display("I2C write transaction nbytes=%d", nbytes);
        i2c_ll_start_cond();
        
        i2c_ll_wr_i2c_address('h50, 0, slave_ack);
        $display("Ack is %d", slave_ack);
       
        for (i = 0; i < nbytes; i = i + 1)
        begin
            // Nack last read
            i2c_ll_write_byte( ack, wr_buffer[i]);
            $display("Write byte, ACK is %x", ack);
        end

        I2C_Stop();
    end
    endtask

    //// Low level functions.
    task i2c_ll_start_cond;
    begin
        if (sda_out != 1)
        begin
            $display("SDA should be high!!");
            $finish;
        end

        if (scl == 0 || enable_scl)
        begin
            $display("SCL should be high and disabled!!");
            $finish;
        end
       
        #50
        //Generate a start condition
        sda_out = 0;
        
        #50;
        enable_scl = 1;
    end
    endtask

    task I2C_Stop;
    begin
        if (enable_scl)
        begin
            wait(scl == 0);
            sda_out = 0;
            wait(scl);
            enable_scl = 0;
        end
        
        if (sda_out != 0)
        begin
            $display("SDA should be low!!");
            $finish;
        end

        if (scl == 0)
        begin
            scl = 1;
        end
       
        #50
        //Generate a start condition
        sda_out = 1;
        
        #50;
    end
    endtask

    task i2c_ll_wr_i2c_address;
        input [7:0] address;
        input r_w;
        output ack;
    begin : tx_addr_proc
        integer i;
    
        //Send i2c address
        for (i = 0; i < 7; i = i + 1) 
        begin
            wait(scl);
            wait(scl == 0);
            sda_out = address[6 - i];
        end

        //send r/w
        wait(scl);
        wait(scl == 0);
        sda_out = r_w;

        //wait ack
        wait(scl);
        wait(scl == 0);
        sda_out = 1;
        wait(scl);
        ack = sda;
    end
    endtask



    task i2c_ll_read_byte;
        input ack;
        output [7 : 0] read_byte;
    begin : tx_addr_proc
        integer i;
        
        read_byte = 0;

        //Get a full byte
        for (i = 0; i < 8; i = i + 1) 
        begin
            wait(scl == 0);
            wait(scl);
            read_byte[7 - i] = sda_in;
            $display("== %b",sda_in);
        end

        //send ACK
        wait(scl == 0);
        sda_out = ack;

        //Release line
        wait(scl);
        wait(scl == 0);
        sda_out = 1;
    end
    endtask


    task i2c_ll_write_byte;
        output ack;
        input [7 : 0] write_byte;
    begin : tx_addr_proc
        integer i;
        
        //Write a full byte
        for (i = 0; i < 8; i = i + 1) 
        begin
            wait(scl == 0);
            sda_out = write_byte[7 - i];
            $display("== %b",sda_out);
            wait(scl);
        end

        //Release line
        wait(scl == 0);
        sda_out = 1;
        
        // Wait ack
        wait(scl);
        ack = sda_in;
    end
    endtask


endmodule
