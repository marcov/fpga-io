#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "fpga_io_bb_api.h"

#define WRITE_MAX_SIZE               1240
#define READ_MAX_SIZE                1240

#define IO_BB_BYTES(bits)   (((bits)/8) + (((bits)%8) ? (1) : (0)))

typedef enum
{
    IO_BB_CMD_READ        = 0x00,
    IO_BB_CMD_WRITE       = 0x01,
    IO_BB_CMD_OK          = 0x02,
}io_cmd_t;


#if DUMP_BUFFERS
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
#endif




BOOL fpga_io_bb_write(FT_HANDLE ftHandle, 
                      UINT param, 
                      UINT value)
{
    FT_STATUS	ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;

    // TODO: support more than 8 bits!
    if (param > 0xFF || value > 0xFF)
    {
        return FALSE;
    } 
    
    tx_buffer[0] = IO_BB_CMD_WRITE;
    tx_buffer[1] = param;
    tx_buffer[2] = value;
    bytesToWrite = 3;
    /////////////////

#if DUMP_BUFFERS 
    fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
    dumpBuffer(tx_buffer, bytesToWrite);
#endif

    ftStatus = FT_Write(ftHandle, tx_buffer, bytesToWrite, &bytesWritten);
    if (ftStatus != FT_OK || (bytesWritten != bytesToWrite))
    {
        fprintf(stdout, "FT_Write failed (error %d).\n", (int)ftStatus);
        fflush(stdout);
        return FALSE;
    }

    //fprintf(stdout, "Written %lu bytes\n", bytesWritten);
    bytesToRead = 1;  // Read just an ok.

       
    //fprintf(stdout, "Reading size... %u\n", bytesToRead);
    ftStatus = FT_Read(ftHandle, rx_buffer, bytesToRead, &bytesReturned);

    if (ftStatus != FT_OK)
    {
       fprintf(stdout, "Failure.  FT_Read returned %d\n", (int)ftStatus);
       fflush(stdout);
       return FALSE;
    }

#if DUMP_BUFFERS
    printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
    dumpBuffer(rx_buffer, bytesToRead);
#endif

    if (bytesReturned != bytesToRead)
    {
        fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
              (int)bytesReturned,
              (int)bytesToRead);
       fflush(stdout);
       return FALSE;
    }

    if (rx_buffer[0] != IO_BB_CMD_OK)
    {
       fprintf(stdout, "%s fail, ft_read rx_buffer[0]=%02x\n", __FUNCTION__, rx_buffer[0]);
       fflush(stdout);
       return FALSE;
    }
    
    return TRUE;
}


BOOL fpga_io_bb_read(FT_HANDLE ftHandle, UINT * rd_data)
{
    FT_STATUS   ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;
     
    
    tx_buffer[0] = IO_BB_CMD_READ;
    bytesToWrite = 1;
    ////////////////////////

#if DUMP_BUFFERS 
    fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
    dumpBuffer(tx_buffer, bytesToWrite);
#endif

    ftStatus = FT_Write(ftHandle, tx_buffer, bytesToWrite, &bytesWritten);
    if (ftStatus != FT_OK || (bytesWritten != bytesToWrite))
    {
        fprintf(stdout, "FT_Write failed (error %d).\n", (int)ftStatus);
        fflush(stdout);
        return FALSE;
    }

    //fprintf(stdout, "Written %lu bytes\n", bytesWritten);
    // TODO: support for more than 8 bits!!
    bytesToRead = 1;

       
    //fprintf(stdout, "Reading size... %u\n", bytesToRead);
    ftStatus = FT_Read(ftHandle, rx_buffer, bytesToRead, &bytesReturned);

    if (ftStatus != FT_OK)
    {
       fprintf(stdout, "Failure.  FT_Read returned %d\n", (int)ftStatus);
       fflush(stdout);
       return FALSE;
    }

#if DUMP_BUFFERS
    printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
    dumpBuffer(rx_buffer, bytesToRead);
#endif

    //Sleep(1000);

    if (bytesReturned != bytesToRead)
    {
        fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
              (int)bytesReturned,
              (int)bytesToRead);
       fflush(stdout);
       return FALSE;
    }
   
   *rd_data = (UINT)(rx_buffer[0]);

    return TRUE;
}
