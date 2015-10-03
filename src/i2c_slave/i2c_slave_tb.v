
`timescale 1ns / 1ps

module i2c_slave_tb;

    reg  scl;
    wire sda;
    reg  sda_out;
    wire slave_sda_oe;
    reg  enable_scl;
    reg  slave_ack;
    reg [7:0] read_byte;
    reg       ack;

    reg  clk;
    reg  rst_n;
    integer i;

    // SDA_OUT = 1 => high impedance.
    // SDA_OUT = 0 =>  drive SDA low.

    assign sda = sda_out ? 1'bz: 'b0;
    
    wire sda_in;

    assign sda_in = !(sda === 0);

    i2c_slave iut_i2c_slave 
                 (.in_clk(clk),
                  .in_rst_n(rst_n),
                  .in_scl(scl),
                  .io_sda(sda),
                  .out_sda_dir(slave_sda_oe));


    //66MHz
	always #7.5 clk = !clk; 

    always #100 if (enable_scl) scl = !scl;

    initial
    begin
        $dumpfile("i2c_slave_tb.lxt");
        $dumpvars(0, i2c_slave_tb);

		// Initialize 
		#0
		clk        = 0;
		rst_n      = 1;
        sda_out    = 1;
        scl        = 1;
        enable_scl = 0;
        read_byte  = 0;

		#10
		rst_n = 0;
		
		#50
		rst_n = 1;
        
        i2c_read_transaction(4);
        #200

        i2c_write_transaction(4, 'hAA);

        #200
        i2c_write_transaction(2, 'hBB);

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
            i2c_ll_read_byte( (i + 1 == nbytes) ? 1 : 0, read_byte);
            $display("Read byte is %x", read_byte);
        end

        I2C_Stop();
    end
    endtask

    task i2c_write_transaction;
        input [7:0] nbytes;
        input [7:0] wrbyte;
    begin
        $display("I2C write transaction nbytes=%d", nbytes);
        i2c_ll_start_cond();
        
        i2c_ll_wr_i2c_address('h50, 0, slave_ack);
        $display("Ack is %d", slave_ack);
       
        for (i = 0; i < nbytes; i = i + 1)
        begin
            // Nack last read
            i2c_ll_write_byte( ack, wrbyte);
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
