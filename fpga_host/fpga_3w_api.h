#ifndef __FPGA_3W_API_H__
#define __FPGA_3W_API_H__
#include "ftd2xx.h"

#ifdef __cplusplus
extern "C" {
#endif

FT_HANDLE fpga_3w_init (void);
BOOL fpga_3w_read      (FT_HANDLE ftHandle,
                        UINT address,      
                        UINT * rd_data, 
                        UINT burst);

BOOL fpga_3w_write     (FT_HANDLE ftHandle,
                        UINT address,      
                        UINT wr_data, 
                        UINT burst);

BOOL fpga_3w_set_io_bits(FT_HANDLE ftHandle, 
                         UINT address_bits, 
                         UINT data_bits,
                         UINT clk_div_exponent);

#ifdef __cplusplus
}
#endif

#endif //__FPGA_3W_API_H__
