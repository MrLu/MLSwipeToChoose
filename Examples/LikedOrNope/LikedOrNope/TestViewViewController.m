//
//  TestViewViewController.m
//  LikedOrNope
//
//  Created by Mrlu on 03/08/2017.
//  Copyright © 2017 modocache. All rights reserved.
//

#import "TestViewViewController.h"
#import "MLSwipeableView.h"

@interface TestViewViewController () <MLSwipeableViewDelegate,MLSwipeableViewDataSource>

@property (nonatomic, strong) MLSwipeableView *MLSwipeableView;

@end

@implementation TestViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.MLSwipeableView];
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn setFrame:CGRectMake(10, self.view.bounds.size.height - 50, 60, 35)];
    [leftBtn setTitle:@"left" forState:UIControlStateNormal];
    [leftBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(leftBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftBtn];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setFrame:CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 50, 60, 35)];
    [rightBtn setTitle:@"right" forState:UIControlStateNormal];
    [rightBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rightBtn];
}

- (void)leftBtnAction:(UIButton *)sender{
    [self.MLSwipeableView swipeTopViewToLeft];
}

- (void)rightBtnAction:(UIButton *)sender{
    [self.MLSwipeableView swipeTopViewToRight];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MLSwipeableView *)MLSwipeableView {
    if (!_MLSwipeableView) {
        _MLSwipeableView = [[MLSwipeableView alloc] initWithFrame:self.view.bounds];
        _MLSwipeableView.delegate = self;
        _MLSwipeableView.dataSource = self;
        _MLSwipeableView.threshold = 220;
    }
    return _MLSwipeableView;
}

- (UIView *)nextViewForSwipeableView:(MLSwipeableView *)swipeableView {
    UIView *view = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(swipeableView.bounds, UIEdgeInsetsMake(40, 20, 100, 20)) ];
    view.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255. green:(arc4random()%255)/255. blue:(arc4random()%255)/255. alpha:1];
    view.layer.allowsEdgeAntialiasing = YES;
    return view;
}

- (void)swipeableView:(MLSwipeableView *)swipeableView didSwipeLeft:(UIView *)view {

}

- (void)swipeableView:(MLSwipeableView *)swipeableView didSwipeRight:(UIView *)view {
    
}



@end
