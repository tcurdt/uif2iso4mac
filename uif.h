/*
    Copyright 2008 Torsten Curdt, http://vafer.org

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

    http://www.gnu.org/licenses/gpl.txt
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <zlib.h>

typedef uint8_t     u8;
typedef uint16_t    u16;
typedef uint32_t    u32;
typedef uint64_t    u64;

#define BBIS_SIGN   0x73696262
#define BLHR_SIGN   0x72686c62
#define BSDR_SIGN   0x72647362

#define off_t   off64_t
#define fseek   fseeko
#define ftell   ftello

#pragma pack(2)

typedef struct {
    u32     sign;       // blhr
    u32     size;       // size of the data plus ver and num
    u32     ver;        // ignored
    u32     num;        // number of blhr_data structures
} blhr_t;

typedef struct {
    u64     offset;     // input offset
    u32     zsize;      // block size
    u32     sector;     // where to place the output
    u32     size;       // size in sectors!
    u32     type;       // type
} blhr_data_t;

typedef struct {
    u32     sign;       // bbis
    u32     unknown1;   // ignored, probably the size of the structure
    u16     ver;        // version, 1
    u32     image_type; // 8
    u16     padding;    // ignored
    u32     sectors;    // number of sectors of the ISO
    u32     sectorsz;   // CD use sectors and this is the size of them (chunks)
    u32     unknown2;   // almost ignored
    u64     blhr;       // where is located the blhr header
    u32     blhrbbissz; // total size of the blhr and bbis headers
    u8      hash[16];   // hash? what algo?
    u32     unknown3;   // ignored
    u32     unknown4;   // ignored
} bbis_t;

#pragma pack()

extern int endian;

void myalloc(u8 **data, unsigned wantsize, unsigned *currsize);
void myfr(FILE *fd, void *data, unsigned size);
void myfw(FILE *fd, void *data, unsigned size);

int unzip(z_stream *z, u8 *in, int insz, u8 *out, int outsz);
void b2l_blhr(blhr_t *p);
void b2l_blhr_data(blhr_data_t *p);
void b2l_bbis(bbis_t *p);
void b2l_16(u16 *num);
void b2l_32(u32 *num);
void b2l_64(u64 *num);
u8 *show_hash(u8 *hash);