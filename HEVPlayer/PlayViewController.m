//
//  PlayViewController.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013年 Peking University. All rights reserved.
//

#import "PlayViewController.h"

@interface PlayViewController ()

@end

@implementation PlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (self.player == nil) {
        self.player = [[MoviePlayer alloc] init];
    }
    NSString * path = [[NSUserDefaults standardUserDefaults] valueForKey:@"videoPath"];
    int ret = [self.player openMovie:path];
    if(ret != 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Get movie data failed! Please check your source or try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return ;
    } else {
        [self.player setOutputViews:self.imageView:self.infoLabel];
        [self.player play];
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

- (IBAction)doneButtonPressed:(id)sender {
    [self.player stop];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
