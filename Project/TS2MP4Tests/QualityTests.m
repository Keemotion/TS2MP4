
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
 The result of tests below are to be evaluated watching the MP4 file produced as an output of the export session.
 A succeeded test does not mean that the mp4 file produced is valid or of the expected quality.
 */

static NSTimeInterval timeout = 60;

@interface QualityTests : XCTestCase
@end

@implementation QualityTests


/*
 This test produce an mp4 file displaying the TS file concatenated without artefact nor discontinuity between the TS files
 */

- (void)testConversionMultipleContinuousTStoMP4
{
    NSURL* ts1FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous1.ts"]];
    KMMediaAsset *ts1Asset = [KMMediaAsset assetWithURL:ts1FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts1FileURL.path], @"The input file must exist");
    
    NSURL* ts2FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous2.ts"]];
    KMMediaAsset *ts2Asset = [KMMediaAsset assetWithURL:ts2FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts2FileURL.path], @"The input file must exist");
    
    NSURL* ts3FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous3.ts"]];
    KMMediaAsset *ts3Asset = [KMMediaAsset assetWithURL:ts3FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts3FileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[ts1Asset, ts2Asset, ts3Asset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have fail");
}


/*
 This test produce an mp4 file displaying the TS file concatenated without artefact but with discontinuity between the TS files
 */

- (void)testConversionMultipleDiscontinuousTStoMP4
{
    NSURL* ts1FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Discontinuous1.ts"]];
    KMMediaAsset *ts1Asset = [KMMediaAsset assetWithURL:ts1FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts1FileURL.path], @"The input file must exist");
    
    NSURL* ts2FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Discontinuous2.ts"]];
    KMMediaAsset *ts2Asset = [KMMediaAsset assetWithURL:ts2FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts2FileURL.path], @"The input file must exist");
    
    NSURL* ts3FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Discontinuous3.ts"]];
    KMMediaAsset *ts3Asset = [KMMediaAsset assetWithURL:ts3FileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:ts3FileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[ts1Asset, ts2Asset, ts3Asset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have fail");
}


/*
 This test produce a valid MP4 file but the video is messed up. The TS files must have the same resolution.
 */

- (void)testExportTwoTSAssetWithTwoDifferentResolutions
{
    NSURL* lowResTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/lowRes.ts"]];
    KMMediaAsset *lowResTSAsset = [KMMediaAsset assetWithURL:lowResTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:lowResTSFileURL.path], @"The input file must exist");
    
    NSURL* highResTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/highRes.ts"]];
    KMMediaAsset *highResTSAsset = [KMMediaAsset assetWithURL:highResTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:highResTSFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[lowResTSAsset,highResTSAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have succeed");
}


/*
 This test produce a valid MP4 file but the video is messed up. The TS files must have the same audio codec.
 */

- (void)testExportTwoTSAssetWithDifferentAudioCodecs
{
    NSURL* mp3TSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/mp3Audio.ts"]];
    KMMediaAsset *lowResTSAsset = [KMMediaAsset assetWithURL:mp3TSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp3TSFileURL.path], @"The input file must exist");
    
    NSURL* aacTSFileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:@"/Continuous1.ts"]];
    KMMediaAsset *highResTSAsset = [KMMediaAsset assetWithURL:aacTSFileURL withFormat:KMMediaFormatTS];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:aacTSFileURL.path], @"The input file must exist");
    
    NSURL *mp4FileURL = [NSURL fileURLWithPath:[[[NSBundle bundleForClass:[self class] ] resourcePath] stringByAppendingString:[NSString stringWithFormat:@"/%@Result.mp4",NSStringFromSelector(_cmd)]]];
    
    KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
    
    KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[lowResTSAsset,highResTSAsset]];
    tsToMP4ExportSession.outputAssets = @[mp4Asset];
    
    [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:mp4FileURL.path], @"The output file must exist after export session");
        XCTAssertNil(tsToMP4ExportSession.error, @"An error occured while converting the file.");
    }];
    
    [[NSRunLoop currentRunLoop] waitUntil:^BOOL{ return tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted; } orTimeout:timeout];
    XCTAssertTrue(tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted, @"The export session must have succeed");
}


@end
