/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class represents a node/sequencer.
                 It contains -
                     A reference to the AudioEngine
                     Basic Views for displaying parameters. Subclasses can provide their own views for customization
*/

#import "AudioViewController.h"

@interface AudioViewController ()

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //if the device is an iPad, add the view to the stackview and display it right away
    //else for iPhone, make the title bar selectable, and then present the view modally
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.stackView addArrangedSubview:self.parameterView];
    } else {
        UITapGestureRecognizer *titleViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showParameterView:)];
        [self.titleView addGestureRecognizer:titleViewTap];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognizer:)];
        swipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self.parameterView addGestureRecognizer:swipe];
    }
    
    [self updateUIElements];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// style play/stop button
- (void)styleButton:(UIButton *)button isPlaying:(BOOL)isPlaying
{
    if (isPlaying)
        [button setTitle: @"Stop" forState: UIControlStateNormal];
    else
        [button setTitle: @"Play" forState: UIControlStateNormal];
}

//present parameter view
- (void)showParameterView:(UITapGestureRecognizer *)recognizer {
    
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        UINavigationController *navigationController = [UINavigationController new];
        UIViewController *controller = [UIViewController new];
        controller.view = self.parameterView;
        navigationController.viewControllers = @[controller];
        navigationController.navigationBar.translucent = NO;
        navigationController.navigationBar.barTintColor = self.titleView.tintColor;
        navigationController.navigationBar.topItem.title = self.titleLabel.text;
        [UINavigationBar appearance].tintColor = [UIColor blackColor];
        
        UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(swipeRecognizer:)];
        [navigationController.navigationBar.topItem setRightBarButtonItem:dismissButton];
        
        self.parameterView.presentedController = navigationController;
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

//swipe down to dismiss the controller
- (void)swipeRecognizer:(UISwipeGestureRecognizer *)sender {
    [self.parameterView.presentedController dismissViewControllerAnimated:YES completion:nil];
    self.parameterView.presentedController = nil;
}

//subclasses can overide this method to update their UI elements when the engine is re/configured
-(void)updateUIElements
{
    
}



@end
