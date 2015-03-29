#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <stdlib.h>
#include <strings.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>

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

typedef enum
{
    IO_BB_PARAM_DIRECTION = 0x00,
    IO_BB_PARAM_OUTVAL    = 0x01,
}io_param_t;

typedef enum
{
    IO_BB_CMD_READ        = 0x00,
    IO_BB_CMD_WRITE       = 0x01,
    IO_BB_CMD_OK          = 0x02,
}io_cmd_t;

static uint8_t curr_outval;
static int fd;
static const char * ftdi_path = "/dev/ttyUSB1";

static uint8_t write_pkt[] = {IO_BB_CMD_WRITE, 0x00, 0x00};
static uint8_t read_pkt[] = {IO_BB_CMD_READ};

char readval[1];

static int init_usb_fpga(void)
{
    uint8_t dir_output;
    
    fprintf(stderr, "usb init %s...\n", ftdi_path);
    if ((fd = open(ftdi_path, O_RDWR)) < 0)
    {
        perror("Serial port open failed");
        return -1;
    }
    
    dir_output = IO_SRST | IO_TCK | IO_TDI | IO_TMS | IO_TRST;
    
    curr_outval = 0x00;
    
    fprintf(stderr, "io bb set outval: %02X...\n", curr_outval);
    write_pkt[1] = IO_BB_PARAM_OUTVAL;
    write_pkt[2] = curr_outval;
    if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
    {
        fprintf(stdout, "bb set outval failed.\n");
        return -1;
    }
    if (read(fd, readval, 1) != 1)
    {
        perror("read failed...\n");
        return -1;
    }
    
    fprintf(stderr, "io bb set direction: %02X...\n", dir_output);
    write_pkt[1] = IO_BB_PARAM_DIRECTION;
    write_pkt[2] = dir_output;
    if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
    {
        fprintf(stdout, "bb set direction failed.\n");
        return -1;
    }
    
    if (read(fd, readval, 1) != 1)
    {
        perror("read failed...\n");
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
                
                if (write(fd, read_pkt, sizeof(read_pkt)) != sizeof(read_pkt))
                {
                    fprintf(stdout, "bb set outval failed.\n");
                    return -1;
                }
                
                if (read(fd, readval, 1) != 1)
                {
                    perror("read failed...\n");
                    return -1;
                }

                
                readval[0] = ((readval[0] & IO_TDO) != 0) ? '1' : '0';
                
                LOG_JTAG("r tdo=%c\n", *readval);

                /* Write a response to the client */
                n = write(newsockfd, readval , 1);
                
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
                
                fprintf(stderr, "io bb set outval: %02X...\n", curr_outval);
                write_pkt[1] = IO_BB_PARAM_OUTVAL;
                write_pkt[2] = curr_outval;
                if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
                {
                    fprintf(stdout, "bb set outval failed.\n");
                    return -1;
                }
                
                if (read(fd, readval, 1) != 1)
                {
                    perror("read failed...\n");
                    return -1;
                }
                
                break;
            }
   
            default:
            {
				char out = *buffer;
                static uint32_t write_ctr = 0;
               
			    write_ctr++;
				if ((write_ctr & 0x3FF) == 0)
				{
					printf("Written: %u bits\n", write_ctr);
				}
				
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
	 			write_pkt[1] = IO_BB_PARAM_OUTVAL;
                write_pkt[2] = curr_outval;
                if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
                {
                    fprintf(stdout, "bb set outval failed.\n");
                    return -1;
                }
                
                if (read(fd, readval, 1) != 1)
                {
                    perror("read failed...\n");
                    return -1;
                }
                
                break;
            }
                
        }
    }
    
    close(fd);
    
    close(sockfd);
    return 0;
}
