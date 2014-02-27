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
#ifndef __COMMON_H
#define __COMMON_H

#ifdef _WIN32
#include <windows.h>
#endif

#include <sys/types.h>
#include <stdio.h>
#include <map>
#include <string>
#include <list>
#include <memory.h>
#include <stdlib.h>
#ifndef _WIN32
#include <dirent.h>
#include <getopt.h>
#include <unistd.h>
#else
#include <io.h>
#include <fcntl.h>
#include "getopt.h"
#endif
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <memory>
#include <vector>
#include <fcntl.h>
#include <stdarg.h>


#ifndef _WIN32
#define O_BINARY 0
#else
typedef unsigned char u_int8_t;
typedef unsigned short u_int16_t;
typedef unsigned long u_int32_t;
typedef unsigned long long u_int64_t;
#endif

#ifndef O_LARGEFILE
#define O_LARGEFILE 0
#endif

#ifndef _WIN32
#define os_slash        '/'
#else
#define os_slash        '\\'
#endif


#endif
