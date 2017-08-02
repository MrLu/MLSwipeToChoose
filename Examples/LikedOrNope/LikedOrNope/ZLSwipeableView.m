//
//  ZLSwipeableView.m
//  ZLSwipeableViewDemo
//
//  Created by Zhixuan Lai on 11/1/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import "ZLSwipeableView.h"
#import <MDCSwipeToChoose/MDCSwipeDirection.h>

const MDCRotationDirection MDCRotationAwayFromCenter = 1.f;
const MDCRotationDirection MDCRotationTowardsCenter = -1.f;

CGPoint MDCCGPointAdd(const CGPoint a, const CGPoint b) {
    return CGPointMake(a.x + b.x,
                       a.y + b.y);
}

@interface ZLPanGestureRecognizer:UIPanGestureRecognizer

@end

@implementation ZLPanGestureRecognizer

@end

static const int numPrefetchedViews = 3;

@interface ZLSwipeableView ()

// ContainerView
@property (strong, nonatomic) UIView *reuseCoverContainerView;

@property (nonatomic, strong) UIView *nextView;

/*!
 * The center of the view when the pan gesture began.
 */
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, assign) CATransform3D originalTransform;

/*!
 * When the pan gesture originates at the top half of the view, the view rotates
 * away from its original center, and this property takes on a value of 1.
 *
 * When the pan gesture originates at the bottom half, the view rotates toward its
 * original center, and this takes on a value of -1.
 */
@property (nonatomic, assign) MDCRotationDirection rotationDirection;

@end

@implementation ZLSwipeableView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator {
    NSLog(@"resume");
//    self.userInteractionEnabled = NO;
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator {
    NSLog(@"pause");
//    self.userInteractionEnabled = YES;
    if (!self.userInteractionEnabled) {
        self.userInteractionEnabled = YES;
    }
}

-(void)setup {
    self.originalCenter = self.center;
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.containerView];
    self.reuseCoverContainerView = [[UIView alloc] initWithFrame:self.bounds];
    self.reuseCoverContainerView.userInteractionEnabled = false;
    [self addSubview:self.reuseCoverContainerView];
    
    // Default properties
    self.isRotationEnabled = YES;
    self.rotationDegree = 1;
    self.rotationRelativeYOffsetFromCenter = 0.3;
    
    self.pushVelocityMagnitude = 1500;
    self.escapeVelocityThreshold = 750;
#pragma mark 卡片飞走的判定距离
    self.relativeDisplacementThreshold = 0.45;
    
    self.manualSwipeRotationRelativeYOffsetFromCenter = -0.2;
    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.containerView.frame = self.bounds;
    self.reuseCoverContainerView.frame = self.bounds;
    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

-(void)setSwipeableViewsCenter:(CGPoint)swipeableViewsCenter {
    _swipeableViewsCenter = swipeableViewsCenter;
    [self animateSwipeableViewsIfNeeded];
}

#pragma mark - Properties
- (void)setDataSource:(id<ZLSwipeableViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self loadNextSwipeableViewsIfNeeded:NO];
}

#pragma mark - DataSource
- (void)discardAllSwipeableViews {
    for (UIView *view in self.containerView.subviews) {
        [view removeFromSuperview];
    }
}
- (void)loadNextSwipeableViewsIfNeeded {
    [self loadNextSwipeableViewsIfNeeded:NO];
}
- (void)loadNextSwipeableViewsIfNeeded:(BOOL)animated {
    NSInteger numViews = self.containerView.subviews.count;
    NSMutableSet *newViews = [NSMutableSet set];
    for (NSInteger i=numViews; i<numPrefetchedViews; i++) {
        UIView *nextView = [self nextSwipeableView];
        if (nextView) {
        
            [self.containerView addSubview:nextView];
            [self.containerView sendSubviewToBack:nextView];
//            nextView.center = self.swipeableViewsCenter;
            
#pragma mark 下一张的布局
//            if (i == numViews+1) {
//                
//                self.nextView = nextView;
//            }
            nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y+CGRectGetHeight(nextView.frame)/2.*0.05+10);
            nextView.transform = CGAffineTransformMakeScale(0.95, 0.95);
            [newViews addObject:nextView];
        }
    }
//    if (self.containerView.subviews.count)
    for (int i = 0; i < self.containerView.subviews.count; i++) {
        UIView *av = [self.containerView.subviews objectAtIndex:i];
        av.tag = i;
    }
    if (animated) {
        NSTimeInterval maxDelay = 0.3;
        NSTimeInterval delayStep = maxDelay/numPrefetchedViews;
        NSTimeInterval aggregatedDelay = maxDelay;
        NSTimeInterval animationDuration = 0.25;
        for (UIView *view in newViews) {
            view.center = CGPointMake(view.center.x, -view.frame.size.height);
            [UIView animateWithDuration: animationDuration
                                  delay: aggregatedDelay
                                options: UIViewAnimationOptionCurveEaseIn
                             animations: ^{
                                 view.center = self.swipeableViewsCenter;
                             }
                             completion:^(BOOL finished) {
//                                 self.userInteractionEnabled = YES;
                             }];
            aggregatedDelay -= delayStep;
        }
        [self performSelector:@selector(animateSwipeableViewsIfNeeded) withObject:nil afterDelay:animationDuration];
    } else {
        [self animateSwipeableViewsIfNeeded];
    }
}

- (void)animateSwipeableViewsIfNeeded {
    UIView *topSwipeableView = [self topSwipeableView];
    if (!topSwipeableView) {return;}
    
    for (UIView *cover in self.containerView.subviews) {
        cover.userInteractionEnabled = NO;
    }
    topSwipeableView.userInteractionEnabled = YES;
    
    for (UIGestureRecognizer *recognizer in topSwipeableView.gestureRecognizers) {
        if (recognizer.state != UIGestureRecognizerStatePossible) {
            return;
        }
    }

    if (self.isRotationEnabled) {
        // rotation
        NSUInteger numSwipeableViews = self.containerView.subviews.count;
        if (numSwipeableViews>=1) {
            // 不会有抖动效果
            topSwipeableView.center = self.swipeableViewsCenter;
            topSwipeableView.transform = CGAffineTransformIdentity;
            return;
        }
        CGPoint rotationCenterOffset = {0,CGRectGetHeight(topSwipeableView.frame)*self.rotationRelativeYOffsetFromCenter};
        if (numSwipeableViews>=2) {
            [self rotateView:self.containerView.subviews[numSwipeableViews-2] forDegree:self.rotationDegree atOffsetFromCenter:rotationCenterOffset animated:YES];
            return;
        }
        if (numSwipeableViews>=3) {
            [self rotateView:self.containerView.subviews[numSwipeableViews-3] forDegree:-self.rotationDegree atOffsetFromCenter:rotationCenterOffset animated:YES];
            return;
        }
    }
}

#pragma mark - Action
-(void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    CGPoint location = [recognizer locationInView:self];
    
    UIView *swipeableView = recognizer.view;
    
    #pragma mark 下一张卡片变化
    CGFloat base = CGRectGetWidth(self.frame) / 2.;

    CGFloat move = fabsf(base-swipeableView.center.x);
    NSLog(@"%f   %f    %f", swipeableView.center.x, base, move);
    CGFloat max = 70.f;
    
    CGFloat ratio = move / max;
    if (ratio > 1) {
        ratio = 1;
    }
    
    UIView *nextView = nil;
    for (UIView *av in self.containerView.subviews) {
        NSLog(@"%d", av.tag);
        if (self.containerView.subviews.count > 2) {
            if (av.tag == 1) {
                nextView = av;
                break;
            }
        } else {
            if (av != swipeableView) {
                nextView = av;
                break;
            }
        }
        
    }
    if (nextView) {

        nextView.transform = CGAffineTransformMakeScale(0.95+0.05*ratio, 0.95+0.05*ratio);
        nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y+(CGRectGetHeight(nextView.frame)/2.*0.05+10)*(1-ratio));
    }
    
    UIView *view = recognizer.view;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.originalCenter = view.center;
        self.originalTransform = view.layer.transform;
        
        // If the pan gesture originated at the top half of the view, rotate the view
        // away from the center. Otherwise, rotate towards the center.
        if ([recognizer locationInView:view].y < view.center.y) {
            self.rotationDirection = MDCRotationAwayFromCenter;
        } else {
            self.rotationDirection = MDCRotationTowardsCenter;
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Either move the view back to its original position or move it off screen.
        [self mdc_finalizePosition];
    } else {
        // Update the position and transform. Then, notify any listeners of
        // the updates via the pan block.
        CGPoint translation = [recognizer translationInView:view];
        view.center = MDCCGPointAdd(self.originalCenter, translation);
        [self mdc_rotateForTranslation:translation
                     rotationDirection:self.rotationDirection];
        [self mdc_executeOnPanBlockForTranslation:translation];
    }

    
}

- (void)asas {
    self.userInteractionEnabled = YES;
}
- (void)swipeTopViewToLeft {
    [self swipeTopViewToLeft:YES];
}
- (void)swipeTopViewToRight {
    [self swipeTopViewToLeft:NO];
}

- (void)swipeTopViewToLeft:(BOOL)left {
    UIView *topSwipeableView = [self topSwipeableView];
    if (!topSwipeableView) {return;}
    CGPoint location = CGPointMake(topSwipeableView.center.x, topSwipeableView.center.y*(1+self.manualSwipeRotationRelativeYOffsetFromCenter));
}

- (void)left {
    if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableView:didSwipeLeft:)]) {
        [self.delegate swipeableView:self didSwipeLeft:nil];
    }
}

- (void)right {
    if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableView:didSwipeRight:)]) {
        
        [self.delegate swipeableView:self didSwipeRight:nil];
    }
}

#pragma mark - ()

- (CGFloat) degreesToRadians: (CGFloat) degrees
{
    return degrees * M_PI / 180;
};

- (CGFloat) radiansToDegrees: (CGFloat) radians
{
    return radians * 180 / M_PI;
};

- (UIView *)nextSwipeableView {
    UIView *nextView = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(nextViewForSwipeableView:)]) {
        nextView = [self.dataSource nextViewForSwipeableView:self];
    }
    return nextView;
}

- (void)rotateView:(UIView*)view forDegree:(float)degree atOffsetFromCenter:(CGPoint)offset animated:(BOOL)animated {
    float duration = animated? 0.4:0;
    NSLog(@"%lf", duration);
    float rotationRadian = [self degreesToRadians:degree];
    [UIView animateWithDuration:duration animations:^{
        view.center = self.swipeableViewsCenter;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
        transform = CGAffineTransformRotate(transform, rotationRadian);
        transform = CGAffineTransformTranslate(transform,-offset.x,-offset.y);
        view.transform=transform;
    } completion:^(BOOL finished) {
//        self.userInteractionEnabled = YES;
    }];
}
- (UIView *)topSwipeableView {
    return self.containerView.subviews.lastObject;
}

#pragma mark - Internal Helpers
- (void)mdc_swipe:(MDCSwipeDirection)direction {
    [self mdc_swipeToChooseSetupIfNecessary];
    
    // A swipe in no particular direction "finalizes" the swipe.
    if (direction == MDCSwipeDirectionNone) {
        [self mdc_finalizePosition];
        return;
    }
    
    // Moves the view to the minimum point exceeding the threshold.
    // Transforms and executes pan callbacks as well.
    void (^animations)(void) = ^{
        CGPoint translation = [self mdc_translationExceedingThreshold:self.threshold
                                                            direction:direction];
        self.center = MDCCGPointAdd(self.center, translation);
        [self mdc_rotateForTranslation:translation
                     rotationDirection:MDCRotationAwayFromCenter];
        [self mdc_executeOnPanBlockForTranslation:translation];
    };
    
    // Finalize upon completion of the animations.
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) { [self mdc_finalizePosition]; }
    };
    
    [UIView animateWithDuration:self.mdc_options.swipeAnimationDuration
                          delay:0.0
                        options:self.mdc_options.swipeAnimationOptions
                     animations:animations
                     completion:completion];
}

#pragma mark Translation

- (void)mdc_finalizePosition {
    MDCSwipeDirection direction = [self mdc_directionOfExceededThreshold];
    switch (direction) {
        case MDCSwipeDirectionRight:
        case MDCSwipeDirectionLeft: {
            CGPoint translation = MDCCGPointSubtract(self.center,
                                                     self.mdc_viewState.originalCenter);
            [self mdc_exitSuperviewFromTranslation:translation];
            break;
        }
        case MDCSwipeDirectionNone:
            [self mdc_returnToOriginalCenter];
            [self mdc_executeOnPanBlockForTranslation:CGPointZero];
            break;
    }
}

- (void)mdc_returnToOriginalCenter {
    [UIView animateWithDuration:self.mdc_options.swipeCancelledAnimationDuration
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:self.mdc_options.swipeCancelledAnimationOptions
                     animations:^{
                         self.layer.transform = self.mdc_viewState.originalTransform;
                         self.center = self.mdc_viewState.originalCenter;
                     } completion:^(BOOL finished) {
                         id<MDCSwipeToChooseDelegate> delegate = self.mdc_options.delegate;
                         if ([delegate respondsToSelector:@selector(viewDidCancelSwipe:)]) {
                             [delegate viewDidCancelSwipe:self];
                         }
                     }];
}

- (void)mdc_exitSuperviewFromTranslation:(CGPoint)translation {
    MDCSwipeDirection direction = [self mdc_directionOfExceededThreshold];
    id<MDCSwipeToChooseDelegate> delegate = self.mdc_options.delegate;
    if ([delegate respondsToSelector:@selector(view:shouldBeChosenWithDirection:)]) {
        BOOL should = [delegate view:self shouldBeChosenWithDirection:direction];
        if (!should) {
            [self mdc_returnToOriginalCenter];
            if (self.mdc_options.onCancel != nil){
                self.mdc_options.onCancel(self);
            }
            return;
        }
    }
    
    MDCSwipeResult *state = [MDCSwipeResult new];
    state.view = self;
    state.translation = translation;
    state.direction = direction;
    state.onCompletion = ^{
        if ([delegate respondsToSelector:@selector(view:wasChosenWithDirection:)]) {
            [delegate view:self wasChosenWithDirection:direction];
        }
    };
    self.mdc_options.onChosen(state);
}

- (void)mdc_executeOnPanBlockForTranslation:(CGPoint)translation {
    if (self.mdc_options.onPan) {
        CGFloat thresholdRatio = MIN(1.f, fabsf(translation.x)/self.mdc_options.threshold);
        
        MDCSwipeDirection direction = MDCSwipeDirectionNone;
        if (translation.x > 0.f) {
            direction = MDCSwipeDirectionRight;
        } else if (translation.x < 0.f) {
            direction = MDCSwipeDirectionLeft;
        }
        
        MDCPanState *state = [MDCPanState new];
        state.view = self;
        state.direction = direction;
        state.thresholdRatio = thresholdRatio;
        self.mdc_options.onPan(state);
    }
}

#pragma mark Rotation

- (void)mdc_rotateForTranslation:(CGPoint)translation
               rotationDirection:(MDCRotationDirection)rotationDirection {
    CGFloat rotation = MDCDegreesToRadians(translation.x/100 * self.mdc_options.rotationFactor);
    self.layer.transform = CATransform3DMakeRotation(rotationDirection * rotation, 0.0, 0.0, 1.0);
}

#pragma mark Threshold

- (CGPoint)mdc_translationExceedingThreshold:(CGFloat)threshold
                                   direction:(MDCSwipeDirection)direction {
    NSParameterAssert(direction != MDCSwipeDirectionNone);
    
    CGFloat offset = threshold + 1.f;
    switch (direction) {
        case MDCSwipeDirectionLeft:
            return CGPointMake(-offset, 0);
        case MDCSwipeDirectionRight:
            return CGPointMake(offset, 0);
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invallid direction argument."];
            return CGPointZero;
    }
}

- (MDCSwipeDirection)mdc_directionOfExceededThreshold {
    if (self.center.x > self.mdc_viewState.originalCenter.x + self.mdc_options.threshold) {
        return MDCSwipeDirectionRight;
    } else if (self.center.x < self.mdc_viewState.originalCenter.x - self.mdc_options.threshold) {
        return MDCSwipeDirectionLeft;
    } else {
        return MDCSwipeDirectionNone;
    }
}

@end
