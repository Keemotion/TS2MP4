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


#import "KMMediaAssetExportSession.h"

/* MP4Mux */
#import "mp4mux.h"

/* TSDemux */
#import "ts.h"

/* Wrapper */
#import "KMMediaFormat.h"

/* Utils */
#import "NSFileManager+Temporary.h"


typedef NS_ENUM(NSUInteger, KMMediaAssetExportSessionInputType) {
    KMMediaAssetExportSessionInputTypeTS,
    KMMediaAssetExportSessionInputTypeUndefined
};

typedef NS_ENUM(NSUInteger, KMMediaAssetExportSessionOutputType) {
    KMMediaAssetExportSessionOutputTypeMP4,
    KMMediaAssetExportSessionOutputTypeUndefined
};


@interface KMMediaAssetExportSession ()
@property (nonatomic, readwrite) KMMediaAssetExportSessionStatus status;
@property (nonatomic, readwrite) float progress;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong) NSArray *inputAssets;
@property (nonatomic) KMMediaAssetExportSessionInputType inputType;
@property (nonatomic) KMMediaAssetExportSessionOutputType outputType;
@end

@implementation KMMediaAssetExportSession

- (id)initWithInputAssets:(NSArray *)inputAssets
{
    self = [super init];
    if(self)
    {
        _inputAssets = inputAssets;
        _inputType = KMMediaAssetExportSessionInputTypeUndefined;
    }
    return self;
}

- (BOOL)isAValidExportSession
{

    /* Check input validity */
    if([[self.inputAssets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"format=%d",KMMediaFormatTS]] count] == [self.inputAssets count]) self.inputType = KMMediaAssetExportSessionInputTypeTS;
    else
    {
        self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeInvalidInput userInfo:@{NSLocalizedDescriptionKey:@"The input assets are invalid. The only valid input assets are KMMediaFormatTS."}];
        return NO;
    }
    
    /* Check output validity */
    if([self.outputAssets count] == 1 && [[self.outputAssets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"format=%d",KMMediaFormatMP4]] count] == 1) self.outputType = KMMediaAssetExportSessionOutputTypeMP4;
    else
    {
        self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeInvalidOutput userInfo:@{NSLocalizedDescriptionKey:@"The output assets are invalid. The only valid output asset is KMMediaFormatMP4."}];
        return NO;
    }
    
    /* Check operation validity */
    if(self.inputType == KMMediaAssetExportSessionInputTypeTS && self.outputType == KMMediaAssetExportSessionOutputTypeMP4) return YES;
    else
    {
        self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeUnsupportedOperation userInfo:@{NSLocalizedDescriptionKey:@"The operation is not supported. The only supported operation is KMMediaFormatTS -> KMMediaFormatMP4"}];
        return NO;
    }
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler
{
    self.status = KMMediaAssetExportSessionStatusWaiting;
    if(![self isAValidExportSession])
    {
        self.status = KMMediaAssetExportSessionStatusFailed;
        handler();
    }
    else
    {
        /*
         Execute the task on one of the four global concurrent queue
         with a background priority 
         */
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue, ^(void) {
            self.status = KMMediaAssetExportSessionStatusExporting;
            if(self.inputType == KMMediaAssetExportSessionInputTypeTS && self.outputType == KMMediaAssetExportSessionOutputTypeMP4) [self convertInputAssets];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                handler();
            });
        });
    }
}

- (void)convertInputAssets
{
    /*
     Create a unique temporary directory to store the elementary streams files.
     May be nil.
     */
    NSURL *temporaryDirectoryURL = [[NSFileManager defaultManager] createUniqueTemporaryDirectory];
    
    /*
     Demux the input assets into the unique temporary directory
     Create two files into it:
     - a file storing the audio elementary stream of the MPEG-TS files (mp3 or aac)
     - a file storing the video elementary stream of the MPEG-TS files (h264)
     */
    [self demuxFilesInTemporaryDirectory:temporaryDirectoryURL];
    
    /*
     Mux the elementary stream stored in as files in the unique temporary directory
     into a MP4 file and store it in the outputAsset
     */
    [self muxFilesFromTemporaryDirectory:temporaryDirectoryURL];
    
    /*
     Delete the temporary directory
     */
    NSError *error;
    if(![[NSFileManager defaultManager] removeItemAtPath:[temporaryDirectoryURL path]error:&error])
    {
        ALog(@"Cannot delete temporary directory. Will be deleted automatically later. Error:%@", error);
    }
}


- (void)demuxFilesInTemporaryDirectory:(NSURL *)outputDemuxDirectoryURL
{
    if(!outputDemuxDirectoryURL)
    {
        self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeDemuxOperationFailed userInfo:@{NSLocalizedDescriptionKey:@"Directory to store elementary streams files not set."}];
        self.status = KMMediaAssetExportSessionStatusFailed;
        return;
    }
    
    /*
     * Initialize the demuxer
     */
    ts::demuxer cpp_demuxer;
    cpp_demuxer.parse_only=false;
    cpp_demuxer.es_parse=false;
    cpp_demuxer.dump=0;
    cpp_demuxer.av_only=false;
    cpp_demuxer.channel=0;
    cpp_demuxer.pes_output=false;
    cpp_demuxer.prefix = [[[NSProcessInfo processInfo] globallyUniqueString] UTF8String];
    cpp_demuxer.dst = [[outputDemuxDirectoryURL path] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    
    /*
     * Demux each file with the same Demuxer will produce only two output files
     * The concatenate audio elementary streams file and
     * the concatenate video elementary streams file
     */
    for (KMMediaAsset *inputAsset in self.inputAssets)
    {
        cpp_demuxer.demux_file([[inputAsset.url path] UTF8String]);
    }
}


- (void)muxFilesFromTemporaryDirectory:(NSURL *)inputMuxDirectoryURL
{
    NSError *error;
    NSArray *inputMuxDirectoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[inputMuxDirectoryURL path] error:&error];
    
    if(!error)
    {
        /*
         Retrieve audio elementary stream file
         */
        NSArray *audioExtensions = [NSArray arrayWithObjects:@"aac", @"mp3", nil];
        NSArray *audioElementaryStreamFiles = [inputMuxDirectoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", audioExtensions]];
        
        if([audioElementaryStreamFiles count]>1)
        {
            self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeDemuxOperationFailed userInfo:@{NSLocalizedDescriptionKey:@"Cannot decide wich audio elementary streams in the directory since there are more than one."}];
            self.status = KMMediaAssetExportSessionStatusFailed;
            return;
        }
        
        NSString *audioElementaryStreamFileName = [audioElementaryStreamFiles firstObject];
        
        /*
         Retrieve video elementary stream file
         */
        NSArray *videoExtensions = [NSArray arrayWithObjects:@"264", nil];
        NSArray *videoElementaryStreamFiles = [inputMuxDirectoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", videoExtensions]];
        
        if([videoElementaryStreamFiles count]>1)
        {
            self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeDemuxOperationFailed userInfo:@{NSLocalizedDescriptionKey:@"Cannot decide wich video elementary streams in the directory since there are more than one."}];
            self.status = KMMediaAssetExportSessionStatusFailed;
            return;
        }
        
        NSString *videoElementaryStreamFileName = [videoElementaryStreamFiles firstObject];
        
        /*
         Assemble the elementary streams into a MP4 file
         */
        if(videoElementaryStreamFileName && audioElementaryStreamFileName)
        {
            KMMediaAsset *outputAsset = [self.outputAssets firstObject];

            double fps = 20.0;
            NSString *outputAudioElementaryStreamFilePath = [NSString stringWithFormat:@"%@/%@",[inputMuxDirectoryURL path],audioElementaryStreamFileName];
            NSString *outputVideoElementaryStreamFilePath = [NSString stringWithFormat:@"%@/%@",[inputMuxDirectoryURL path],videoElementaryStreamFileName];
            
            assemble_elementary_streams((char *)[outputVideoElementaryStreamFilePath UTF8String], (char *)[outputAudioElementaryStreamFilePath UTF8String], (char *)[[outputAsset.url path ] UTF8String], fps);
            
            self.status = KMMediaAssetExportSessionStatusCompleted;
        }
        else
        {
            self.error = [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeDemuxOperationFailed userInfo:@{NSLocalizedDescriptionKey:@"Missing audio elementary stream or video elementary stream while trying to mux it."}];
            self.status = KMMediaAssetExportSessionStatusFailed;
        }
    }
    else
    {
        self.error =  [NSError errorWithDomain:KMMediaAssetExportSessionErrorDomain code:KMMediaAssetExportSessionErrorCodeDemuxOperationFailed userInfo:error.userInfo];
        self.status = KMMediaAssetExportSessionStatusFailed;
    }
}

@end
