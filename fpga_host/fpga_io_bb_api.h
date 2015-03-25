#ifndef __FPGA_IO_BB_API_H__
#define __FPGA_IO_BB_API_H__
#include "ftd2xx.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum
{
    IO_BB_PARAM_DIRECTION = 0x00,
    IO_BB_PARAM_OUTVAL    = 0x01,
}io_param_t;


FT_HANDLE fpga_usb_init(void);

BOOL fpga_io_bb_write(FT_HANDLE ftHandle, UINT param, UINT value);

BOOL fpga_io_bb_read(FT_HANDLE ftHandle, UINT * rd_data);


#ifdef __cplusplus
}
#endif

#endif //__FPGA_IO_BB_API_H__

