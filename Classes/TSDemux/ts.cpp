/*
 *			tsDemux is a MPEG2-TS to Elementary Stream demuxer
 *
 *			Authors: Anton Burdinuk
 *          Edited by: Jonathan Gailliez
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


#include "ts.h"
#include <errno.h>

// TODO: join TS

// 1) M2TS timecode (0-1073741823)
/*
 The extra 4-byte header is composed of two fields. The upper 2 bits are the copy_permission_indicator and the lower 30 bits are the arrival_time_stamp. The arrival_time_stamp is equal to the lower 30 bits of the 27 MHz STC at the 0x47 byte of the Transport packet. In a packet that contains a PCR, the PCR will be a few ticks later than the arrival_time_stamp. The exact difference between the arrival_time_stamp and the PCR (and the number of bits between them) indicates the intended fixed bitrate of the variable rate Transport Stream.
 
 The primary function is to allow the variable rate Transport Stream to be converted to a fixed rate stream before decoding (since only fixed rate Transport Streams fit into the T-STD buffering model).
 
 It doesn't really help for random access. 30 bits at 27 MHz only represents 39.77 seconds.
 */

// 2) TS Continuity counter (0-15..0-15..)
// 3) PES PTS/DTS

namespace ts
{
    void get_prefix_name_by_filename(const std::string& s,std::string& name);
#ifdef _WIN32
    void my_strptime(const char* s,tm* t);
#endif
}

ts::stream::~stream(void)
{
    if(timecodes)
        fclose(timecodes);
}


void ts::get_prefix_name_by_filename(const std::string& s,std::string& name)
{
    int ll=s.length();
    const char* p=s.c_str();
    
    while(ll>0)
    {
        if(p[ll-1]=='/' || p[ll-1]=='\\')
            break;
        ll--;
    }
    
    p+=ll;
    
    const char* pp=strchr(p,'.');
    
    if(pp)
        name.assign(p,pp-p);
}


ts::file::~file(void)
{
    close();
}

bool ts::file::open(int mode,const char* fmt,...)
{
    filename.clear();
    
    char name[512];
    
    va_list ap;
    va_start(ap,fmt);
    vsprintf(name,fmt,ap);
    va_end(ap);
    
    int flags=0;
    
    switch(mode)
    {
        case in:
            flags=O_LARGEFILE|O_BINARY|O_RDONLY;
            break;
        case out:
            flags=O_CREAT|O_TRUNC|O_LARGEFILE|O_BINARY|O_WRONLY;
            break;
    }
    
    fd=::open(name,flags,0644);
    
    if(fd!=-1)
    {
        filename=name;
        len=offset=0;
        return true;
    }
#ifdef VERBOSE
    fprintf(stderr,"can`t open file %s %s\n",name,strerror(errno));
#endif
    return false;
}


void ts::file::close(void)
{
    if(fd!=-1)
    {
        flush();
        ::close(fd);
        fd=-1;
    }
    len=0;
    offset=0;
}

int ts::file::flush(void)
{
    int l=0;
    
    while(l<len)
    {
        int n=::write(fd,buf+l,len-l);
        if(!n || n==-1)
            break;
        l+=n;
    }
    
    len=0;
    
    return l;
}

int ts::file::write(const char* p,int l)
{
    int rc=l;
    
    while(l>0)
    {
        if(len>=max_buf_len)
            flush();
        
        int n=max_buf_len-len;
        
        if(n>l)
            n=l;
        
        memcpy(buf+len,p,n);
        len+=n;
        
        p+=n;
        l-=n;
    }
    
    return rc;
}
int ts::file::read(char* p,int l)
{
    const char* tmp=p;
    
    while(l>0)
    {
        int n=len-offset;
        
        if(n>0)
        {
            if(n>l)
                n=l;
            
            memcpy(p,buf+offset,n);
            p+=n;
            offset+=n;
            l-=n;
        }else
        {
            int m=::read(fd,buf,max_buf_len);
            if(m==-1 || !m)
                break;
            len=m;
            offset=0;
        }
    }
    
    return p-tmp;
}


bool ts::demuxer::validate_type(u_int8_t type)
{
    if(av_only)
        return strchr("\x01\x02\x80\x1b\xea\x81\x06\x83\x03\x04\x82\x86\x8a",type)?true:false;
    
    return true;
}

int ts::demuxer::get_stream_type(u_int8_t type)
{
    switch(type)
    {
        case 0x01:
        case 0x02:
            return stream_type::mpeg2_video;
        case 0x80:
            return hdmv?stream_type::lpcm_audio:stream_type::mpeg2_video;
        case 0x1b:
            return stream_type::h264_video;
        case 0xea:
            return stream_type::vc1_video;
        case 0x81:
        case 0x06:
        case 0x83:
            return stream_type::ac3_audio;
        case 0x03:
        case 0x04:
            return stream_type::mpeg2_audio;
        case 0x82:
        case 0x86:
        case 0x8a:
            return stream_type::dts_audio;
    }
    return stream_type::data;
}

bool ts::demuxer::is_video_stream_type(u_int8_t type)
{
    switch(type)
    {
        case 0x01:
        case 0x02:
        case 0x1b:
        case 0xea:
            return true;
        case 0x80:
            return hdmv?false : true;
        case 0x81:
        case 0x06:
        case 0x83:
        case 0x03:
        case 0x04:
        case 0x82:
        case 0x86:
        case 0x8a:
        default:
            return false;
    }
}

const char* ts::demuxer::get_stream_ext(u_int8_t type_id)
{
    static const char* list[8]= { "aac", "m2v", "264", "vc1", "ac3", "mp3", "pcm", "dts" };
    
    if(type_id<0 || type_id>=8)
        type_id=0;
    
    return list[type_id];
}

u_int64_t ts::demuxer::decode_pts(const char* ptr)
{
    const unsigned char* p=(const unsigned char*)ptr;
    
    u_int64_t pts=((p[0]&0xe)<<29);
    pts|=((p[1]&0xff)<<22);
    pts|=((p[2]&0xfe)<<14);
    pts|=((p[3]&0xff)<<7);
    pts|=((p[4]&0xfe)>>1);
    
    return pts;
}

double ts::demuxer::compute_fps_from_frame_length(u_int32_t frame_length)
{
    return 90000./(double)frame_length;
}

int ts::demuxer::demux_ts_packet(const char* ptr, double* video_fps)
{
    u_int32_t timecode=0;
    if(hdmv)
    {
        timecode=to_int32(ptr)&0x3fffffff;
        ptr+=4;
    }
    
    const char* end_ptr=ptr+188;
    
    if(ptr[0]!=0x47)            // ts sync byte
        return -1;
    
    u_int16_t pid=to_int(ptr+1);
    u_int8_t flags=to_byte(ptr+3);
    
    bool transport_error=pid&0x8000;
    bool payload_unit_start_indicator=pid&0x4000;
    bool adaptation_field_exist=flags&0x20;
    bool payload_data_exist=flags&0x10;
    u_int8_t continuity_counter=flags&0x0f;
    pid&=0x1fff;
    
    if(transport_error)
        return -2;
    
    if(pid==0x1fff || !payload_data_exist)
        return 0;
    
    ptr+=4;
    
    // skip adaptation field
    if(adaptation_field_exist)
    {
        ptr+=to_byte(ptr)+1;
        if(ptr>=end_ptr)
            return -3;
    }
#ifdef VERBOSE
    if(dump==1)
        printf("%.4x: [%c%c%c%c] %u.%i\n",
               pid,
               transport_error?'e':'-',
               payload_data_exist?'p':'-',
               payload_unit_start_indicator?'s':'-',
               adaptation_field_exist?'a':'-',
               timecode,
               continuity_counter
               );
#endif
    
    
    stream& s=streams[pid];
    
    if(!pid || (s.channel!=0xffff && s.type==0xff))
    {
        // PSI
        
        if(payload_unit_start_indicator)
        {
            // begin of PSI table
            
            ptr++;
            
            if(ptr>=end_ptr)
                return -4;
            
            if(*ptr!=0x00 && *ptr!=0x02)
                return 0;
            
            if(end_ptr-ptr<3)
                return -5;
            
            u_int16_t l=to_int(ptr+1);
            
            if((l&0x3000)!=0x3000)
                return -6;
            
            l&=0x0fff;
            
            ptr+=3;
            
            int len=end_ptr-ptr;
            
            if(l>len)
            {
                if(l>ts::table::max_buf_len)
                    return -7;
                
                s.psi.reset();
                
                memcpy(s.psi.buf,ptr,len);
                s.psi.offset+=len;
                s.psi.len=l;
                
                return 0;
            }else
                end_ptr=ptr+l;
        }else
        {
            // next part of PSI
            if(!s.psi.offset)
                return -8;
            
            int len=end_ptr-ptr;
            
            if(len>ts::table::max_buf_len-s.psi.offset)
                return -9;
            
            memcpy(s.psi.buf+s.psi.offset,ptr,len);
            s.psi.offset+=len;
            
            if(s.psi.offset<s.psi.len)
                return 0;
            else
            {
                ptr=s.psi.buf;
                end_ptr=ptr+s.psi.len;
            }
        }
        
        if(!pid)
        {
            // PAT
            
            ptr+=5;
            
            if(ptr>=end_ptr)
                return -10;
            
            int len=end_ptr-ptr-4;
            
            if(len<0 || len%4)
                return -11;
            
            int n=len/4;
            
            for(int i=0;i<n;i++,ptr+=4)
            {
                u_int16_t channel=to_int(ptr);
                u_int16_t pid=to_int(ptr+2);
                
                if((pid&0xe000)!=0xe000)
                    return -12;
                
                pid&=0x1fff;
                
                if(!demuxer::channel || demuxer::channel==channel)
                {
                    stream& ss=streams[pid];
                    ss.channel=channel;
                    ss.type=0xff;
                }
            }
        }else
        {
            // PMT
            
            ptr+=7;
            
            if(ptr>=end_ptr)
                return -13;
            
            u_int16_t info_len=to_int(ptr)&0x0fff;
            
            ptr+=info_len+2;
            end_ptr-=4;
            
            if(ptr>=end_ptr)
                return -14;
            
            while(ptr<end_ptr)
            {
                if(end_ptr-ptr<5)
                    return -15;
                
                u_int8_t type=to_byte(ptr);
                u_int16_t pid=to_int(ptr+1);
                
                if((pid&0xe000)!=0xe000)
                    return -16;
                
                pid&=0x1fff;
                
                info_len=to_int(ptr+3)&0x0fff;
                
                ptr+=5+info_len;
                
                // ignore unknown streams
                if(validate_type(type))
                {
                    stream& ss=streams[pid];
                    
                    if(ss.channel!=s.channel || ss.type!=type)
                    {
                        ss.channel=s.channel;
                        ss.type=type;
                        ss.id=++s.id;
                        
                        if(!parse_only && !ss.file.is_opened())
                        {
                            if(dst.length())
                            {
                                ss.file.open(file::out,"%s%c%s%s",dst.c_str(),os_slash,prefix.c_str(),get_stream_ext(get_stream_type(ss.type)));
                                fprintf(stderr,"%s%c%s%s\n",dst.c_str(),os_slash,prefix.c_str(),get_stream_ext(get_stream_type(ss.type)));
                            }
                            
                            
                            else
                                ss.file.open(file::out,"%s%s",prefix.c_str(),get_stream_ext(get_stream_type(ss.type)));
                        }
                    }
                }
            }
            
            if(ptr!=end_ptr)
                return -18;
        }
    }else
    {
        if(s.type!=0xff)
        {
            // PES
            
            if(payload_unit_start_indicator)
            {
                s.psi.reset();
                s.psi.len=9;
            }
            
            while(s.psi.offset<s.psi.len)
            {
                int len=end_ptr-ptr;
                
                if(len<=0)
                    return 0;
                
                int n=s.psi.len-s.psi.offset;
                
                if(len>n)
                    len=n;
                
                memcpy(s.psi.buf+s.psi.offset,ptr,len);
                s.psi.offset+=len;
                
                ptr+=len;
                
                if(s.psi.len==9)
                    s.psi.len+=to_byte(s.psi.buf+8);
            }
            
            if(s.psi.len)
            {
                if(memcmp(s.psi.buf,"\x00\x00\x01",3))
                    return -19;
                
                s.stream_id=to_byte(s.psi.buf+3);
                
                u_int8_t flags=to_byte(s.psi.buf+7);
                
                s.frame_num++;
                
                switch(flags&0xc0)
                {
                    case 0x80:          // PTS only
                    {
                        u_int64_t pts=decode_pts(s.psi.buf+9);
#ifdef VERBOSE
                        if(dump==2)
                            printf("%.4x: %llu\n",pid,pts);
                        else if(dump==3)
                            printf("%.4x: track=%.4x.%.2i, type=%.2x, stream=%.2x, pts=%llums\n",pid,s.channel,s.id,s.type,s.stream_id,pts/90);
#endif
                        if(s.dts>0 && pts>s.dts)
                        {
                            s.frame_length=(u_int32_t)(pts-s.dts);
                            
                            if(is_video_stream_type(s.type))
                            {
                                *video_fps = compute_fps_from_frame_length(s.frame_length);
                            }
                        }
                        s.dts=pts;
                        
                        if(pts>s.last_pts)
                            s.last_pts=pts;
                        
                        if(!s.first_pts)
                            s.first_pts=pts;
                    }
                        break;
                    case 0xc0:          // PTS,DTS
                    {
                        u_int64_t pts=decode_pts(s.psi.buf+9);
                        u_int64_t dts=decode_pts(s.psi.buf+14);
#ifdef VERBOSE
                        if(dump==2)
                            printf("%.4x: %llu %llu\n",pid,pts,dts);
                        else if(dump==3)
                            printf("%.4x: track=%.4x.%.2i, type=%.2x, stream=%.2x, pts=%llums, dts=%llums\n",pid,s.channel,s.id,s.type,s.stream_id,pts/90,dts/90);
#endif
                        if(s.dts>0 && dts>s.dts)
                        {
                            s.frame_length=(u_int32_t)(dts-s.dts);
                            
                            if(is_video_stream_type(s.type))
                            {
                                *video_fps = compute_fps_from_frame_length(s.frame_length);
                            }
                        }
                        
                        s.dts=dts;
                        
                        if(pts>s.last_pts)
                            s.last_pts=pts;
                        
                        if(!s.first_dts)
                            s.first_dts=dts;
                    }
                        break;
                }
                
                if(pes_output && s.file.is_opened())
                    s.file.write(s.psi.buf,s.psi.len);
                
                s.psi.reset();
            }
            
            if(s.frame_num)
            {
                int len=end_ptr-ptr;
                
                if(es_parse)
                {
                    switch(s.type)
                    {
                        case 0x1b:
                            s.frame_num_h264.parse(ptr,len);
                            break;
                        case 0x06:
                        case 0x81:
                        case 0x83:
                            s.frame_num_ac3.parse(ptr,len);
                            break;
                    }
                }
                
                if(s.file.is_opened())
                    s.file.write(ptr,len);
            }
        }
    }
    
    return 0;
}

void ts::demuxer::show(void)
{
    u_int64_t beg_pts=0,end_pts=0;
    
    for(std::map<u_int16_t,ts::stream>::const_iterator i=streams.begin();i!=streams.end();++i)
    {
        const ts::stream& s=i->second;
        
        if(s.type!=0xff)
        {
            if(s.first_pts<beg_pts || !beg_pts)
                beg_pts=s.first_pts;
            
            u_int64_t n=s.last_pts+s.frame_length;
            if(n>end_pts || !end_pts)
                end_pts=n;
        }
    }
    
    for(std::map<u_int16_t,ts::stream>::const_iterator i=streams.begin();i!=streams.end();++i)
    {
        u_int16_t pid=i->first;
        const ts::stream& s=i->second;
        
        if(s.type!=0xff)
        {
            u_int64_t end=s.last_pts+s.frame_length;
            u_int64_t len=end-s.first_pts;
            
            fprintf(stderr,"pid=%i (0x%.4x), ch=%i, id=%.i, type=0x%.2x (%s), stream=0x%.2x",
                    pid,pid,s.channel,s.id,s.type,get_stream_ext(get_stream_type(s.type)),s.stream_id);
            
            if(s.frame_length>0)
                fprintf(stderr,", fps=%.2f",90000./(double)s.frame_length);
            
            if(len>0)
                fprintf(stderr,", len=%llums",len/90);
            
            
            if(s.frame_num>0)
                fprintf(stderr,", fn=%llu",s.frame_num);
            
            u_int64_t esfn=s.get_es_frame_num();
            
            if(esfn>0)
                fprintf(stderr,", esfn=%llu",esfn);
            
            if(s.first_pts>beg_pts)
            {
                u_int32_t n=(u_int32_t)(s.first_pts-beg_pts)/90;
                
                fprintf(stderr,", head=+%ums",n);
            }
            
            if(end<end_pts)
            {
                u_int32_t n=(u_int32_t)(end_pts-end)/90;
                
                fprintf(stderr,", tail=-%ums",n);
            }
            
            fprintf(stderr,"\n");
        }
    }
}

int ts::demuxer::demux_file(const char* name, double* video_fps)
{
//    prefix.clear();
    
    char buf[192];
    
    int buf_len=0;
    
    ts::file file;
    
    if(!file.open(file::in,"%s",name))
    {
#ifdef VERBOSE
        fprintf(stderr,"can`t open file %s\n",name);
#endif
        return -1;
    }
    
    if(prefix.length()==0) get_prefix_name_by_filename(name,prefix);
    if(prefix.length())
        prefix+='.';
    
    for(u_int64_t pn=1;;pn++)
    {
        if(buf_len)
        {
            if(file.read(buf,buf_len)!=buf_len)
                break;
        }else
        {
            if(file.read(buf,188)!=188)
                break;
            if(buf[0]==0x47 && buf[4]!=0x47)
            {
                buf_len=188;
#ifdef VERBOSE
                fprintf(stderr,"TS stream detected in %s (packet length=%i)\n",name,buf_len);
#endif
                hdmv=false;
            }else if(buf[0]!=0x47 && buf[4]==0x47)
            {
                if(file.read(buf+188,4)!=4)
                    break;
                buf_len=192;
#ifdef VERBOSE
                fprintf(stderr,"M2TS stream detected in %s (packet length=%i)\n",name,buf_len);
#endif
                hdmv=true;
            }else
            {
#ifdef VERBOSE
                fprintf(stderr,"unknown stream type in %s\n",name);
#endif
                return -1;
            }
        }
        
        int n;
        if((n=demux_ts_packet(buf, video_fps)))
        {
#ifdef VERBOSE
            fprintf(stderr,"%s: invalid packet %llu (%i)\n",name,pn,n);
#endif
            return -1;
        }
    }
    
    return 0;
}

#ifdef _WIN32
void ts::my_strptime(const char* s,tm* t)
{
    memset((char*)t,0,sizeof(tm));
    sscanf(s,"%d-%d-%d %d:%d:%d",&t->tm_year,&t->tm_mon,&t->tm_mday,&t->tm_hour,&t->tm_min,&t->tm_sec);
    t->tm_year-=1900;
    t->tm_mon-=1;
    t->tm_isdst=1;
}
#endif


void ts::demuxer::write_timecodes(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len)
{
    u_int64_t len=last_pts-first_pts;
    
    double c=(double)len/(double)frame_num;
    
    double m=0;
    u_int32_t n=0;
    
    for(int i=0;i<frame_num;i++)
    {
        fprintf(fp,"%llu\n",(first_pts+n)/90);
        
        m+=c;
        n+=c;
        
        if(m-n>=1)
            n+=1;
    }
}

#ifndef OLD_TIMECODES
// for audio
void ts::demuxer::write_timecodes2(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len)
{
    u_int64_t len=last_pts-first_pts;
    
    u_int64_t len2=frame_num*frame_len;
    
    if(len2>len || frame_len%90)
        write_timecodes(fp,first_pts,last_pts,frame_num,frame_len);
    else
    {
        u_int32_t frame_len_ms=frame_len/90;
        u_int32_t timecode_ms=(u_int32_t)base_pts/90;
        
        for(u_int32_t i=0;i<frame_num;i++)
        {
            fprintf(fp,"%u\n",timecode_ms);
            timecode_ms+=frame_len_ms;
        }
    }
}
#endif
