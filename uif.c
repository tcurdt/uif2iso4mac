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

#include "uif.h"

int endian;

void myfw(FILE *fd, void *data, unsigned size) {
    if(fwrite(data, 1, size, fd) == size) return;

//    printf("\nError: problems during the writing of the output file\n");
//    myexit();
}

void myalloc(u8 **data, unsigned wantsize, unsigned *currsize) {
    if(wantsize <= *currsize) return;
    *data = realloc(*data, wantsize);
    if(!*data) {
//        std_err();
    }
    *currsize = wantsize;
}


void myfr(FILE *fd, void *data, unsigned size) {
    if(fread(data, 1, size, fd) == size) return;

//    printf("\nError: incomplete input file, can't read %u bytes\n", size);
//    myexit();
}

int unzip(z_stream *z, u8 *in, int insz, u8 *out, int outsz) {
    inflateReset(z);

    z->next_in   = in;
    z->avail_in  = insz;
    z->next_out  = out;
    z->avail_out = outsz;
    if(inflate(z, Z_SYNC_FLUSH) != Z_STREAM_END) {
//        printf("\nError: the compressed input is wrong or incomplete\n");
//        myexit();
    }
    return(z->total_out);
}

void b2l_blhr(blhr_t *p) {
    if(!endian) return;
    b2l_32(&p->sign);
    b2l_32(&p->size);
    b2l_32(&p->ver);
    b2l_32(&p->num);
}



void b2l_blhr_data(blhr_data_t *p) {
    if(!endian) return;
    b2l_64(&p->offset);
    b2l_32(&p->zsize);
    b2l_32(&p->sector);
    b2l_32(&p->size);
    b2l_32(&p->type);
}



void b2l_bbis(bbis_t *p) {
    if(!endian) return;
    b2l_32(&p->sign);
    b2l_32(&p->unknown1);
    b2l_16(&p->ver);
    b2l_32(&p->image_type);
    b2l_16(&p->padding);
    b2l_32(&p->sectors);
    b2l_32(&p->sectorsz);
    b2l_32(&p->unknown2);
    b2l_64(&p->blhr);
    b2l_32(&p->blhrbbissz);
    b2l_32(&p->unknown3);
    b2l_32(&p->unknown4);
}



void b2l_16(u16 *num) {
    u16     tmp;

    if(!endian) return;

    tmp = *num;
    *num = ((tmp & 0xff00) >> 8) |
           ((tmp & 0x00ff) << 8);
}



void b2l_32(u32 *num) {
    u32     tmp;

    if(!endian) return;

    tmp = *num;
    *num = ((tmp & 0xff000000) >> 24) |
           ((tmp & 0x00ff0000) >>  8) |
           ((tmp & 0x0000ff00) <<  8) |
           ((tmp & 0x000000ff) << 24);
}



void b2l_64(u64 *num) {
    u64     tmp;

    if(!endian) return;

    tmp = *num;
    *num = ((u64)(tmp & (u64)0xff00000000000000ULL) >> 56) |
           ((u64)(tmp & (u64)0x00ff000000000000ULL) >> 40) |
           ((u64)(tmp & (u64)0x0000ff0000000000ULL) >> 24) |
           ((u64)(tmp & (u64)0x000000ff00000000ULL) >>  8) |
           ((u64)(tmp & (u64)0x00000000ff000000ULL) <<  8) |
           ((u64)(tmp & (u64)0x0000000000ff0000ULL) << 24) |
           ((u64)(tmp & (u64)0x000000000000ff00ULL) << 40) |
           ((u64)(tmp & (u64)0x00000000000000ffULL) << 56);
}

u8 *show_hash(u8 *hash) {
    int     i;
    static u8   vis[33];
    static const char hex[16] = "0123456789abcdef";
    u8      *p;

    p = vis;
    for(i = 0; i < 16; i++) {
        *p++ = hex[hash[i] >> 4];
        *p++ = hex[hash[i] & 15];
    }
    *p = 0;

    return(vis);
}