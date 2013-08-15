//
//  ViewController.m
//  ALAlertBannerDemo
//
//  Created by Anthony Lobianco on 8/12/13.
//  Copyright (c) 2013 Anthony Lobianco. All rights reserved.
//

#import "ViewController.h"
#import "ALAlertBanner.h"
#import "AppDelegate.h"

static NSString *loremIpsum[] = {
    @"Aliquam facilisis gravida ipsum, eu varius lacus lobortis eu. Fusce ac suscipit elit, eu varius tortor. Sed sed vestibulum ante. Integer eu orci eget felis pulvinar scelerisque. Etiam euismod risus ipsum.",
    @"Nunc id dictum enim. Nulla facilisi.",
    @"Mauris fermentum tellus in ligula laoreet accumsan. Nullam felis ipsum, ultrices id lacus a, accumsan tempor sapien."
};

@interface ViewController ()

@property (nonatomic, strong) UIButton *topButton;
@property (nonatomic, strong) UIButton *bottomButton;
@property (nonatomic, strong) UIButton *showInViewButton;
@property (nonatomic, strong) UIButton *hideAllBannersButton;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, readwrite) ALAlertBannerPosition position;

@end

@implementation ViewController

-(id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"ALAlertBanner", @"ALAlertBanner");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
        
    self.view.backgroundColor = [UIColor lightGrayColor];
        
    self.topButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.topButton.tag = ALAlertBannerPositionTop;
    [self.topButton setTitle:@"Top" forState:UIControlStateNormal];
    [self.topButton addTarget:self action:@selector(selectPosition:) forControlEvents:UIControlEventTouchUpInside];
    [self.topButton setHighlighted:YES];
    [self.view addSubview:self.topButton];
    
    self.bottomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.bottomButton.tag = ALAlertBannerPositionBottom;
    [self.bottomButton setTitle:@"Bottom" forState:UIControlStateNormal];
    [self.bottomButton addTarget:self action:@selector(selectPosition:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.bottomButton];
    
    self.showInViewButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.showInViewButton setTitle:@"Show Banner" forState:UIControlStateNormal];
    [self.showInViewButton addTarget:self action:@selector(showAlertBannerInView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showInViewButton];
    
    self.hideAllBannersButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.hideAllBannersButton setTitle:@"Hide All" forState:UIControlStateNormal];
    [self.hideAllBannersButton addTarget:self action:@selector(hideAllBanners) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hideAllBannersButton];
    
    self.label = [[UILabel alloc] init];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.font = [UIFont italicSystemFontOfSize:10.f];
    self.label.text = @"Go ahead, spam the shit out of that Show button.";
    [self.view addSubview:self.label];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.position = ALAlertBannerPositionTop;
}

-(void)configureViewForPosition:(ALAlertBannerPosition)position
{
    self.topButton.frame = CGRectMake(20, position == ALAlertBannerPositionTop ? self.view.frame.size.height - 200.f : 100.f, self.view.frame.size.width/2 - 20.f, 40.f);
    self.bottomButton.frame = CGRectMake(self.topButton.frame.origin.x + self.topButton.frame.size.width, self.topButton.frame.origin.y, self.topButton.frame.size.width, self.topButton.frame.size.height);
    self.showInViewButton.frame = CGRectMake(self.topButton.frame.origin.x, self.topButton.frame.origin.y + self.topButton.frame.size.height + 10.f, self.view.frame.size.width/2 - 20.f, self.topButton.frame.size.height);
    self.hideAllBannersButton.frame = CGRectMake(self.showInViewButton.frame.origin.x + self.showInViewButton.frame.size.width, self.showInViewButton.frame.origin.y, self.view.frame.size.width/2 - 20.f, self.showInViewButton.frame.size.height);
    self.label.frame = CGRectMake(self.showInViewButton.frame.origin.x, self.showInViewButton.frame.origin.y + self.showInViewButton.frame.size.height + 10.f, self.showInViewButton.frame.size.width + self.hideAllBannersButton.frame.size.width, 20.f);
}

-(void)selectPosition:(UIButton*)button
{
    [self clearAllPositionButtons];
    [self performSelector:@selector(highlightButton:) withObject:button afterDelay:0.0];
    ALAlertBannerPosition position = (ALAlertBannerPosition)button.tag;
    self.position = position;
}

-(void)showAlertBannerInView:(UIButton*)button
{
    ALAlertBannerStyle randomStyle = (ALAlertBannerStyle)(arc4random_uniform(4));
    [[ALAlertBannerManager sharedManager] showAlertBannerInView:self.view style:randomStyle position:self.position title:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit." subtitle:[self randomLoremIpsum]];
}

-(void)hideAllBanners
{
    [[ALAlertBannerManager sharedManager] hideAllAlertBanners];
}

-(void)highlightButton:(UIButton *)button
{
    [button setHighlighted:YES];
}

-(void)clearAllPositionButtons
{
    [self.topButton setHighlighted:NO];
    [self.bottomButton setHighlighted:NO];
}

-(NSString*)randomLoremIpsum
{
    static int arrayCount = sizeof(loremIpsum) / sizeof(loremIpsum[0]);
    return loremIpsum[arc4random_uniform(arrayCount)];
}

-(void)setPosition:(ALAlertBannerPosition)position
{
    _position = position;
    [self configureViewForPosition:position];
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self configureViewForPosition:self.position];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
