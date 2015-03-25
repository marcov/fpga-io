#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "fpga_io_bb_api.h"
#include "fpga_common_api.h"
#include "ftd2xx.h"



#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
#define MAX(X,Y) ((X) > (Y) ? (X) : (Y))




#if 1
static void Sleep(unsigned long ms)
{
    usleep(ms * 1000);
}
#endif


int main(int argc, char *argv[])
{
    FT_HANDLE ftHandle;
    UINT rd_data[256];
    UINT direction, outval;

    (void)argc;
    (void)argv;

    fprintf(stderr, "usb init...\n");
    if ((ftHandle = fpga_usb_init()) == NULL)
    {
        return -1;
    }
    
    direction = 0xFF;
    fprintf(stderr, "io bb set direction: %02X...\n", direction);
    if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_DIRECTION, direction))
    {
        fprintf(stdout, "i bb set direction failed.\n");
        return -1; 
    }

    outval = 0xFF;
    fprintf(stderr, "io bb set outval: %02X...\n", outval);
    if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_OUTVAL, outval))
    {
        fprintf(stdout, "i bb set outval failed.\n");
        return -1; 
    }

    if (!fpga_io_bb_read(ftHandle, &rd_data[0]))
    {
        fprintf(stderr, "io bb read failed\n");
        return -1;
    }
    fprintf(stderr, "io bb read val: %02X\n", rd_data[0]);

    outval = 0xAA;
    fprintf(stderr, "io bb set outval: %02X...\n", outval);
    if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_OUTVAL, outval))
    {
        fprintf(stdout, "i bb set outval failed.\n");
        return -1; 
    }

    if (!fpga_io_bb_read(ftHandle, &rd_data[0]))
    {
        fprintf(stderr, "io bb read failed\n");
        return -1;
    }
    fprintf(stderr, "io bb read val: %02X\n", rd_data[0]);


    fpga_usb_deinit(ftHandle);

    return 0;
}
