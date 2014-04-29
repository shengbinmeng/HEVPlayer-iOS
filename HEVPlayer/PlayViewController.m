//
//  PlayViewController.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "PlayViewController.h"
#import "GLView.h"

@implementation PlayViewController

{
    bool isPlaying;
    float lastFrameTime;
    BOOL overlayHidden;
    int flag;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) monitorPlaybackTime
{
    if (!isPlaying) {
        return;
    }
    
    double time = [self.player getMovieTimeInSeconds];
    double duration = [self.player getMovieDurationInSeconds];
    if (duration - time < 2) {
        [self doneButtonPressed:nil];
    }
    if (flag == -1) {
        // not open movie, so return
        return;
    }
    if (flag > 0) {
        // just seek, wait a while (3 seconds) for the correct time value
        flag --;
    } else {
        self.progressIndicator.value = time / (double)duration;
    }
    
    int hour, minute, second;
    hour = (int64_t) time / 3600;
    minute = ((int64_t)time % 3600) / 60;
    second = ((int64_t)time % 3600) % 60;
    [self.playingTimeLabel setText:[NSString stringWithFormat:@"%2.2d:%2.2d:%2.2d",hour, minute, second]];
    
    hour = (int64_t)(duration - time) / 3600;
    minute = ((int64_t)(duration - time) % 3600) / 60;
    second = ((int64_t)(duration - time) % 3600) % 60;
    [self.leftTimeLabel setText:[NSString stringWithFormat:@"%2.2d:%2.2d:%2.2d",hour, minute, second]];

    [self.infoLabel setText:self.player.infoString];
    [self performSelector:@selector(monitorPlaybackTime) withObject:nil afterDelay:1.0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    if (self.player == nil) {
        self.player = [[MoviePlayer alloc] init];
    }
    
    NSString * path = [[NSUserDefaults standardUserDefaults] valueForKey:@"videoPath"];
    int ret = [self.player open:path];
    if(ret != 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Get movie data failed! Please check your source or try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return ;
    } else {
        self.player.renderer = ((GLView*)self.view).renderer;
        [self.player setOutputViews:nil:self.infoLabel];

        int ret = [self.player start];
        if(ret != 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Can't play this movie! Please check its format." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return ;
        }
        isPlaying = YES;
        [self monitorPlaybackTime];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self.navigationController navigationBar] setHidden:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[self.navigationController navigationBar] setHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}


- (IBAction)doneButtonPressed:(id)sender
{
    isPlaying = NO;
    [self.player stop];
    [self.player close];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.navigationController popViewControllerAnimated:YES];
}


-(IBAction)pauseButtonPressed:(id)sender
{
    if([self.player movieIsPlaying] == YES) {
        [self.player pause];
        [sender setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [self.player go];
        [sender setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if ([touch tapCount] < 2) return;
    if ([touch view] == [self view]) {
        if(overlayHidden == YES) {
            [self showOverlayViews];
        } else {
            [self hideOverlayViews];
        }
    }
}

- (void) hideOverlayViews
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.infoLabel setHidden:YES];
    [self.doneButton setHidden:YES];
    [self.pauseButton setHidden:YES];
    [self.progressIndicator setHidden:YES];
    [self.playingTimeLabel setHidden:YES];
    [self.leftTimeLabel setHidden:YES];
    overlayHidden = YES;
}

- (void) showOverlayViews
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.infoLabel setHidden:NO];
    [self.doneButton setHidden:NO];
    [self.pauseButton setHidden:NO];
    [self.progressIndicator setHidden:NO];
    [self.playingTimeLabel setHidden:NO];
    [self.leftTimeLabel setHidden:NO];
    overlayHidden = NO;
}

- (IBAction) onSliderTouchDragExit: (UISlider*)sender
{
    int64_t time = [self.player getMovieDurationInSeconds] * self.progressIndicator.value;
    if ([self.player getMovieDurationInSeconds] - time < 10) {
        time = [self.player getMovieDurationInSeconds] - 10;
    }
    [self.player seekTo:time];
    flag = 2;
}

@end
