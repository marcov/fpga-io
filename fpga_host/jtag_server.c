#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <stdlib.h>
#include <strings.h>
#include <unistd.h>

#include "fpga_io_bb_api.h"
#include "fpga_common_api.h"
#include "ftd2xx.h"

#define BE_VERBOSE 0

#if BE_VERBOSE
#define LOG_JTAG(...) printf(__VA_ARGS__)
#else
#define LOG_JTAG(...)
#endif

enum
{
    IO_TDI  = (1 << 0),
    IO_TMS  = (1 << 1),
    IO_TCK  = (1 << 2),
    IO_TRST = (1 << 3),
    IO_SRST = (1 << 4),
    IO_TDO  = (1 << 5),
};

static UINT curr_outval;
static FT_HANDLE ftHandle;


static int init_usb_fpga(void)
{
    UINT dir_output;
    
    fprintf(stderr, "usb init...\n");
    if ((ftHandle = fpga_usb_init()) == NULL)
    {
        return -1;
    }
    
    dir_output = IO_SRST | IO_TCK | IO_TDI | IO_TMS | IO_TRST;
    
    curr_outval = 0x00;
    fprintf(stderr, "io bb set outval: %02X...\n", curr_outval);
    if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_OUTVAL, curr_outval))
    {
        fprintf(stdout, "bb set outval failed.\n");
        return -1;
    }
    
    fprintf(stderr, "io bb set direction: %02X...\n", dir_output);
    if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_DIRECTION, dir_output))
    {
        fprintf(stdout, "bb set direction failed.\n");
        return -1;
    }
    
    return 0;
}


int main(void)
{
    int sockfd, newsockfd, portno;
    socklen_t clilen;
    char buffer[256];
    struct sockaddr_in serv_addr, cli_addr;
    int  n;
    
    if (init_usb_fpga())
    {
        printf("USB init failed!\n");
        return -1;
    }
    
    /* First call to socket() function */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    
    if (sockfd < 0)
    {
        perror("ERROR opening socket");
        exit(1);
    }
    
    /* Initialize socket structure */
    bzero((char *) &serv_addr, sizeof(serv_addr));
    portno = 5001;
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(portno);
    
    /* Now bind the host address using bind() call.*/
    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
    {
        perror("ERROR on binding");
        exit(1);
    }
    
    {
        const int       optVal = 1;
        const socklen_t optLen = sizeof(optVal);
        
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (void*) &optVal, optLen);
    }

    /* Now start listening for the clients, here process will
     * go in sleep mode and will wait for the incoming connection
     */
    
    printf("Starting TCP server on port %u...\n", portno);
    listen(sockfd, 0);
    clilen = sizeof(cli_addr);
    
    /* Accept actual connection from the client */
    newsockfd = accept(sockfd, (struct sockaddr *)&cli_addr, &clilen);
    if (newsockfd < 0)
    {
        perror("ERROR on accept");
        exit(1);
    }
    
    while (1)
    {
        /* If connection is established then start communicating */
        n = read(newsockfd, buffer, 1);
        
        if (n < 0)
        {
            perror("ERROR reading from socket");
            exit(1);
        }
        
        //printf("RX: len=%u '%c'\n", n, *buffer);
        
        switch (*buffer)
        {
            case 'R':
            {
                UINT readval;
                char val[1];
                
                if (!fpga_io_bb_read(ftHandle, &readval))
                {
                    fprintf(stderr, "io bb read failed\n");
                    return -1;
                }
                
                val[0] = ((readval & IO_TDO) != 0) ? '1' : '0';
                
                LOG_JTAG("r tdo=%c\n", *val);

                /* Write a response to the client */
                n = write(newsockfd, val , 1);
                
                if (n < 0)
                {
                    perror("ERROR writing to socket");
                    exit(1);
                }
                
                break;
            }
                
            case 'B':
                LOG_JTAG(">> Blink on\n");
                break;
            
            case 'b':
                LOG_JTAG(">> Blink off\n");
                break;
                
                
            case 'r':
            case 's':
            case 't':
            case 'u':
            {
                if (*buffer == 'r')
                {
                    curr_outval &= ~(IO_TRST | IO_SRST);
                    LOG_JTAG("reset srst=0 trst=0\n");
                }
                else if (*buffer == 's')
                {
                    curr_outval &= ~(IO_TRST);
                    curr_outval |= IO_SRST;
                    LOG_JTAG("reset srst=1 trst=0\n");
                }
                else if (*buffer == 't')
                {
                    curr_outval &= ~(IO_SRST);
                    curr_outval |= IO_TRST;
                    LOG_JTAG("reset srst=0 trst=1\n");
                }
                else if (*buffer == 'u')
                {
                    curr_outval |= (IO_TRST | IO_SRST);
                    LOG_JTAG("reset srst=1 trst=1\n");
                }
                
                curr_outval ^= (IO_TRST | IO_SRST);
                LOG_JTAG("io bb set outval: %02X...\n", curr_outval);
                if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_OUTVAL, curr_outval))
                {
                    fprintf(stdout, "i bb set outval failed.\n");
                    return -1;
                }
                
                break;
            }
   
            default:
            {
                char out = *buffer;
                
                if (out < '0' && out > '7')
                {
                    fprintf(stderr, "undetected command!");
                    return -1;
                }
                
                out -= '0';
                
                if (out & 0x01)
                {
                    curr_outval |= IO_TDI;
                }
                else
                {
                    curr_outval &= ~IO_TDI;
                }
                
                if (out & 0x02)
                {
                    curr_outval |= IO_TMS;
                }
                else
                {
                    curr_outval &= ~IO_TMS;
                }
                
                if (out & 0x04)
                {
                    curr_outval |= IO_TCK;
                }
                else
                {
                    curr_outval &= ~IO_TCK;
                }
                
                LOG_JTAG("tdi=%u ",  (out & 0x01) ? 1 : 0);
                LOG_JTAG("tms=%u ",  (out & 0x02) ? 1 : 0);
                LOG_JTAG("tck=%u",   (out & 0x04) ? 1 : 0);
                LOG_JTAG("\n");
                
#if 0
                fprintf(stderr, "io bb set outval: %02X...\n", curr_outval);
#endif
                if (!fpga_io_bb_write(ftHandle, IO_BB_PARAM_OUTVAL, curr_outval))
                {
                    fprintf(stdout, "bb set outval failed.\n");
                    return -1;
                }
                
                break;
            }
                
        }
    }
    
    fpga_usb_deinit(ftHandle);
    
    close(sockfd);
    return 0;
}
