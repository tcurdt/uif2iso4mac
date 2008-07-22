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

const char *fixedkeys[] = {
        "FAngS)snOt32",  "AglEy29TarsI;",     "bum87OrYx*THeCa", "ARMy67sabot&",
        "FoOTs:blaZe70", "panIc+elD%self79",  "Usnea*hest98",    "apex(TUft!BLOKE70",
        "sword18rEpP}",  "ARb10naVY=Rouse",   "PAIR18gAG:swAYs", "gums}Box73yANg",
        "naVal45drain]", "Cams42hEt83faiLs)", "rIaNt$Notch5",    "ExaCT&art*MEteS47",
        NULL
};



int mywrite(FILE *fd, void *data, unsigned size) {
    if(fwrite(data, 1, size, fd) == size) {
        return 0;
    }
    
    return -1;
}

int myread(FILE *fd, void *data, unsigned size) {
    if(fread(data, 1, size, fd) == size) {
        return 0;
    }
    
    return -1;
}

int unzip(z_stream *z, u8 *in, int insz, u8 *out, int outsz) {
    inflateReset(z);

    z->next_in   = in;
    z->avail_in  = insz;
    z->next_out  = out;
    z->avail_out = outsz;

    if(inflate(z, Z_FINISH) != Z_STREAM_END) {
        return -1;
    }

    return(z->total_out);
}

u8 *blhr_unzip(FILE *fd, z_stream *z, DES_key_schedule *ctx, u32 zsize, u32 unzsize) {
    u8   *in  = NULL;
    u8          *data;

    in = malloc(zsize);
    if (!in) {
        return NULL;
    }

    if (myread(fd, in, zsize) != 0) {
        free(in);
        return NULL;
    }

    if(ctx) {
        uif_crypt(ctx, in, zsize);
    }
    
    data = malloc(unzsize);
    if (!data) {
        free(in);
        return NULL;
    }

    if (unzip(z, in, zsize, (void *)data, unzsize) == -1) {
        free(data);
        free(in);
        return NULL;
    }

    free(in);

    return(data);
}

void l2n_blhr(blhr_t *p) {
    if(!endian) return;
    l2n_32(&p->sign);
    l2n_32(&p->size);
    l2n_32(&p->ver);
    l2n_32(&p->num);
}



void l2n_blhr_data(blhr_data_t *p) {
    if(!endian) return;
    l2n_64(&p->offset);
    l2n_32(&p->zsize);
    l2n_32(&p->sector);
    l2n_32(&p->size);
    l2n_32(&p->type);
}



void l2n_bbis(bbis_t *p) {
    if(!endian) return;
    l2n_32(&p->sign);
    l2n_32(&p->bbis_size);
    l2n_16(&p->ver);
    l2n_16(&p->image_type);
    l2n_16(&p->unknown1);
    l2n_16(&p->padding);
    l2n_32(&p->sectors);
    l2n_32(&p->sectorsz);
    l2n_32(&p->unknown2);
    l2n_64(&p->blhr);
    l2n_32(&p->blhrbbissz);
    l2n_32(&p->fixedkey);
    l2n_32(&p->unknown4);
}



void l2n_16(u16 *num) {
    u16     tmp;

    if(!endian) return;

    tmp = *num;
    *num = ((tmp & 0xff00) >> 8) |
           ((tmp & 0x00ff) << 8);
}



void l2n_32(u32 *num) {
    u32     tmp;

    if(!endian) return;

    tmp = *num;
    *num = ((tmp & 0xff000000) >> 24) |
           ((tmp & 0x00ff0000) >>  8) |
           ((tmp & 0x0000ff00) <<  8) |
           ((tmp & 0x000000ff) << 24);
}



void l2n_64(u64 *num) {
    u64     tmp;

    if(!endian) return;

    tmp = *num;
    *num = (u64)((u64)(tmp & (u64)0xff00000000000000ULL) >> (u64)56) |
           (u64)((u64)(tmp & (u64)0x00ff000000000000ULL) >> (u64)40) |
           (u64)((u64)(tmp & (u64)0x0000ff0000000000ULL) >> (u64)24) |
           (u64)((u64)(tmp & (u64)0x000000ff00000000ULL) >> (u64)8)  |
           (u64)((u64)(tmp & (u64)0x00000000ff000000ULL) << (u64)8)  |
           (u64)((u64)(tmp & (u64)0x0000000000ff0000ULL) << (u64)24) |
           (u64)((u64)(tmp & (u64)0x000000000000ff00ULL) << (u64)40) |
           (u64)((u64)(tmp & (u64)0x00000000000000ffULL) << (u64)56);
}



void b2n_16(u16 *num) {
    u16     tmp;

    if(endian) return;

    tmp = *num;
    *num = ((tmp & 0xff00) >> 8) |
           ((tmp & 0x00ff) << 8);
}



void b2n_32(u32 *num) {
    u32     tmp;

    if(endian) return;

    tmp = *num;
    *num = ((tmp & 0xff000000) >> 24) |
           ((tmp & 0x00ff0000) >>  8) |
           ((tmp & 0x0000ff00) <<  8) |
           ((tmp & 0x000000ff) << 24);
}



void b2n_64(u64 *num) {
    u64     tmp;

    if(endian) return;

    tmp = *num;
    *num = (u64)((u64)(tmp & (u64)0xff00000000000000ULL) >> (u64)56) |
           (u64)((u64)(tmp & (u64)0x00ff000000000000ULL) >> (u64)40) |
           (u64)((u64)(tmp & (u64)0x0000ff0000000000ULL) >> (u64)24) |
           (u64)((u64)(tmp & (u64)0x000000ff00000000ULL) >> (u64)8)  |
           (u64)((u64)(tmp & (u64)0x00000000ff000000ULL) << (u64)8)  |
           (u64)((u64)(tmp & (u64)0x0000000000ff0000ULL) << (u64)24) |
           (u64)((u64)(tmp & (u64)0x000000000000ff00ULL) << (u64)40) |
           (u64)((u64)(tmp & (u64)0x00000000000000ffULL) << (u64)56);
}

u8 *show_hash(u8 *hash) {
    int i;
    static u8 vis[33];
    static const char hex[16] = "0123456789abcdef";
    u8 *p;

    p = vis;
    for(i = 0; i < 16; i++) {
        *p++ = hex[hash[i] >> 4];
        *p++ = hex[hash[i] & 15];
    }
    *p = 0;

    return(vis);
}

void uif_crypt_key(char *key, char *pwd) {
    i64 *k, a, b;
    int i;

    strncpy(key, pwd, 32);
    k = (i64 *)key;

    for(i = 1; i < 4; i++) {
        if(!endian) {   // this solution is required for little/big endian compatibility and speed
            k[0] += k[i];
            continue;
        }
        a = k[0];
        b = k[i];
        l2n_64((u64*)&a);
        l2n_64((u64*)&b);
        a += b;
        l2n_64((u64*)&a);
        k[0] = a;
    }
}



void uif_crypt(DES_key_schedule *ctx, u8 *data, int size) {
    u8 *p, *l;

    if(!ctx) return;

    l = data + size - (size & 7);

    for(p = data; p < l; p += 8) {
        DES_ecb_encrypt((void *)p, (void *)p, ctx, DES_DECRYPT);
    }
}

