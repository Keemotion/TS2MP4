
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

#import "KMExportViewController.h"
#import "KMMedia.h"

@interface KMExportViewController ()
@property (strong, nonatomic) IBOutlet UIButton *exportButton;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;
@end

@implementation KMExportViewController


- (IBAction)exportButtonPressed:(id)sender
{
    self.infoLabel.text = @"Exporting...";
    __block NSDate *beginDate = [NSDate date];
    NSError *error;
    NSString *resourceDirectoryPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] path];
    NSArray *resourceDirectoryPathContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourceDirectoryPath error:&error];
    
    if(!error)
    {
        NSArray *tsFileList = [resourceDirectoryPathContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ts'"]];
        __block NSUInteger tsFileCount = [tsFileList count];
        if (tsFileCount > 0)
        {
            NSMutableArray *tsAssetList = [NSMutableArray arrayWithCapacity:tsFileCount];
            for(NSString *tsFileName in tsFileList)
            {
                NSURL *tsFileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",resourceDirectoryPath, tsFileName]];
                [tsAssetList addObject:[KMMediaAsset assetWithURL:tsFileURL withFormat:KMMediaFormatTS]];
            }
            
            NSURL *mp4FileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Result.mp4",resourceDirectoryPath]];
            KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
            
            KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:tsAssetList];
            tsToMP4ExportSession.outputAssets = @[mp4Asset];
            
            [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
                if (tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted)
                {
                    unsigned int timeUnits = NSMinuteCalendarUnit | NSSecondCalendarUnit;
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *dateComponents = [calendar components:timeUnits fromDate:beginDate toDate:[NSDate date] options:0];
                    self.infoLabel.text = [NSString stringWithFormat:@"Export %d chunks completed in %d:%d",tsFileCount, [dateComponents minute], [dateComponents second]];
                }
                else
                {
                    self.infoLabel.text = [NSString stringWithFormat:@"Export %d chunks failed: %@",tsFileCount, tsToMP4ExportSession.error];
                }
            }];
        }
        else
        {
            self.infoLabel.text = [NSString stringWithFormat:@"No TS file found in: %@",resourceDirectoryPath];
        }
    }
    else
    {
        self.infoLabel.text = [NSString stringWithFormat:@"Cannot retrieve TS files: %@",error];
    }
}
- (IBAction)testMemoryLeaksPressed:(id)sender
{
    self.infoLabel.text = @"Exporting...";
    NSError *error;
    NSString *resourceDirectoryPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] path];
    NSArray *resourceDirectoryPathContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourceDirectoryPath error:&error];
    
    if(!error)
    {
        NSArray *tsFileList = [resourceDirectoryPathContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ts'"]];
        __block NSUInteger tsFileCount = [tsFileList count];
        if (tsFileCount > 0)
        {
            for(NSString *tsFileName in tsFileList)
            {
                NSURL *tsFileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",resourceDirectoryPath, tsFileName]];
                KMMediaAsset *tsAsset = [KMMediaAsset assetWithURL:tsFileURL withFormat:KMMediaFormatTS];
            
    
                NSURL *mp4FileURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@Result.mp4",resourceDirectoryPath, [tsFileName stringByDeletingPathExtension]]];
                KMMediaAsset *mp4Asset = [KMMediaAsset assetWithURL:mp4FileURL withFormat:KMMediaFormatMP4];
                
                KMMediaAssetExportSession *tsToMP4ExportSession = [[KMMediaAssetExportSession alloc] initWithInputAssets:@[tsAsset]];
                tsToMP4ExportSession.outputAssets = @[mp4Asset];
                
                [tsToMP4ExportSession exportAsynchronouslyWithCompletionHandler:^{
                    if (tsToMP4ExportSession.status == KMMediaAssetExportSessionStatusCompleted)
                    {
                        self.infoLabel.text = [NSString stringWithFormat:@"Export of %@ completed",tsFileName];
                    }
                    else
                    {
                        self.infoLabel.text = [NSString stringWithFormat:@"Export of %@ failed",tsFileName];
                    }
                }];
            }
        }
        else
        {
            self.infoLabel.text = [NSString stringWithFormat:@"No TS file found in: %@",resourceDirectoryPath];
        }
    }
    else
    {
        self.infoLabel.text = [NSString stringWithFormat:@"Cannot retrieve TS files: %@",error];
    }
}



@end
