#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include "fpga_common_api.h"

#define CYCLEPORT_TIME_MS            3000

#define FT2232H_CYCLE_PORT           0
#define FT2232H_SET_TIMEOUTS         0
#define FT2232H_SET_USB_PARAMS       0
#define FT2232H_PORT_NUMBER          1U


FT_HANDLE fpga_usb_init(void)
{
    FT_HANDLE   ftHandle;
    FT_STATUS   ftStatus = FT_OK;
    FT_DEVICE   ftDevice;
    DWORD       deviceID;
    char        SerialNumber[16];
    char        Description[64];
    const int   portNumber = FT2232H_PORT_NUMBER;

    fprintf(stdout, "Starting with channel: %c\n", (portNumber == 0) ? 'A' : 'B');
    fflush(stdout);

    ftStatus = FT_Open(portNumber, &ftHandle);
    if (ftStatus != FT_OK)
    {
        /* FT_Open can fail if the ftdi_sio module is already loaded. */
        printf("FT_Open(%d) failed (error %d).\n", portNumber, (int)ftStatus);
        printf(\
        "\n"\
        "\n"\
        "On Mac OSX:\n"\
        "\n"\
        "Use 'sudo kextunload -bundle <driver name>' to remove all FTDI drivers, that\n"\
        "can be found by doing 'kextstat | grep -i ftdi'\n"\
        "like:\n"\
        "com.FTDI.driver.FTDIUSBSerialDriver\n"\
        "com.apple.driver.AppleUSBFTDI\n"\
        "\n"\
        "On Linux:\n"\
        "\n"\
        "Use lsmod to check if ftdi_sio (and usbserial) are present.\n"\
        "If so, unload them using rmmod, as they conflict with ftd2xx.\n");
        return NULL;
    }
    
    ftStatus = FT_GetDeviceInfo(
                                ftHandle,
                                &ftDevice,
                                &deviceID,
                                SerialNumber,
                                Description,
                                NULL
                                 );

    if (ftStatus == FT_OK) {
         if (ftDevice == FT_DEVICE_232H)
              printf ("Device is FT232H\n");
         else if (ftDevice == FT_DEVICE_4232H)
              printf ("Device is FT4232H\n");
         else if (ftDevice == FT_DEVICE_2232H)
              printf ("Device is FT2232H \n");
         else if (ftDevice == FT_DEVICE_232R)
              printf ("Device is FT232R \n");
         else if (ftDevice == FT_DEVICE_2232C)
              printf ("Device is FT2232C/L/D \n");
         else if (ftDevice == FT_DEVICE_BM)
              printf ("Device is FTU232BM \n");
         else if (ftDevice == FT_DEVICE_AM)
              printf ("Device is FT8U232AM \n");
         else
              printf ("Device unknown (this should not happen!)\n");
                // deviceID contains encoded device ID
                // SerialNumber, Description contain 0-terminated strings
    }
    else {
        printf("FT_GetDeviceType FAILED!\n");
        (void)FT_Close(ftHandle);
        return NULL;
    }

#if (FT2232H_CYCLE_PORT == 1)
    ftStatus = FT_CyclePort(ftHandle);
    //ftStatus = FT_ResetPort(ftHandle);
    if (ftStatus == FT_OK) 
    {
        // Port has been reset
        fprintf(stdout, "FT_ResetPort ok\n");
        Sleep(CYCLEPORT_TIME_MS);

         ftStatus = FT_Open(portNumber, &ftHandle);
         if (ftStatus != FT_OK)
         {
            /* FT_Open can fail if the ftdi_sio module is already loaded. */
            printf("FT_Open(%d) failed (error %d).\n", portNumber, (int)ftStatus);
            printf("Use lsmod to check if ftdi_sio (and usbserial) are present.\n");
            printf("If so, unload them using rmmod, as they conflict with ftd2xx.\n");
            return NULL;
         }
    }
    else 
    {
        // FT_ResetPort FAILED!
        printf("FT_CyclePort FAILED!\n");
        (void)FT_Close(ftHandle);
        return NULL;
    }

#endif
    
#if (FT2232H_SET_USB_PARAMS == 1)
    ftStatus = FT_SetUSBParameters(ftHandle, 64, 64);
    if (ftStatus == FT_OK) {
         // Port has been reset
         fprintf(stdout, "FT_SetUSBParameters ok\n");
    }
    else
    {
        fprintf(stdout, "FT_SetUSBParameters FAILED\n");
        (void)FT_Close(ftHandle);
        return NULL;
    }
#endif
    
#if (FT2232H_SET_TIMEOUTS == 1)
    ftStatus = FT_SetTimeouts(ftHandle, 1000, 1000);
    if (ftStatus == FT_OK) {
         // Port has been reset
         fprintf(stdout, "FT_SetTimeouts ok\n");
    }
    else
    {
        fprintf(stdout, "FT_ResetPort FAILED\n");
        return NULL;
    }

    ftStatus = FT_SetLatencyTimer(ftHandle, 2);
    if (ftStatus == FT_OK) {
         // Port has been reset
         fprintf(stdout, "FT_SetLatencyTimer ok\n");
    }
    else
    {
        fprintf(stdout, "FT_SetLatencyTimer FAILED\n");
        (void)FT_Close(ftHandle);
        return NULL;
    }
#endif

    return ftHandle;
}

void fpga_usb_deinit(FT_HANDLE ftHandle)
{

    (void)FT_Close(ftHandle);
    usleep(50 * 1000);
}
