/***************************************************************************
 *   Copyright (C) 2005 by Dominic Rath                                    *
 *   Dominic.Rath@gmx.de                                                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.           *
 ***************************************************************************/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <jtag/interface.h>
#include "bitbang.h"

#define TDO_BIT		1
#define TDI_BIT		2
#define TCK_BIT		4
#define TMS_BIT		8
#define TRST_BIT	16
#define SRST_BIT	32
#define VCC_BIT		64

#include <sys/mman.h>


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

/* low level command set
 */
static int fpga_bb_read(void);
static void fpga_bb_write(int tck, int tms, int tdi);
static void fpga_bb_reset(int trst, int srst);

static int fpga_bb_init(void);
static int fpga_bb_quit(void);

struct timespec fpga_bb_zzzz;

struct jtag_interface fpga_bb_interface = {
	.name = "fpga_bb",

	/*.supported = DEBUG_CAP_TMS_SEQ,*/
	.execute_queue = bitbang_execute_queue,

	.init = fpga_bb_init,
	.quit = fpga_bb_quit,
};

static struct bitbang_interface fpga_bb_bitbang = {
	.read = fpga_bb_read,
	.write = fpga_bb_write,
	.reset = fpga_bb_reset,
	.blink = 0,
};

static int fpga_bb_read(void)
{
	if (write(fd, read_pkt, sizeof(read_pkt)) != sizeof(read_pkt))
	{
		fprintf(stdout, "bb set outval failed.\n");
		return 0;
	}
	
	if (read(fd, readval, 1) != 1)
	{
		perror("read failed...\n");
		return 0;
	}

	return !!(readval[0] & IO_TDO);
}

static void fpga_bb_write(int tck, int tms, int tdi)
{
	static uint32_t write_ctr = 0;
   
	write_ctr++;
	if ((write_ctr & 0x3FF) == 0)
	{
		fprintf(stderr, "Written: %u bits\n", write_ctr);
	}
	
	if (tck)
        curr_outval |= IO_TCK;
	else
        curr_outval &= ~IO_TCK;

	if (tms)
        curr_outval |= IO_TMS;
	else
        curr_outval &= ~IO_TMS;

	if (tdi)
        curr_outval |= IO_TDI;
	else
        curr_outval &= ~IO_TDI;

	write_pkt[1] = IO_BB_PARAM_OUTVAL;
	write_pkt[2] = curr_outval;
	if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
	{
		fprintf(stdout, "bb set outval failed.\n");
		return ;
	}
	
	if (read(fd, readval, 1) != 1)
	{
		perror("read failed...\n");
		return ;
	}

	//nanosleep(&fpga_bb_zzzz, NULL);
}

/* (1) assert or (0) deassert reset lines */
static void fpga_bb_reset(int trst, int srst)
{
	if (trst == 0)
		curr_outval &= ~IO_TRST;
	else if (trst == 1)
		curr_outval |= IO_TRST;

	if (srst == 0)
		curr_outval &= ~IO_SRST;
	else if (srst == 1)
		curr_outval |= IO_SRST;
	
	curr_outval ^= (IO_TRST | IO_SRST);
	
	fprintf(stderr, "Resetting...\n");
	write_pkt[1] = IO_BB_PARAM_OUTVAL;
	write_pkt[2] = curr_outval;
	if (write(fd, write_pkt, sizeof(write_pkt)) != sizeof(write_pkt))
	{
		fprintf(stdout, "bb set outval failed.\n");
		return; 
	}
	
	if (read(fd, readval, 1) != 1)
	{
		perror("read failed...\n");
		return;
	} 

	//nanosleep(&fpga_bb_zzzz, NULL);
}


static int fpga_bb_init(void)
{
	bitbang_interface = &fpga_bb_bitbang;

	fpga_bb_zzzz.tv_sec = 0;
	fpga_bb_zzzz.tv_nsec = 10000000;

	//nanosleep(&fpga_bb_zzzz, NULL);
	
	/*
	 * Configure bit 0 (TDO) as an input, and bits 1-5 (TDI, TCK
	 * TMS, TRST, SRST) as outputs.  Drive TDI and TCK low, and
	 * TMS/TRST/SRST high.
	 */
	if (init_usb_fpga())
	{
		return -1;
	}
	
	return ERROR_OK;
}

static int fpga_bb_quit(void)
{

	return ERROR_OK;
}
