//
//  ViewController.m
//  ReverseClip
//
//  Created by Mikael Hellqvist on 2012-08-19.
//  Copyright (c) 2012 Mikael Hellqvist. All rights reserved.
//

#import "ViewController.h"

#import "RCToolbox.h"
#import "RCConstants.h"

#import <MediaPlayer/MediaPlayer.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "SVProgressHUD.h"

@interface ViewController ()
{
    MPMoviePlayerController *moviePlayer;
    Float64 endTime;
}
@property(nonatomic,retain)AVURLAsset* videoAsset;
@property(nonatomic,retain)AVURLAsset* audioAsset;
@property (weak, nonatomic) IBOutlet UIView *vwMoviePlayer;
- (void)exportDidFinish:(AVAssetExportSession*)session;

@end

@implementation ViewController

@synthesize videoAsset,audioAsset;
@synthesize vwMoviePlayer;

#pragma mark - UI
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [vwMoviePlayer setHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieIsExported)
                                                 name:@"ExportedMovieNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imageSequenceIsExported)
                                                 name:@"ExportedImageSequenceNotification"
                                               object:nil];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Button Actions

//Creating Video Reverse From Original Video
- (IBAction)startButtonPressed:(id)sender
{
    [SVProgressHUD showWithStatus:@"Creating Video Reverse" maskType:SVProgressHUDMaskTypeGradient];
    
    [self createReverseClip];
}

//Get Audio From Original Video
- (IBAction)getAudioFromVideoTapped:(id)sender
{
    [SVProgressHUD showWithStatus:@"Converting Audio From Original Video.." maskType:SVProgressHUDMaskTypeGradient];
    
    [self getAudioFromVideo];
}

//Merge Audio & Video Together & Play them
- (IBAction)btnMergeTapped:(id)sender
{
    [SVProgressHUD showWithStatus:@"Merge Audio & Video Together" maskType:SVProgressHUDMaskTypeGradient];
    [vwMoviePlayer setHidden:YES];
    [self performSelector:@selector(mergeAndSave) withObject:nil afterDelay:.6];
}

-(IBAction)loadOriginalVideo:(id)sender
{
    
    NSString *sourceMoviePath = [[NSBundle mainBundle] pathForResource:@"Video_AudioDemo" ofType:@"mp4"];
    NSURL *originalMovieURL = [NSURL fileURLWithPath:sourceMoviePath];
    
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:originalMovieURL];
    moviePlayer.view.hidden = NO;
    
    moviePlayer.view.frame = CGRectMake(0, 0, vwMoviePlayer.frame.size.width, vwMoviePlayer.frame.size.height);
    moviePlayer.view.backgroundColor = [UIColor clearColor];
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    
    moviePlayer.fullscreen = NO;
    [moviePlayer prepareToPlay];
    [moviePlayer readyForDisplay];
    [moviePlayer setControlStyle:MPMovieControlStyleDefault];
    
    moviePlayer.shouldAutoplay = NO;
    
    [vwMoviePlayer addSubview:moviePlayer.view];
    [vwMoviePlayer setHidden:NO];
}


#pragma mark - Other Method

-(void)mergeAndSave
{
    //Get path
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    //Create AVMutableComposition Object which will hold our multiple AVMutableCompositionTrack or we can say it will hold our video and audio files.
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //Now first load your audio file using AVURLAsset. Make sure you give the correct path of your videos.
    //This is Converted Audio frile from Original Video
    NSString *outputFilePath111 = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"FinalVideo.m4a"]];
    NSURL *audio_url = [NSURL fileURLWithPath:outputFilePath111];
    audioAsset = [[AVURLAsset alloc]initWithURL:audio_url options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    //Now we are creating the first AVMutableCompositionTrack containing our audio and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Now we will load video file.
    NSString *outputFilePath11 = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"imageSequence_reverse.mov"]];
    NSURL *video_url = [NSURL fileURLWithPath:outputFilePath11];
    videoAsset = [[AVURLAsset alloc]initWithURL:video_url options:nil];
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,audioAsset.duration);
    
    //Now we are creating the second AVMutableCompositionTrack containing our video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //decide the path where you want to store the final video created with audio and video merge.
    NSString *outputFilePath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"FinalVideo.mov"]];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    //Now create an AVAssetExportSession object that will save your final video at specified path.
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = outputFileUrl;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         dispatch_async(dispatch_get_main_queue(), ^{
             [SVProgressHUD dismiss];
             [self exportDidFinish:_assetExport];
             
         });
     }
     ];
}
- (void)exportDidFinish:(AVAssetExportSession*)session
{
    if(session.status == AVAssetExportSessionStatusCompleted){
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL
                                        completionBlock:^(NSURL *assetURL, NSError *error){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                if (error) {
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
                                                    [alert show];
                                                }else{
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"  delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                                                    [alert show];
                                                    [self loadMoviePlayer:outputURL];
                                                }
                                            });
                                        }];
        }
    }
    audioAsset = nil;
    videoAsset = nil;
}

-(void)loadMoviePlayer:(NSURL*)moviePath
{
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:moviePath];
    moviePlayer.view.hidden = NO;
    
    moviePlayer.view.frame = CGRectMake(0, 0, vwMoviePlayer.frame.size.width, vwMoviePlayer.frame.size.height);
    moviePlayer.view.backgroundColor = [UIColor clearColor];
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    
    moviePlayer.fullscreen = NO;
    [moviePlayer prepareToPlay];
    [moviePlayer readyForDisplay];
    [moviePlayer setControlStyle:MPMovieControlStyleDefault];
    
    moviePlayer.shouldAutoplay = NO;
    
    [vwMoviePlayer addSubview:moviePlayer.view];
    [vwMoviePlayer setHidden:NO];
}

-(void)getAudioFromVideo {
    float startTime = 0;
    [super viewDidLoad];
    
    
    //Getting Converted Audio File Path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *audioPath = [documentsDirectory stringByAppendingPathComponent:@"FinalVideo.m4a"];
    
    //Here is Original Video File Path
    //Get Audio From Original Video
    AVAsset *myasset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"Video_AudioDemo" withExtension:@"mp4"]];
    
    AVAssetExportSession *exportSession=[AVAssetExportSession exportSessionWithAsset:myasset presetName:AVAssetExportPresetAppleM4A];
    
    exportSession.outputURL=[NSURL fileURLWithPath:audioPath];
    exportSession.outputFileType=AVFileTypeAppleM4A;
    
    CMTime vocalStartMarker = CMTimeMake((int)(floor(startTime * 100)), 100);
    CMTime vocalEndMarker = CMTimeMake((int)(ceil(endTime * 100)), 100);
    
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(vocalStartMarker, vocalEndMarker);
    exportSession.timeRange= exportTimeRange;
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
    }
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status==AVAssetExportSessionStatusFailed) {
            NSLog(@"failed");
        }
        else {
            [SVProgressHUD dismiss];
            NSLog(@"AudioLocation : %@",audioPath);
        }
    }];
}

#pragma mark - Reverse clip
-(void) createReverseClip
{
    RCFileHandler *filehandler = [[RCToolbox sharedToolbox] fileHandler];
    AVURLAsset *urlAsset = [filehandler getAssetURLFromBundleWithFileName:@"Video_AudioDemo"];
    [self exportReversedClip:urlAsset];
}

-(void) exportReversedClip:(AVURLAsset *)urlAsset
{
    Float64 assetDuration = CMTimeGetSeconds(urlAsset.duration);
    endTime=assetDuration;
    NSLog(@"-- %d",urlAsset.duration.timescale);
    RCComposer *compositionTool = [[RCToolbox sharedToolbox] compositionTool];
    [compositionTool addToCompositionWithAsset:(AVURLAsset*)urlAsset inSeconds:0.0 outSeconds:assetDuration shouldBeReversed:YES];
}

#pragma - Notifications
-(void)movieIsExported
{
    RCFileHandler *fileHandler = [[RCToolbox sharedToolbox] fileHandler];
    AVURLAsset *urlAsset = [fileHandler getAssetURLFromFileName:k_exportedClipName];
    NSLog(@"The movie has been exported. \n URLAsset:%@",urlAsset);
}

-(void)imageSequenceIsExported
{
    RCFileHandler *fileHandler = [[RCToolbox sharedToolbox] fileHandler];
    AVURLAsset *urlAsset = [fileHandler getAssetURLFromFileName:k_exportedSequenceName];
    NSLog(@"The image sequence has been exported. \n URLAsset:%@",urlAsset);
}

@end

