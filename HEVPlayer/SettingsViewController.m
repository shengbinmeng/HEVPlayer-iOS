//
//  SettingsViewController.m
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "SettingsViewController.h"
#import "ToggleSwitchCell.h"
#import "TextFieldCell.h"
#import "PlayViewController.h"

@implementation SettingsViewController {
    UITextField * serverTextField;
    UITextField * actTextField;
    BOOL keyboardIsShowing;
}

@synthesize settingsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"More with HEVPlayer";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void) keyboardWillShow:(NSNotification *)note
{
    if (keyboardIsShowing) {
        return ;
    }
    keyboardIsShowing = YES;
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.settingsTableView.frame;
    
    // Start animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view 
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height -= keyboardBounds.size.height;
    else 
        frame.size.height -= keyboardBounds.size.width;
    
    // Apply new size of table view
    self.settingsTableView.frame = frame;
    
    // Scroll the table view to see the TextField just above the keyboard
    if (actTextField)
    {
        CGRect textFieldRect = [self.settingsTableView convertRect:actTextField.bounds fromView:actTextField];
        [self.settingsTableView scrollRectToVisible:textFieldRect animated:NO];
    }
    
    [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note
{
    keyboardIsShowing = NO;
    
    // Get the keyboard size
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    
    // Detect orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = self.settingsTableView.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view 
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height += keyboardBounds.size.height;
    else 
        frame.size.height += keyboardBounds.size.width;
    
    // Apply new size of table view
    self.settingsTableView.frame = frame;
    
    [UIView commitAnimations];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    keyboardIsShowing = NO;
    
    // Register notification when the keyboard will be show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    // Register notification when the keyboard will be hide
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    actTextField = nil;
    self.settingsTableView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    actTextField = textField;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    actTextField = nil;
}

#pragma mark Actions

- (void) showInfoToggled:(id)sender {
    if ([sender isOn]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"showInfo"];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"showInfo"];
    }
}


#pragma mark - Table View delegate and data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 1;
    }
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            static NSString *CellIdentifier = @"TextFieldCell";
            TextFieldCell *cell = (TextFieldCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextFieldCell"owner:nil options:nil];
                for (id oneObject in nib)
                    if ([oneObject isKindOfClass:[TextFieldCell class]])
                        cell = (TextFieldCell*)oneObject;
            }
            [cell.textField setPlaceholder:@"Input your URL here"];
            cell.textField.delegate = self;
            if([[NSUserDefaults standardUserDefaults] valueForKey:@"pathHistory"]) {
                cell.textField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"pathHistory"];
            } else {
                cell.textField.text = @"";
            };
            return cell;
        }
        
        if ([indexPath row] == 1) {
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleDefaultCell"];
            if(cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"styleDefaultCell"];
            }
            [cell.textLabel setText:@"Open"];
            [cell.textLabel setTextAlignment:UITextAlignmentCenter];
            return cell;
        }
    }

    if ([indexPath section] == 1) {
        static NSString *CellIdentifier = @"ToggleSwitchCell";
        ToggleSwitchCell *cell = (ToggleSwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ToggleSwitchCell"owner:nil options:nil];
            for (id oneObject in nib)
                if ([oneObject isKindOfClass:[ToggleSwitchCell class]])
                    cell = (ToggleSwitchCell *)oneObject;
        }
        [[cell label] setText:@"Show Info"];
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"showInfo"] isEqualToString:@"YES"]) {
            [[cell toggle] setOn:YES];
        } else {
            [[cell toggle] setOn:NO];
        }
        [[cell toggle] addTarget:self action:@selector(showInfoToggled:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
       
    if ([indexPath section] == 2) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleValue1Cell"];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleValue1Cell"];
        }
        [cell.textLabel setText:@"Click to go:"];
        [cell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
        [cell.detailTextLabel setText:@"http://www.xhevc.com"];
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = @"";
    if (section == 0) {
        header = @"Open Location";
    }
    if (section == 1) {
        header = @"Settings";
    }
    if (section == 2) {
        header = @"Website";
    }
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSString *footerText = @"";
    if (section == 0) {
        footerText = @"Input a valid URL and click Open to play";
    } else if (section == 1) {
        footerText = @"show more information about media when playing, such as video size, decode and display FPS, etc.";
    }
    return footerText;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        if ([indexPath row] == 1) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            NSString *url = [((TextFieldCell*)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).textField text];
            if ([url length] < 9 || (([[url substringToIndex:7] isEqualToString:@"http://"]) == NO) || ([[url substringFromIndex:[url length] - 5] isEqualToString:@".hevc"] == NO)) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Input is invalid!\nURL should start with 'http://' and end with .hevc" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return ;
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"videoPath"];
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"pathHistory"];
            
            PlayViewController *playViewController =[[PlayViewController alloc] initWithNibName:@"PlayViewController" bundle:nil];
            [self.navigationController pushViewController:playViewController animated:YES];
            return;
        }
    }
    
    if ([indexPath section] == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:@"http://www.xhevc.com"]];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
