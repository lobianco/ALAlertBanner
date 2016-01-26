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
#import "TableViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *topButton;
@property (nonatomic, strong) UIButton *bottomButton;
@property (nonatomic, strong) UIButton *underNavButton;
@property (nonatomic, strong) UIButton *changeTextButton;

@property (nonatomic, strong) UISlider *secondsToShowSlider;
@property (nonatomic, strong) UILabel *secondsToShowLabel;
@property (nonatomic) NSTimeInterval secondsToShow;

@property (nonatomic, strong) UISlider *animationDurationSlider;
@property (nonatomic, strong) UILabel *animationDurationLabel;
@property (nonatomic) NSTimeInterval showAnimationDuration;
@property (nonatomic) NSTimeInterval hideAnimationDuration;

@property (nonatomic, weak) ALAlertBanner *lastBanner;

@end

@implementation ViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"ALAlertBanner", @"ALAlertBanner");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide All" style:UIBarButtonItemStyleBordered target:[ALAlertBanner class] action:@selector(hideAllAlertBanners)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Table" style:UIBarButtonItemStyleBordered target:self action:@selector(push)];
    
    self.view.backgroundColor = [UIColor colorWithRed:243/255.0 green:247/255.0 blue:249/255.0 alpha:1.f];
    
    _secondsToShow = 3.5;
    _showAnimationDuration = 0.25;
    _hideAnimationDuration = 0.2;
        
    self.topButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.topButton.tag = ALAlertBannerPositionTop;
    [self.topButton setTitle:@"Top" forState:UIControlStateNormal];
    [self.topButton addTarget:self action:@selector(showAlertBannerInView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.topButton];
    
    self.bottomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.bottomButton.tag = ALAlertBannerPositionBottom;
    [self.bottomButton setTitle:@"Bottom" forState:UIControlStateNormal];
    [self.bottomButton addTarget:self action:@selector(showAlertBannerInView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.bottomButton];
    
    self.underNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.underNavButton.tag = ALAlertBannerPositionUnderNavBar;
    [self.underNavButton setTitle:@"UIWindow" forState:UIControlStateNormal];
    [self.underNavButton addTarget:self action:@selector(showAlertBannerInWindow:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.underNavButton];
    
    self.secondsToShowSlider = [[UISlider alloc] init];
    self.secondsToShowSlider.continuous = YES;
    self.secondsToShowSlider.minimumValue = 0.f;
    self.secondsToShowSlider.maximumValue = 10.f;
    [self.secondsToShowSlider setValue:3.5f];
    [self.secondsToShowSlider addTarget:self action:@selector(secondsToShowSlider:) forControlEvents:UIControlEventValueChanged];
    [self.secondsToShowSlider addTarget:self action:@selector(secondsToShowSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.secondsToShowSlider];
    
    self.secondsToShowLabel = [[UILabel alloc] init];
    self.secondsToShowLabel.backgroundColor = [UIColor clearColor];
    self.secondsToShowLabel.font = [UIFont systemFontOfSize:10.f];
    self.secondsToShowLabel.text = @"Seconds to show: 3.5 seconds";
    self.secondsToShowLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.secondsToShowLabel];
    
    self.animationDurationSlider = [[UISlider alloc] init];
    self.animationDurationSlider.continuous = YES;
    self.animationDurationSlider.minimumValue = 0.01f;
    self.animationDurationSlider.maximumValue = 2.f;
    [self.animationDurationSlider setValue:0.25f];
    [self.animationDurationSlider addTarget:self action:@selector(animationDurationSlider:) forControlEvents:UIControlEventValueChanged];
    [self.animationDurationSlider addTarget:self action:@selector(animationDurationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.animationDurationSlider];

    self.animationDurationLabel = [[UILabel alloc] init];
    self.animationDurationLabel.backgroundColor = [UIColor clearColor];
    self.animationDurationLabel.font = [UIFont systemFontOfSize:10.f];
    self.animationDurationLabel.text = @"Animation duration: 0.25 seconds";
    self.animationDurationLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.animationDurationLabel];

    self.changeTextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.changeTextButton setTitle:@"Change text" forState:UIControlStateNormal];
    [self.changeTextButton addTarget:self action:@selector(changeText) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.changeTextButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [ALAlertBanner forceHideAllAlertBannersInView:self.view];
}

- (void)configureView {
    self.topButton.frame = CGRectMake(20, self.view.frame.size.height/2 - 80.f, (self.view.frame.size.width - 40.f)/3, 40.f);
    self.bottomButton.frame = CGRectMake(self.topButton.frame.origin.x + self.topButton.frame.size.width, self.topButton.frame.origin.y, self.topButton.frame.size.width, self.topButton.frame.size.height);
    self.underNavButton.frame = CGRectMake(self.bottomButton.frame.origin.x + self.bottomButton.frame.size.width, self.topButton.frame.origin.y, self.topButton.frame.size.width, self.topButton.frame.size.height);
    
    self.secondsToShowSlider.frame = CGRectMake(self.topButton.frame.origin.x, self.topButton.frame.origin.y + self.topButton.frame.size.height + 20.f, self.view.frame.size.width - 40.f, 20.f);
    self.secondsToShowLabel.frame = CGRectMake(self.secondsToShowSlider.frame.origin.x, self.secondsToShowSlider.frame.origin.y + self.secondsToShowSlider.frame.size.height, self.secondsToShowSlider.frame.size.width, 20.f);
    self.animationDurationSlider.frame = CGRectMake(self.secondsToShowSlider.frame.origin.x, self.secondsToShowLabel.frame.origin.y + self.secondsToShowLabel.frame.size.height + 20.f, self.view.frame.size.width - 40.f, 20.f);
    self.animationDurationLabel.frame = CGRectMake(self.animationDurationSlider.frame.origin.x, self.animationDurationSlider.frame.origin.y + self.animationDurationSlider.frame.size.height, self.animationDurationSlider.frame.size.width, 20.f);

    self.changeTextButton.frame = CGRectMake(self.bottomButton.frame.origin.x, self.animationDurationSlider.frame.origin.y + self.animationDurationSlider.frame.size.height + 20.f, self.bottomButton.frame.size.width, self.bottomButton.frame.size.height);
}

- (void)showAlertBannerInView:(UIButton *)button {
    ALAlertBannerPosition position = (ALAlertBannerPosition)button.tag;
    ALAlertBannerStyle randomStyle = (ALAlertBannerStyle)(arc4random_uniform(4));
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.view style:randomStyle position:position title:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit." subtitle:[AppDelegate randomLoremIpsum] tappedBlock:^(ALAlertBanner *alertBanner) {
        NSLog(@"tapped!");
        [alertBanner hide];
    }];
    banner.secondsToShow = self.secondsToShow;
    banner.showAnimationDuration = self.showAnimationDuration;
    banner.hideAnimationDuration = self.hideAnimationDuration;
    [banner show];
    
    self.lastBanner = banner;
}

- (void)changeText {
    [self.lastBanner changeTitle:@"Text changed" subtitle:[[AppDelegate randomLoremIpsum] stringByAppendingString:[AppDelegate randomLoremIpsum]]];
}

- (void)showAlertBannerInWindow:(UIButton *)button {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ALAlertBannerStyle randomStyle = (ALAlertBannerStyle)(arc4random_uniform(4));
    ALAlertBannerPosition position = (ALAlertBannerPosition)button.tag;
    ALAlertBanner *banner = [ALAlertBanner alertBannerForView:appDelegate.window style:randomStyle position:position title:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit." subtitle:[AppDelegate randomLoremIpsum] tappedBlock:^(ALAlertBanner *alertBanner) {
        NSLog(@"tapped!");
        [alertBanner hide];
    }];
    banner.secondsToShow = self.secondsToShow;
    banner.showAnimationDuration = self.showAnimationDuration;
    banner.hideAnimationDuration = self.hideAnimationDuration;
    [banner show];
}

- (void)push {
    [self.navigationController pushViewController:[[TableViewController alloc] init] animated:YES];
}

- (void)secondsToShowSlider:(UISlider *)slider {
    CGFloat roundedValue = round(slider.value * 100)/100.0;
    [slider setValue:roundedValue animated:NO];
    self.secondsToShowLabel.text = [NSString stringWithFormat:@"Seconds to show: %.02f seconds", roundedValue];
}

- (void)secondsToShowSliderTouchEnded:(UISlider *)slider {
    [self setSecondsToShow:slider.value];
}

- (void)animationDurationSlider:(UISlider *)slider {
    CGFloat roundedValue = round(slider.value * 100)/100.0;
    [slider setValue:roundedValue animated:NO];
    self.animationDurationLabel.text = [NSString stringWithFormat:@"Animation duration: %0.02f seconds", roundedValue];
}

- (void)animationDurationSliderTouchEnded:(UISlider *)slider {
    [self setShowAnimationDuration:slider.value];
    [self setHideAnimationDuration:slider.value];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
