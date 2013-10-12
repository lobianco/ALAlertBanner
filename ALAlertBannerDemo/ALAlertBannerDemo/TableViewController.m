//
//  TableController.m
//  ALAlertBannerDemo
//
//  Created by Anthony Lobianco on 10/12/13.
//  Copyright (c) 2013 Anthony Lobianco. All rights reserved.
//

#import "TableViewController.h"
#import "ALAlertBanner.h"

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

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Banner" style:UIBarButtonItemStyleBordered target:self action:@selector(show)];
}

- (void)show {
    ALAlertBannerPosition position = ALAlertBannerPositionTop;
    ALAlertBannerStyle randomStyle = (ALAlertBannerStyle)(arc4random_uniform(4));
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.view style:randomStyle position:position title:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit." subtitle:@"This is an alert banner in a table." tappedBlock:^(ALAlertBanner *alertBanner) {
        NSLog(@"tapped!");
        [alertBanner hide];
    }];
    [banner show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %i", indexPath.row];
    
    return cell;
}

@end
