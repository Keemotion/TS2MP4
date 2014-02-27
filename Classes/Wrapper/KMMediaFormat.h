/*
 *			         TS2MP4 Pod
 *
 *			Authors: Gailliez Jonathan
 *                   Damien Leroy
 *			Copyright (c) Keemotion 2014
 *					All rights reserved
 *
 *  This file is part of TS2MP4 Pod.
 *
 *  TS2MP4 is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  TS2MP4 is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; see the file LICENCE.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */


#ifndef TS2MP4_KMMediaFormat_h
#define TS2MP4_KMMediaFormat_h

/* 
 Defined the format in which the media data are stored
 */
typedef NS_ENUM(NSInteger, KMMediaFormat) {
    KMMediaFormatUnknown,
    KMMediaFormatAAC,       /* Audio AAC format */
    KMMediaFormatMP3,       /* Audio MP3 format */
    KMMediaFormatH264,      /* Video H264 format */
    KMMediaFormatMP4,       /* Video MP4 format */
    KMMediaFormatTS         /* Video MPEG2-TS format */
};

#endif
