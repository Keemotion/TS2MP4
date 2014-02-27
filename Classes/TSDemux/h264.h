/*
 *			tsDemux is a MPEG2-TS to Elementary Stream demuxer
 *
 *			Authors: Anton Burdinuk
 *			Copyright (C) 2009 Anton Burdinuk (clark15b@gmail.com)
 *					All rights reserved
 *
 *
 *  tsDemux is a free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  tsDemux is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Foobar. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#ifndef __H264_H
#define __H264_H

#include "common.h"

namespace h264
{
    class counter
    {
    private:
        u_int32_t ctx;
        u_int64_t frame_num;                            // JVT NAL (h.264) frame counter
    public:
        counter(void):ctx(0),frame_num(0) {}

        void parse(const char* p,int l)
        {
            for(int i=0;i<l;i++)
            {
                ctx=(ctx<<8)+((unsigned char*)p)[i];
                    if((ctx&0xffffff1f)==0x00000109)    // NAL access unit
                        frame_num++;
            }
        }

        u_int64_t get_frame_num(void) const { return frame_num; }

        void reset(void)
        {
            ctx=0;
            frame_num=0;
        }
    };
}

#endif
