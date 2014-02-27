
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

#import <XCTest/XCTest.h>
#import "KMMediaFormat.h"
#import "KMMediaAsset.h"
#import "KMMediaAssetExportSession.h"
#import "NSRunLoop+waitUntil.h"


/*
 The result of tests below evaluate the behavior of the export session.
 */

static NSTimeInterval timeout = 60;

@interface BehaviorTests : XCTestCase
@end

@implementation BehaviorTests

- (void)testExportSessionValidity
{
    KMMediaAsset *tsAsset1 = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"ts"] withFormat:KMMediaFormatTS];
    KMMediaAsset *tsAsset2 = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"ts"] withFormat:KMMediaFormatTS];
    KMMediaAsset *tsAsset3 = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"ts"] withFormat:KMMediaFormatTS];
    
    KMMediaAsset *aacAsset = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"aac"] withFormat:KMMediaFormatAAC];
    
    KMMediaAsset *mp3Asset = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"mp3"] withFormat:KMMediaFormatMP3];
    
    KMMediaAsset *h264Asset = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"h264"] withFormat:KMMediaFormatH264];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:[NSURL URLWithString:@"mp4"] withFormat:KMMediaFormatMP4];
    
    
    /* Valid export sessions */
    
    KMMediaAssetExportSession *tsToMP4 = [[KMMediaAssetExportSession alloc]initWithInputAssets:@[tsAsset1,tsAsset2,tsAsset3]];
    tsToMP4.outputAssets = @[mp4Asset];
    XCTAssertTrue([tsToMP4 isAValidExportSession],@"This session must be valid");
    
    KMMediaAssetExportSession *tsToH264AndAAC = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset1,tsAsset2,tsAsset3]];
    tsToH264AndAAC.outputAssets = @[aacAsset,h264Asset];
    XCTAssertFalse([tsToH264AndAAC isAValidExportSession],@"This session must not be valid");
    
    KMMediaAssetExportSession *tsToH264AndMP3 = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset1,tsAsset2,tsAsset3]];
    tsToH264AndAAC.outputAssets = @[mp3Asset,h264Asset];
    XCTAssertFalse([tsToH264AndMP3 isAValidExportSession],@"This session must not be valid");
    
    KMMediaAssetExportSession *h264AndAACToMP4 = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[h264Asset,aacAsset]];
    tsToH264AndAAC.outputAssets = @[mp4Asset];
    XCTAssertFalse([h264AndAACToMP4 isAValidExportSession],@"This session must not be valid %@",h264AndAACToMP4.error);
    
    KMMediaAssetExportSession *h264AndMP3ToMP4 = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[h264Asset,mp3Asset]];
    tsToH264AndAAC.outputAssets = @[mp4Asset];
    XCTAssertFalse([h264AndMP3ToMP4 isAValidExportSession],@"This session must not be valid");
}


- (void)testConversionSingleTStoMP4
{
    NSURL* tsFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous1.ts"]];
    KMMediaAsset *tsAsset = [KMMediaAsset assetWithURL:tsFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:tsFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have fail");
}


- (void)testNoInputAssetProvided
{
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:nil];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must not exist after export session with no input asset");
        XCTAssertNotNil(tsToMP4ExportSession.error, @"An error must occur while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed, @"The export session must have fail");
}


- (void)testEmptyInputAssetProvided
{
    NSURL* emptyTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/emptyfile.ts"]];
    KMMediaAsset *emptyTSAsset = [KMMediaAsset assetWithURL:emptyTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:emptyTSFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[emptyTSAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must not exist after export session with no input asset");
        XCTAssertNotNil(tsToMP4ExportSession.error, @"An error must occur while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed, @"The export session must have fail");
}


- (void)testInputAssetIsNotATS
{
    NSURL* txtAsTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/txtFileRenamedAsTS.ts"]];
    KMMediaAsset *txtAsTSAsset = [KMMediaAsset assetWithURL:txtAsTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:txtAsTSFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[txtAsTSAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must not exist after export session with no input asset");
        XCTAssertNotNil(tsToMP4ExportSession.error, @"An error must occur while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed, @"The export session must have fail");
}


- (void)testNoOutputAssetProvided
{
    NSURL* txtAsTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Discontinuous2.ts"]];
    KMMediaAsset *txtAsTSAsset = [KMMediaAsset assetWithURL:txtAsTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:txtAsTSFileURL.path], @"The input file must exist");
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[txtAsTSAsset]];
    XCTAssertNil(tsToMP4ExportSession.outputAssets, @"Output asset must be nil for this test");
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertNotNil(tsToMP4ExportSession.error, @"An error must occur while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusFailed, @"The export session must have fail");
}


- (void)testOutputAssetAlreadyExist
{
    NSURL* tsFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous1.ts"]];
    KMMediaAsset *tsAsset = [KMMediaAsset assetWithURL:tsFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:tsFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have succeed");
    
    NSError *error;
    NSDictionary *mp4FileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[mp4Asset.url path] error:&error];
    XCTAssertNil(error, @"Error must not occur when retrieving mp4 file infos");
    NSNumber *firstExportMP4FileSize = mp4FileAttributes[NSFileSize];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have succeed");
    
    mp4FileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[mp4Asset.url path] error:&error];
    XCTAssertNil(error, @"Error must not occur when retrieving mp4 file infos");
    NSLog(@"%@ = %@", firstExportMP4FileSize, mp4FileAttributes[NSFileSize]);
    XCTAssertTrue([firstExportMP4FileSize isEqualToNumber:mp4FileAttributes[NSFileSize]], @"The file size must be the same since the export session override output file");
}


@end
