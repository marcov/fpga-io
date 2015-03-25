#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "fpga_3w_api.h"
#include "fpga_common_api.h"
#include "ftd2xx.h"


#define RETRIES_PER_WRITE            4
#define BYTES_TO_WRITE_INCREMENT     32
#define BYTES_TO_WRITE_START         32
#define WR_SLEEP_TIME_MS             0
#define WRITE_MAX_SIZE               1240
#define READ_MAX_SIZE                1240

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
#define MAX(X,Y) ((X) > (Y) ? (X) : (Y))


#define THREEWIRE_ADDRESS_BYTES 2
#define THREEWIRE_DATA_BYTES    2
#define THREEWIRE_ADDR_BITS     9
#define THREEWIRE_DATA_BITS     16
// Exponent for the 66MHz clock divider. Divider range is 2 to 256, i.e. exponent from 1 to 8
#define THREEWIRE_CLK_DIV_EXP   4  


#define DFLL_RB5                0x0156
#define FM_RESV3                0x2E0
#define FM_AMON_MAX_ADDRESS     0x02F6
static BOOL fill_table;
static UINT rd_table[FM_AMON_MAX_ADDRESS/THREEWIRE_DATA_BYTES];
extern const unsigned int fm_regs_reset_values[];
extern const unsigned int fm_regs_reset_values_len;

#if 1
static void Sleep(unsigned long ms)
{
    usleep(ms * 1000);
}
#endif


static void dumpBuffer(unsigned char *buffer, int elements)
{
	int j;

	for (j = 0; j < elements; j++)
	{
		if (j % 8 == 0)
		{
			if (j % 16 == 0)
				printf("\n%p: ", &buffer[j]);
			else
				printf("   "); // Separate two columns of eight bytes
		}
		printf("%02X ", (unsigned int)buffer[j]);
	}
	printf("\n\n");
}

static int ftdiPerformanceEvaluate(FT_HANDLE ftHandle)
{
    FT_STATUS	ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;
    unsigned    long long totalb = 0;
    unsigned    long long prevtotalb = 0;
    time_t      tstart, tnow;
    unsigned int i;
    unsigned int secondctr  = 0;
    struct
    {
        unsigned long rate;
        unsigned long size;
    }max  = {0, 0};
    
    for (i = 0; i < sizeof(tx_buffer); i++)
    {
	    tx_buffer[i] = 0x00;
    }

    bytesToWrite = BYTES_TO_WRITE_START;
    time(&tstart);
    fprintf(stdout, "Switching to transfer size of %u bytes\n", bytesToWrite);
    
    while(TRUE)
    {
        BOOL readAborted = FALSE;

        //fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
        //dumpBuffer(tx_buffer, bytesToWrite);

        ftStatus = FT_Write(ftHandle, tx_buffer, bytesToWrite, &bytesWritten);
        if (ftStatus != FT_OK || (bytesWritten != bytesToWrite))
        {
            fprintf(stdout, "FT_Write failed (error %d).\n", (int)ftStatus);
            fflush(stdout);
            goto exit;
        }

        totalb += bytesToWrite;

        //fprintf(stdout, "Written %lu bytes\n", bytesWritten);
        bytesToRead = (bytesToWrite);

        while (bytesToRead > 0)
        {
            unsigned int rs = 0;
            DWORD n = 0;
#if 0
            unsigned int retries = 0;
            while (n == 0)
            {
                ftStatus = FT_GetQueueStatus (ftHandle, &n);

                if (ftStatus != FT_OK)
                {
                    fprintf(stdout, "Failure.  FT_Read returned %d\n", (int)ftStatus);
                    fflush(stdout);
                    goto exit;
                }
                retries++;
                if (retries > 100 && n == 0)
                {
                    fprintf(stdout, "Queue size == 0\n");
                    fflush(stdout);
                    goto exit;
                    //retries = 0;
                    //continue;
                    //readAborted = TRUE;
                    break;
                }
                Sleep(10);
            }

            if (readAborted)
            {
                break;
            }
#else
            n = bytesToWrite;
#endif

           rs = n;
           //fprintf(stdout, "Read %u\n", rs);
           ftStatus = FT_Read(ftHandle, rx_buffer, rs, &bytesReturned);


           if (ftStatus != FT_OK)
           {
               fprintf(stdout, "Failure.  FT_Read returned %d\n", (int)ftStatus);
               fflush(stdout);
               goto exit;
           }

           totalb += bytesReturned;

           //printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
           //dumpBuffer(rx_buffer, bytesToRead);

           Sleep(WR_SLEEP_TIME_MS);

           if (bytesReturned != rs)
           {
                fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
                      (int)bytesReturned,
                      (int)bytesToRead);
               fflush(stdout);
               goto exit;
           }

            bytesToRead -= rs;
        }

        if (readAborted)
        {
            fprintf(stdout, "Read aborted\n");
            fflush(stdout);
            continue;
        }

#if 0
        for (i = 0; i < bytesToWrite; i++)
        if (tx_buffer[i] != (unsigned char)(~rx_buffer[i]))
        {
            fprintf(stdout, "Exception found at idx=%d, expected %02X != %02X\n", i, (unsigned char)(~tx_buffer[i]), rx_buffer[i]);
            fflush(stdout);
            //Sleep(3000);
            break;
        }
#endif
        //fflush(stdout);

        time(&tnow);

        if (tnow - tstart >=1)
        {
            tstart = tnow;

            if (max.size < totalb-prevtotalb)
            {
                max.size = totalb-prevtotalb;
                max.rate = bytesToWrite;
            }

            fprintf (stdout, "%lu B/s (max %luB @ %lu rate) \n", (unsigned long)(totalb - prevtotalb), max.size, max.rate);
            prevtotalb = totalb;
            secondctr++;

            if (secondctr >= RETRIES_PER_WRITE)
            {
                secondctr = 0;
                if (bytesToWrite + BYTES_TO_WRITE_INCREMENT <= WRITE_MAX_SIZE)
                {
                  bytesToWrite += BYTES_TO_WRITE_INCREMENT;
                }
                else
                {
                    bytesToWrite = WRITE_MAX_SIZE;
                }
                fprintf(stdout, "Switching to transfer size of %u bytes\n", bytesToWrite);
            }
            fflush(stdout);
        }
        
        
        //printf("%lu, %lu\n", tnow.tv_sec, tstart.tv_sec);    
        //fflush(stdout);
    }

exit:
    return -1;
}

static int readTest(FT_HANDLE ftHandle)
{
    unsigned    long total_bytes_txrx = 0;
    unsigned    long total_ops = 0;
    time_t      tstart, tnow;
    unsigned int secondctr  = 0;
    UINT      address;
    UINT       rd_data[32];
    //UINT       wr_data;
    UINT     burst;
    UINT i;
    struct
    {
        unsigned long bytes;
        unsigned long ops;
    }max  = {0, 0};
    
    address = 0;

    time(&tstart);
    
    fill_table = TRUE;
     
    fprintf(stdout, "Read endurance test started\n");
    
    burst = 0;

    fprintf(stdout, "Setting 3W IO bits\n");
    if (!fpga_3w_set_io_bits(ftHandle, THREEWIRE_ADDR_BITS, THREEWIRE_DATA_BITS, THREEWIRE_CLK_DIV_EXP))
    {
        fprintf(stdout, "%s failed.\n", __FUNCTION__);
        fflush(stdout);
        goto exit;
    }

    while(TRUE)
    {
        if (!fpga_3w_read(ftHandle, address, &rd_data[0], burst))
        {
            fprintf(stdout, "%s failed.\n", __FUNCTION__);
            printf("  address:   0x%04X\n", address);
            printf("  rd_data[0]:   0x%04X\n", rd_data[0]);
            fflush(stdout);
            goto exit;
        }

        //FTDI Write + Read size
        total_bytes_txrx += 1 + ((burst > 0) ? 1 : 0 ) + THREEWIRE_ADDRESS_BYTES + (burst + 1) * THREEWIRE_DATA_BYTES;


#if 1
        /* Compare mode */

        // Skip this data value because changes dynamically
        if (address == DFLL_RB5)
        {
            rd_data[0] &= ~((1<<14) | (1<< 13));
        }

        if (fill_table)
        {
            for (i = 0; i <= burst; i++)
            {
                // Skip this data value because changes dynamically
                if (address + i*THREEWIRE_DATA_BYTES == DFLL_RB5)
                {
                    rd_data[i] &= ~((1<<14) | (1<< 13));
                }
                
                //fprintf(stdout, "Fill table with rd_data[i]=%02X\n", rd_data[i]);
                //fflush(stdout);
                rd_table[address/THREEWIRE_DATA_BYTES + i] = rd_data[i];
            }
            
        }
        else
        {
            for (i = 0; i <= burst; i++)
            {
                // Skip this data value because changes dynamically
                if (address + i*THREEWIRE_DATA_BYTES == DFLL_RB5)
                {
                    rd_data[i] &= ~((1<<14) | (1<< 13));
                }

                if (rd_data[i] != rd_table[address/THREEWIRE_DATA_BYTES + i])
                {
                   fprintf(stdout, "RD FAIL address=%04X - rd_data[0]=%04X rd_table[address]=%04X\n",
                           address + (i * THREEWIRE_DATA_BYTES), 
                           rd_data[i], rd_table[address/THREEWIRE_DATA_BYTES + i]);
                   fflush(stdout);
                   goto exit;
                }
            }


        }
#endif
        
        //fprintf(stdout, "RD address=%04X - data=%04X\n", address*THREEWIRE_DATA_BYTES, rd_data[0]);
        
        address+= (burst + 1) * THREEWIRE_DATA_BYTES;

        if (address > FM_AMON_MAX_ADDRESS)
        {
            if (fill_table)
            {
                unsigned int i;
                fill_table = FALSE;
                fprintf(stdout, "RD full address space completed. Dump:\n");
                for (i = 0; i < address/THREEWIRE_DATA_BYTES; i++)
                {
                    if (i % 8 == 0)
                    {
                        fprintf(stdout, "\n%04X |", i * THREEWIRE_DATA_BYTES);
                    }
                    fprintf(stdout, "%04X  ", rd_table[i]);
                }
                fprintf(stdout,"\n");


                fprintf(stdout, "Comparing filled table with FM reset values...\n");
                for (i = 0; i < address/THREEWIRE_DATA_BYTES; i++)
                {
                    if (i >= fm_regs_reset_values_len)
                    {
                        fprintf(stdout, ">>>>> OUT OF RESET REGS VALUES!!!!\n");
                    }

                    if (rd_table[i] != fm_regs_reset_values[i])
                    {
                        fprintf(stdout, ">>>>> Regs compare w/ reset FAILED: address=%04X rd_table[i]=%04X reset_value[i]=%04X\n", 
                                i*THREEWIRE_DATA_BYTES, 
                                rd_table[i], 
                                fm_regs_reset_values[i]);
                    }
                    else
                    {

                        fprintf(stdout, "Regs compare w/ reset OK: address=%04X rd_table[i]=%04X reset_value[i]=%04X\n", 
                                i*THREEWIRE_DATA_BYTES, 
                                rd_table[i], 
                                fm_regs_reset_values[i]);
                    }
                }
                
                fflush(stdout);

            }
            address = 0;
#if 0
            fprintf(stdout, "RD full addresses done\n");
            Sleep(1000);
#endif
        }

        total_ops++;
        time(&tnow);

#if 1
        if (tnow - tstart >= 1)
        {
            tstart = tnow;

            if (max.bytes < total_bytes_txrx)
            {
                max.bytes = total_bytes_txrx;
            }

            if (max.ops < total_ops)
            {
                max.ops = total_ops;
            }
            
            fprintf (stdout, "%lu B/s - %lu ops/s (max %luB/s - %lu ops/s) \n", total_bytes_txrx, total_ops, max.bytes, max.ops);
            total_bytes_txrx = 0;
            total_ops = 0;
            
            secondctr++;

            fflush(stdout);
        }
        //printf("%lu, %lu\n", tnow.tv_sec, tstart.tv_sec);    
        //fflush(stdout);
#endif

    }

exit:
    return -1;
}


static int writeTest(FT_HANDLE ftHandle)
{
    unsigned    long total_bytes_txrx = 0;
    unsigned    long total_ops = 0;
    time_t      tstart, tnow;
    unsigned int secondctr  = 0;
    UINT wr_data;
    UINT rd_data[32];
    UINT address;

    struct
    {
        unsigned long bytes;
        unsigned long ops;
    }max  = {0, 0};
   
    //memset(tx_buffer, 0, sizeof(tx_buffer));
    
    address = FM_RESV3;

    time(&tstart);
    
    srand(time(NULL));


    fprintf(stdout, "Write test started\n");
    
    wr_data = (0x0000FFFF & rand());
    //wr_data = 0;
    
    fprintf(stdout, "Setting 3W IO bits\n");
    if (!fpga_3w_set_io_bits(ftHandle, THREEWIRE_ADDR_BITS, THREEWIRE_DATA_BITS, THREEWIRE_CLK_DIV_EXP))
    {
        fprintf(stdout, "%s failed.\n", __FUNCTION__);
        fflush(stdout);
        goto exit;
    }

    while(TRUE)
    {
        if (!fpga_3w_write(ftHandle, address, wr_data, 0))
        {
            fprintf(stdout, "%s failed.\n", __FUNCTION__);
            printf("  address:   0x%04X\n", address);
            printf("  wr_data:   0x%04X\n", wr_data);
            fflush(stdout);
            goto exit;
        }
        total_ops++;
        
        if (!fpga_3w_read(ftHandle, address, rd_data, 0))
        {
            fprintf(stdout, "%s failed.\n", __FUNCTION__);
            printf("  address:      0x%04X\n", address);
            printf("  rd_data[0]:   0x%04X\n", rd_data[0]);
            fflush(stdout);
            goto exit;
        }
        total_ops++;
        
        if (wr_data != rd_data[0])
        {
            fprintf(stdout, "ERROR - Read/Write sequence failed\n");
            fprintf(stdout, "  secondctr:  %d\n", secondctr);
            fprintf(stdout, "  address:   0x%04X\n", address);
            fprintf(stdout, "  wr_data:   0x%04X\n", wr_data);
            fprintf(stdout, "  rd_data[0]:   0x%04X\n", rd_data[0]);
            fflush(stdout);
            goto exit;
        }
        
        //fprintf(stderr, ".");
             
        time(&tnow);
#if 1
        if (tnow - tstart >= 1)
        {
            tstart = tnow;

            if (max.bytes < total_bytes_txrx)
            {
                max.bytes = total_bytes_txrx;
            }

            if (max.ops < total_ops)
            {
                max.ops = total_ops;
            }
            
            fprintf (stdout, "\nWrite test: - %lu ops/s (max %luB/s - %lu ops/s)", total_ops, max.bytes, max.ops);
            total_bytes_txrx = 0;
            total_ops = 0;
            
            secondctr++;

            fflush(stdout);
        }
        //printf("%lu, %lu\n", tnow.tv_sec, tstart.tv_sec);    
        //fflush(stdout);
#endif
    }

exit:
    return -1;
}



int main(int argc, char *argv[])
{
    FT_HANDLE ftHandle;

    if (argc <= 1)
    {
        fprintf(stderr, "Usage: %s [r|w]\n", argv[0]);
        return -1;
    }
    

    if (*argv[1] == 'r')
    {
        fprintf(stderr, "Running read test\n");
        if ((ftHandle = fpga_usb_init()) == NULL)
        {
            return -1;
        }
        readTest(ftHandle);
    }
    else if (*argv[1] == 'w')
    {
        fprintf(stderr, "Running write test\n");
        if ((ftHandle = fpga_usb_init()) == NULL)
        {
            return -1;
        }
        writeTest(ftHandle);
    }
    else
    {
        fprintf(stderr, "Usage: %s [r|w]\n", argv[0]);
        return -1;
    }
    
    fpga_usb_deinit(ftHandle);

    //ftdiPerformanceEvaluate(ftHandle);
    return 0;
}
