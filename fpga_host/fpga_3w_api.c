#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "fpga_3w_api.h"

#define WRITE_MAX_SIZE               1240
#define READ_MAX_SIZE                1240

#define THREEWIRE_BYTES(bits)   (((bits)/8) + (((bits)%8) ? (1) : (0)))


static struct {
    UINT address_bits;
    UINT data_bits;
} fpga_3w_info = {
    .address_bits  = 9,
    .data_bits = 16,
};

enum
{
    THREEWIRE_CMD_READ        = 0x00,
    THREEWIRE_CMD_WRITE       = 0x01,
    THREEWIRE_CMD_OK          = 0x02,
    THREEWIRE_CMD_SET_IO_BITS = 0x05,
    THREEWIRE_CMD_MODE_BURST  = 0x80,
};


BOOL fpga_3w_set_io_bits(FT_HANDLE ftHandle, UINT address_bits, UINT data_bits, UINT clk_div_exponent)
{
    FT_STATUS   ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;

    fpga_3w_info.address_bits  = address_bits;
    fpga_3w_info.data_bits     = data_bits; 
    
    tx_buffer[0] = THREEWIRE_CMD_SET_IO_BITS;
    tx_buffer[1] = address_bits;
    tx_buffer[2] = data_bits;
    tx_buffer[3] = clk_div_exponent;

    bytesToWrite = 4;
    
    //fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
    //dumpBuffer(tx_buffer, bytesToWrite);
    
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


    //printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
    //dumpBuffer(rx_buffer, bytesToRead);

    if (bytesReturned != bytesToRead)
    {
        fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
              (int)bytesReturned,
              (int)bytesToRead);
       fflush(stdout);
       return FALSE;
    }

    if (rx_buffer[0] != THREEWIRE_CMD_OK)
    {
       fprintf(stdout, "%s fail, ft_read rx_buffer[0]=%02x\n", __FUNCTION__, rx_buffer[0]);
       fflush(stdout);
       return FALSE;
    }
    
    return TRUE;
}


BOOL fpga_3w_write(FT_HANDLE ftHandle, 
                   UINT address, 
                   UINT wr_data, 
                   UINT burst)
{
    FT_STATUS	ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;
    UINT        i;
    UINT        addr_offset;

    //prepare address for FM format.
    address >>= 1;
     
    tx_buffer[0] = THREEWIRE_CMD_WRITE;
    
    if (burst > 0)
    {
        tx_buffer[0] |= THREEWIRE_CMD_MODE_BURST;
        tx_buffer[1] = burst;
        addr_offset = 2;
    }
    else
    {
        addr_offset = 1;
    }

    tx_buffer[addr_offset] = address >> 8;
    tx_buffer[addr_offset + 1] = address & 0xFF;
    /////////////////

    for (i = 0; i <= burst; i++)
    {
        tx_buffer[addr_offset + THREEWIRE_BYTES(fpga_3w_info.address_bits) + i] = wr_data >> 8;
        tx_buffer[addr_offset + THREEWIRE_BYTES(fpga_3w_info.address_bits) + 1 + i] = wr_data & 0xFF;
    }

    bytesToWrite = addr_offset + 
                   THREEWIRE_BYTES(fpga_3w_info.address_bits)+ 
                   (1 + burst) * THREEWIRE_BYTES(fpga_3w_info.data_bits);
    
    //fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
    //dumpBuffer(tx_buffer, bytesToWrite);
    
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


    //printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
    //dumpBuffer(rx_buffer, bytesToRead);

    if (bytesReturned != bytesToRead)
    {
        fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
              (int)bytesReturned,
              (int)bytesToRead);
       fflush(stdout);
       return FALSE;
    }

    if (rx_buffer[0] != THREEWIRE_CMD_OK)
    {
       fprintf(stdout, "%s fail, ft_read rx_buffer[0]=%02x\n", __FUNCTION__, rx_buffer[0]);
       fflush(stdout);
       return FALSE;
    }
    
    return TRUE;
}


BOOL fpga_3w_read(FT_HANDLE ftHandle, UINT address, UINT * rd_data, UINT burst)
{
    FT_STATUS   ftStatus = FT_OK;
    UCHAR       tx_buffer[WRITE_MAX_SIZE];
    DWORD       bytesWritten = 0;
    UCHAR       rx_buffer[READ_MAX_SIZE];
    DWORD       bytesToRead = 0;
    DWORD       bytesReturned = 0;
    DWORD       bytesToWrite = 0;
    UINT        i;
    UINT        addr_offset;
     
    //prepare address for FM format.
    address >>= 1;
    
    tx_buffer[0] = THREEWIRE_CMD_READ;
    
    if (burst > 0)
    {
        tx_buffer[0] |= THREEWIRE_CMD_MODE_BURST;
        tx_buffer[1] = burst;
        addr_offset = 2;
    }
    else
    {
        addr_offset = 1;
    }

    tx_buffer[addr_offset] = address >> 8;
    tx_buffer[addr_offset + 1] = address & 0xFF;

    bytesToWrite = addr_offset + THREEWIRE_BYTES(fpga_3w_info.address_bits);
    
    //fprintf(stdout, "Writing %lu bytes: \n",bytesToWrite);
    //dumpBuffer(tx_buffer, bytesToWrite);
    
    ftStatus = FT_Write(ftHandle, tx_buffer, bytesToWrite, &bytesWritten);
    if (ftStatus != FT_OK || (bytesWritten != bytesToWrite))
    {
        fprintf(stdout, "FT_Write failed (error %d).\n", (int)ftStatus);
        fflush(stdout);
        return FALSE;
    }

    //fprintf(stdout, "Written %lu bytes\n", bytesWritten);
    bytesToRead = (burst + 1) * THREEWIRE_BYTES(fpga_3w_info.data_bits);

       
    //fprintf(stdout, "Reading size... %u\n", bytesToRead);
    ftStatus = FT_Read(ftHandle, rx_buffer, bytesToRead, &bytesReturned);

    if (ftStatus != FT_OK)
    {
       fprintf(stdout, "Failure.  FT_Read returned %d\n", (int)ftStatus);
       fflush(stdout);
       return FALSE;
    }

    //printf("Read %lu/%lu bytes\n", bytesToRead, bytesReturned);
    //dumpBuffer(rx_buffer, bytesToRead);
    
    //Sleep(1000);

    if (bytesReturned != bytesToRead)
    {
        fprintf(stdout, "Failure.  FT_Read only read %d (of %d) bytes\n",
              (int)bytesReturned,
              (int)bytesToRead);
       fflush(stdout);
       return FALSE;
    }
   
    for (i = 0; i <= burst; i+= THREEWIRE_BYTES(fpga_3w_info.data_bits))
     {
        *rd_data = ((UINT)(rx_buffer[i]) << 8) | ((UINT)rx_buffer[i+1]);
        rd_data++;
    }

    return TRUE;
}
