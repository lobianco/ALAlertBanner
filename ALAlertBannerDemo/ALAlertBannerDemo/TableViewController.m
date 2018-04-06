//
//  TableController.m
//  ALAlertBannerDemo
//
//  Created by Anthony Lobianco on 10/12/13.
//  Copyright (c) 2013 Anthony Lobianco. All rights reserved.
//

#import "TableViewController.h"
#import "ALAlertBanner.h"
#import "AppDelegate.h"
#import "ALBannerStyleConfiguration.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Banner" style:UIBarButtonItemStyleBordered target:self action:@selector(showAlertBannerInView)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ALAlertBanner forceHideAllAlertBannersInView:self.view];
}

- (void)showAlertBannerInView {
    NSInteger styleNumber = arc4random_uniform(4);
    ALBannerStyleConfiguration *styleConfiguration = nil;
    switch (styleNumber) {
        case 0:
            styleConfiguration = [ALBannerStyleConfiguration successStyleConfiguration];
            break;
        case 1:
            styleConfiguration = [ALBannerStyleConfiguration failureStyleConfiguration];
            break;
        case 2:
            styleConfiguration = [ALBannerStyleConfiguration notifyStyleConfiguration];
            break;
        case 3:
            styleConfiguration = [ALBannerStyleConfiguration warningStyleConfiguration];
            break;
        default:
            styleConfiguration = [ALBannerStyleConfiguration successStyleConfiguration];
    }
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.view styleConfiguration:styleConfiguration position:ALAlertBannerPositionTop title:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit." subtitle:[AppDelegate randomLoremIpsum] tappedBlock:^(ALAlertBanner *alertBanner) {
        NSLog(@"tapped!");
        [alertBanner hide];
    }];
    [banner show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
        
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %li", (long)indexPath.row];
    
    return cell;
}

@end
