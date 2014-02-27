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


#import <Foundation/Foundation.h>
#import "KMMediaFormat.h"

@interface KMMediaAsset : NSObject

@property (nonatomic, readonly) KMMediaFormat format;
@property (nonatomic, readonly, strong) NSURL *url;

/**
 Returns an instance of KMMediaAsset for inspection of a media resource.
 @param url An instance of NSURL that represent the path to the media file
 @param format The format in which the data in the file are stored
 @return An instance of KMMediaAsset.
 */

+ (id)assetWithURL:(NSURL *)url withFormat:(KMMediaFormat)format;


@end
