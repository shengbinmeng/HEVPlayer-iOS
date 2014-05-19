//
//  SettingsViewController.m
//  IPGateway
//
//  Created by Meng Shengbin on 2/1/12.
//  Copyright (c) 2012 Peking University. All rights reserved.
//

#import "SettingsViewController.h"
#import "TextFieldCell.h"
#import "PlayViewController.h"

@implementation SettingsViewController {
    UITextField * serverTextField;
    UITextField * actTextField;
    BOOL keyboardIsShowing;
    UIActivityIndicatorView *theIndicator;
    UIView *theActionSheet;

    //Say you have an array of strings you want to present in the pickerview like this
    NSArray *arrayOfStrings;
    int selectedRow;
    
    NSArray *arrayOfStringsFPS;
    int selectedRowFPS;

}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"More with HEVPlayer";
    }
    
    arrayOfStrings = [NSArray arrayWithObjects:@"0 (auto)", @"1", @"2", @"4", nil];
    NSString *num = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    selectedRow = [arrayOfStrings indexOfObject:num];
    
    arrayOfStringsFPS = [NSArray arrayWithObjects:@"0 (full speed)", @"24.0", nil];
    NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    selectedRowFPS = [arrayOfStringsFPS indexOfObject:fps];
    
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
    CGRect frame = self.tableView.frame;
    
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
    self.tableView.frame = frame;
    
    // Scroll the table view to see the TextField just above the keyboard
    if (actTextField)
    {
        CGRect textFieldRect = [self.tableView convertRect:actTextField.bounds fromView:actTextField];
        [self.tableView scrollRectToVisible:textFieldRect animated:NO];
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
    CGRect frame = self.tableView.frame;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // Reduce size of the Table view 
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.size.height += keyboardBounds.size.height;
    else 
        frame.size.height += keyboardBounds.size.width;
    
    // Apply new size of table view
    self.tableView.frame = frame;
    
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([theActionSheet isHidden] == NO) {
        [theActionSheet setHidden:YES];
    }
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



#pragma mark - Table View delegate and data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
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
            [cell.textLabel setText:@"Download"];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            return cell;
        }
    }
       
    if ([indexPath section] == 1) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleValue1Cell"];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleValue1Cell"];
        }
        [cell.textLabel setText:@"Click to go:"];
        [cell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
        [cell.detailTextLabel setText:@"http://www.xhevc.com"];
        return cell;
    }
    
    if ([indexPath section] == 2) {
        
        if ([indexPath row] == 0) {
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleValue1Cell"];
            if(cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleValue1Cell"];
            }
            
            [cell.textLabel setText:@"Decoding Thread Number"];
            [cell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
            NSString *num = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
            [cell.detailTextLabel setText:num];
            
            return cell;
        }
        
        if ([indexPath row] == 1) {
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleValue1Cell"];
            if(cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleValue1Cell"];
            }
            
            [cell.textLabel setText:@"Render FPS"];
            [cell.textLabel setFont:[UIFont systemFontOfSize:17.0]];
            NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
            [cell.detailTextLabel setText:fps];
            
            return cell;
        }
        
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *header = @"";
    if (section == 0) {
        header = @"Open Location";
    }
    if (section == 1) {
        header = @"Website";
    }
    if (section == 2) {
        header = @"Settings";
    }
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSString *footerText = @"";
    if (section == 0) {
        footerText = @"Input a valid URL and click Download to add it to Movies";
    }
    return footerText;
}

- (void) downloadFile:(NSString*) urlString
{    
    [self performSelectorInBackground:@selector(loadData:) withObject:urlString];
}

- (void) loadData:(NSString*) urlString
{
    NSURL  *url = [NSURL URLWithString:urlString];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if (urlData)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [url lastPathComponent]];
        [urlData writeToFile:filePath atomically:YES];
    }
    
    [theIndicator stopAnimating];
    [theIndicator removeFromSuperview];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)viewAnimation:(UIView*)view willHidden:(BOOL)hidden {
    
    [UIView animateWithDuration:0.3 animations:^{
        if (hidden) {
            view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 240);
        } else {
            [view setHidden:hidden];
            view.frame = CGRectMake(0, self.view.frame.size.height - 240, self.view.frame.size.width, 240);
        }
    } completion:^(BOOL finished) {
        [view setHidden:hidden];
    }];
}

- (void) doneButtonPressed
{
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStrings objectAtIndex:selectedRow] forKey:@"threadNum"];
    [[NSUserDefaults standardUserDefaults] setValue:[arrayOfStringsFPS objectAtIndex:selectedRowFPS] forKey:@"renderFPS"];
    
    [self viewAnimation:theActionSheet willHidden:YES];
    [self.tableView reloadData];
}

- (void) cancelButtonPressed
{
    // restore selectedRow
    NSString *num = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    selectedRow = [arrayOfStrings indexOfObject:num];
    NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    selectedRowFPS = [arrayOfStringsFPS indexOfObject:fps];
    
    [self viewAnimation:theActionSheet willHidden:YES];
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
            
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"pathHistory"];
            
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [self.view insertSubview:indicator aboveSubview:self.tableView];
            indicator.center = self.view.center;
            [indicator startAnimating];
            
            theIndicator = indicator;
            
            // load data in the main thread will block the UI response
            // should load large data in the background
            [self performSelectorInBackground:@selector(loadData:) withObject:url];
                        
            return;
        }
    }
    
    if ([indexPath section] == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:@"http://www.xhevc.com"]];
        return;
    }
    
    if ([indexPath section] == 2) {
        if ([indexPath row] == 0) {
            //float height = self.view.frame.size.height;
            float height = self.view.frame.size.height;
            
            float width = self.view.frame.size.width;
            float myHeight = 240;
            float myWidth = width;
            UIView *myActionSheet = [[UIView alloc] initWithFrame:CGRectMake(0, height, myWidth, myHeight)];
            
            UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, myWidth, 44)];
            pickerToolbar.barStyle = UIBarStyleBlackOpaque;
            
            NSMutableArray *barItems = [[NSMutableArray alloc] init];
            
            UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed)];
            [barItems addObject:doneBtn];
            
            UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)];
            [barItems addObject:cancelBtn];
            
            UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
            [barItems addObject:flexSpace];
            
            [pickerToolbar setItems:barItems animated:YES];
            
            UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, myWidth, myHeight - 44)];
            [pickerView setTag:0];

            pickerView.showsSelectionIndicator = YES;
            pickerView.dataSource = self;
            pickerView.delegate = self;
            
            [myActionSheet addSubview:pickerToolbar];
            [myActionSheet addSubview:pickerView];
            
            [pickerView selectRow:selectedRow inComponent:0 animated:YES];
            theActionSheet = myActionSheet;
            
            [self.view addSubview:theActionSheet];
            [self viewAnimation:theActionSheet willHidden:NO];
        }
        
        if ([indexPath row] == 1) {
            //float height = self.view.frame.size.height;
            float height = self.view.frame.size.height;
            
            float width = self.view.frame.size.width;
            float myHeight = 240;
            float myWidth = width;
            UIView *myActionSheet = [[UIView alloc] initWithFrame:CGRectMake(0, height, myWidth, myHeight)];
            
            UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, myWidth, 44)];
            pickerToolbar.barStyle = UIBarStyleBlackOpaque;
            
            NSMutableArray *barItems = [[NSMutableArray alloc] init];
            
            UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonPressed)];
            [barItems addObject:doneBtn];
            
            UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)];
            [barItems addObject:cancelBtn];
            
            UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
            [barItems addObject:flexSpace];
            
            [pickerToolbar setItems:barItems animated:YES];
            
            UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, myWidth, myHeight - 44)];
            [pickerView setTag:1];

            pickerView.showsSelectionIndicator = YES;
            pickerView.dataSource = self;
            pickerView.delegate = self;
            
            [myActionSheet addSubview:pickerToolbar];
            [myActionSheet addSubview:pickerView];
            
            [pickerView selectRow:selectedRowFPS inComponent:0 animated:YES];
            theActionSheet = myActionSheet;
            
            [self.view addSubview:theActionSheet];
            [self viewAnimation:theActionSheet willHidden:NO];
        }

    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    int num = 0;
    if (pickerView.tag == 0) {
        num = [arrayOfStrings count];
    }
    if (pickerView.tag == 1) {
        num = [arrayOfStringsFPS count];
    }
    
    return num;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(pickerView.tag == 0) {
        return [arrayOfStrings objectAtIndex:row];
    }
    if(pickerView.tag == 1) {
        return [arrayOfStringsFPS objectAtIndex:row];
    }
    return @"Damn! A Bug!";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(pickerView.tag == 0) {
        selectedRow = row;
    }
    if(pickerView.tag == 1) {
        selectedRowFPS = row;
    }
}

@end
