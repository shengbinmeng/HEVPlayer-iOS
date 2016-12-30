//
//  MoreViewController.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MoreViewController.h"
#import "PlayViewController.h"

@implementation MoreViewController {
    UITextField * urlTextField;
    UIActivityIndicatorView *dataLoadingIndicator;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"More";
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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
        return 3;
    } else if (section == 1) {
        return 1;
    }
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleDefaultCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"styleDefaultCell"];
        }

        if ([indexPath row] == 0) {
            UITextField *textField = [[UITextField alloc] initWithFrame:[cell frame]];
            textField.placeholder = @"Input your URL here";
            textField.keyboardType = UIKeyboardTypeURL;
            textField.returnKeyType = UIReturnKeyDone;
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.textAlignment = NSTextAlignmentCenter;
            textField.adjustsFontSizeToFitWidth = YES;
            textField.delegate = self;

            [urlTextField removeFromSuperview];
            urlTextField = textField;
            [cell.contentView addSubview:urlTextField];
        }
        
        if ([indexPath row] == 1) {
            [cell.textLabel setText:@"Download"];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            return cell;
        }
        if ([indexPath row] == 2) {
            [cell.textLabel setText:@"Play"];
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        }
        return cell;
    }
       
    if ([indexPath section] == 1) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"styleValue1Cell"];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleValue1Cell"];
        }
        [cell.textLabel setText:@"Click to go:"];
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
        header = @"Website";
    }
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	NSString *footerText = @"";
    if (section == 0) {
        footerText = @"Input a valid URL and click Download to add it to Movies, or click Play to play it directly.";
    }
    return footerText;
}

- (void) downloadFile:(NSString*) urlString
{    
    [self performSelectorInBackground:@selector(loadData:) withObject:urlString];
}

- (void) loadData:(NSString*) urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if (urlData)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [url lastPathComponent]];
        [urlData writeToFile:filePath atomically:YES];
    }
    
    [dataLoadingIndicator stopAnimating];
    [dataLoadingIndicator removeFromSuperview];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        if ([indexPath row] == 1) {
            NSString *url = [urlTextField text];
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"pathHistory"];
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [self.view insertSubview:indicator aboveSubview:self.tableView];
            indicator.center = self.view.center;
            [indicator startAnimating];
            
            dataLoadingIndicator = indicator;
            
            // load data in the main thread will block the UI response
            // should load large data in the background
            [self performSelectorInBackground:@selector(loadData:) withObject:url];
                        
            return;
        }
        
        if ([indexPath row] == 2) {
            NSString *url = [urlTextField text];
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"pathHistory"];
            [[NSUserDefaults standardUserDefaults] setValue:url forKey:@"videoPath"];
            PlayViewController *playViewController = [[PlayViewController alloc] initWithNibName:@"PlayViewController" bundle:nil];
            [self.navigationController pushViewController:playViewController animated:YES];
            
            return;
        }
    }
    
    if ([indexPath section] == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:@"http://www.xhevc.com"]];
        return;
    }
}


@end
