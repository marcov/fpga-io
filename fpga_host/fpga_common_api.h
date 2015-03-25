#ifndef __FPGA_COMMON_API_H__
#define __FPGA_COMMON_API_H__
#include "ftd2xx.h"

#ifdef __cplusplus
extern "C" {
#endif


FT_HANDLE   fpga_usb_init(void);

void        fpga_usb_deinit(FT_HANDLE ftHandle);



#ifdef __cplusplus
}
#endif

#endif //__FPGA_COMMON_API_H__

