
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
    reg [7:0] wr_buffer ['hFFFF : 0];
    reg [7:0] rd_buffer ['hFFFF : 0];


    // SDA_OUT = 1 => high impedance.
    // SDA_OUT = 0 =>  drive SDA low.
    assign sda = sda_out ? 1'bz: 'b0;
    
    wire sda_in;

    assign sda_in = !(sda === 0);

    i2c_slave_top i2c_slave_top_iut(
                              .in_ext_osc(clk),
                              .in_reset_n(rst_n),
                              .in_i2c_scl(scl),
                              .io_i2c_sda(sda));

    //66MHz
	always #7.5 clk = !clk; 

    always #100 if (enable_scl) scl = !scl;

    initial
    begin
        $dumpfile("i2c_slave_top_tb.lxt");
        $dumpvars(0, i2c_slave_top_testbench);

        $display("\n\n============= SIMULATION STARTED ==============");

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
        eeprom_read_at_address('h0001, 4);
        $display("\n===============================\n");

        #200
        eeprom_read_at_address('hAACC, 8);
        $display("\n===============================\n");
        
        
        #200
        eeprom_read_at_address('h0000, 'h10);
        $display("\n===============================\n");

        #1000
        $display("\n\n============= SIMULATION ENDED OK! ==============");
        $finish;
    end


    task eeprom_read_at_address;
        input integer eeprom_offset;
        input integer read_len;
    begin
        wr_buffer[0] = eeprom_offset[15:8];
        wr_buffer[1] = eeprom_offset[7:0];
        
        i2c_write_transaction(2);

        i2c_read_transaction(read_len);
       
        // Verify read data
        for (i = 0; i < read_len; i = i + 1)
        begin            
            if (rd_buffer[i] !== i2c_slave_top_iut.rom_mem_inst.mem[eeprom_offset + i])
            begin
                $display("======= ERROR ======= ");
                $display("Read data mismatch: rd=%x - expected=%x", 
                         rd_buffer[i], i2c_slave_top_iut.rom_mem_inst.mem[eeprom_offset + i]);
                $finish;        
            end    
        end
        
        $display("======= ROM DATA VERIFY OK! ======= ");
    end
    endtask


    task i2c_read_transaction;
        input integer nbytes;
    begin
        $display("= I2C read transaction nbytes=%d", nbytes);
        i2c_ll_start_cond();
        
        i2c_ll_wr_i2c_address('h50, 1, slave_ack);
        $display("=== I2C addr ACK is %d", slave_ack);
        
        if (slave_ack)
        begin
            $display("Error: expected ACK value 0!");
            $finish;
        end

        for (i = 0; i < nbytes; i = i + 1)
        begin
            // Nack last read
            i2c_ll_read_byte( (i + 1 == nbytes) ? 1 : 0, rd_buffer[i]);
            $display("=== read byte=%02X", rd_buffer[i]);
        end

        I2C_Stop();
    end
    endtask

    task i2c_write_transaction;
        input integer nbytes;
    begin
        $display("= I2C write transaction nbytes=%d", nbytes);
        i2c_ll_start_cond();
        
        i2c_ll_wr_i2c_address('h50, 0, slave_ack);
        $display("=== I2C addr ACK is %d", slave_ack);
       
        if (slave_ack)
        begin
            $display("Error: expected ACK value 0!");
            $finish;
        end

        for (i = 0; i < nbytes; i = i + 1)
        begin
            // Nack last read
            i2c_ll_write_byte( slave_ack, wr_buffer[i]);
            $display("=== written byte=%02X, ACK is %x", wr_buffer[i], slave_ack);
    
            if (slave_ack)
            begin
                $display("Error: expected ACK value 0!");
                $finish;
            end

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

        $write("==== SDA bits:");
        
        //Get a full byte
        for (i = 0; i < 8; i = i + 1) 
        begin
            wait(scl == 0);
            wait(scl);
            read_byte[7 - i] = sda_in;
            $write (" %b",sda_in);
        end
        $write("\n");

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
       
        $write("==== SDA bits:");
        //Write a full byte
        for (i = 0; i < 8; i = i + 1) 
        begin
            wait(scl == 0);
            sda_out = write_byte[7 - i];
            $write("  %b",sda_out);
            wait(scl);
        end
        $write("\n");

        //Release line
        wait(scl == 0);
        sda_out = 1;
        
        // Wait ack
        wait(scl);
        ack = sda_in;
    end
    endtask


endmodule
