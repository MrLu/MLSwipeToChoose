//
//  MLSwipeableView.m
//  MLSwipeableViewDemo
//
//  Created by Zhixuan Lai on 11/1/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import "MLSwipeableView.h"

CGPoint MLCGPointAdd(const CGPoint a, const CGPoint b) {
    return CGPointMake(a.x + b.x,
                       a.y + b.y);
}

CGPoint MLCGPointSubtract(const CGPoint minuend, const CGPoint subtrahend) {
    return CGPointMake(minuend.x - subtrahend.x,
                       minuend.y - subtrahend.y);
}

CGFloat MDCDegreesToRadians(const CGFloat degrees) {
    return degrees * (M_PI/180.0);
}

CGRect MLCGRectExtendedOutOfBounds(const CGRect rect,
                                    const CGRect bounds,
                                    const CGPoint translation,
                                    const NSUInteger direction) {
    CGRect destination = rect;
    while (!CGRectIsNull(CGRectIntersection(bounds, destination))) {
        if (direction>=2) { //XY轴
            destination = CGRectMake(CGRectGetMinX(destination) + translation.x,
                                     CGRectGetMinY(destination) + translation.y,
                                     CGRectGetWidth(destination),
                                     CGRectGetHeight(destination));
        }
        if (direction==0) { //X轴
            destination = CGRectMake(CGRectGetMinX(destination) + translation.x,
                                     CGRectGetMinY(destination),
                                     CGRectGetWidth(destination),
                                     CGRectGetHeight(destination));
        }
        if (direction==1) { //Y轴
            destination = CGRectMake(CGRectGetMinX(destination),
                                     CGRectGetMinY(destination) + translation.y,
                                     CGRectGetWidth(destination),
                                     CGRectGetHeight(destination));
        }
    }
    
    return destination;
}

typedef CGFloat MLRotationDirection;
const MLRotationDirection MLRotationAwayFromCenter = 1.f;
const MLRotationDirection MLRotationTowardsCenter = -1.f;

static const int numPrefetchedViews = 3;

@implementation MLPanState

@end


@implementation MLSwipeResult

@end


@interface MLSwipeableView ()

// ContainerView
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
@property (nonatomic, assign) MLRotationDirection rotationDirection;

@end

@implementation MLSwipeableView

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

-(void)setup {
    self.swipeClosedAnimationDuration = 0.25;
    self.swipeClosedAnimationOptions = UIViewAnimationOptionCurveEaseOut;
    self.swipeCancelledAnimationDuration = 0.5;
    self.swipeCancelledAnimationOptions = UIViewAnimationOptionCurveEaseOut;
    self.swipeAnimationDuration = 0.15;
    self.swipeAnimationOptions = UIViewAnimationOptionCurveEaseInOut;
    self.rotationFactor = 3.f;
    self.threshold = self.bounds.size.width/2;
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.containerView];
    
    // Default properties
    self.isRotationEnabled = YES;
    self.rotationRelativeYOffsetFromCenter = 0.3;
    
    self.escapeVelocityThreshold = 650;

    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.containerView.frame = self.bounds;
    self.swipeableViewsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

-(void)setSwipeableViewsCenter:(CGPoint)swipeableViewsCenter {
    _swipeableViewsCenter = swipeableViewsCenter;
    [self animateSwipeableViewsIfNeeded];
}

- (void)setupPanGestureRecognizer {
    SEL action = @selector(handlePan:);
    UIPanGestureRecognizer *panGestureRecognizer =
    [[UIPanGestureRecognizer alloc] initWithTarget:self
                                            action:action];
    [self addGestureRecognizer:panGestureRecognizer];
}

#pragma mark - Properties
- (void)setDataSource:(id<MLSwipeableViewDataSource>)dataSource {
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
            // 下一张的布局
            nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y+CGRectGetHeight(nextView.frame)/2.*0.05+10);
            nextView.transform = CGAffineTransformMakeScale(0.95, 0.95);
            [newViews addObject:nextView];
        }
    }
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
                                options: UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
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
            [self rotateView:self.containerView.subviews[numSwipeableViews-2] forDegree:self.rotationFactor atOffsetFromCenter:rotationCenterOffset animated:YES];
            return;
        }
        if (numSwipeableViews>=3) {
            [self rotateView:self.containerView.subviews[numSwipeableViews-3] forDegree:-self.rotationFactor atOffsetFromCenter:rotationCenterOffset animated:YES];
            return;
        }
    }
}

#pragma mark - Action
-(void)handlePan:(UIPanGestureRecognizer *)recognizer {
    UIView *swipeableView = recognizer.view;
    
    #pragma mark 下一张卡片变化
    CGFloat base = CGRectGetWidth(self.frame) / 2.;

    CGFloat move = fabs(base-swipeableView.center.x);
    CGFloat max = 70.f;
    
    CGFloat ratio = move / max;
    if (ratio > 1) {
        ratio = 1;
    }
    
    UIView *nextView = [self getNextSwipeableView:swipeableView];
    if (nextView) {
        nextView.transform = CGAffineTransformMakeScale(0.95+0.05*ratio, 0.95+0.05*ratio);
        nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y+(CGRectGetHeight(nextView.frame)/2.*0.05+10)*(1-ratio));
    }
    
    UIView *view = recognizer.view;
    CGPoint translation = [recognizer translationInView:view];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.originalCenter = view.center;
        self.originalTransform = view.layer.transform;
        
        // If the pan gesture originated at the top half of the view, rotate the view
        // away from the center. Otherwise, rotate towards the center.
        if ([recognizer locationInView:view].y < view.center.y) {
            self.rotationDirection = MLRotationAwayFromCenter;
        } else {
            self.rotationDirection = MLRotationTowardsCenter;
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded ||
               recognizer.state == UIGestureRecognizerStateCancelled ||
               recognizer.state == UIGestureRecognizerStateFailed) {
        // Either move the view back to its original position or move it off screen.
        CGPoint velocity = [recognizer velocityInView:self];
        CGFloat velocityMagnitude = sqrt(pow(velocity.x,2)+pow(velocity.y,2));
//        CGPoint normalizedVelocity = CGPointMake(velocity.x/velocityMagnitude, velocity.y/velocityMagnitude);
        [self mdc_finalizePosition:(UIView *)view velocity:velocityMagnitude];
    } else {
        // Update the position and transform. Then, notify any listeners of
        // the updates via the pan block.
        view.center = MLCGPointAdd(self.originalCenter, translation);
        [self mdc_rotateForTranslation:translation
                     rotationDirection:self.rotationDirection view:view];
        [self mdc_executeOnPanBlockForTranslation:translation view:view];
    }
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
    if (left) {
        [self mdc_swipe:MLSwipeDirectionLeft view:topSwipeableView];
    } else {
        [self mdc_swipe:MLSwipeDirectionRight view:topSwipeableView];
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
    if (nextView) {
        [nextView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
    }
    return nextView;
}

- (UIView *)getNextSwipeableView:(UIView *)swipeableView {
    UIView *nextView = nil;
    for (UIView *av in self.containerView.subviews) {
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
    return nextView;
}

- (void)rotateView:(UIView*)view forDegree:(float)degree atOffsetFromCenter:(CGPoint)offset animated:(BOOL)animated {
    float duration = animated? 0.4:0;
    NSLog(@"%lf", duration);
    float rotationRadian = [self degreesToRadians:degree];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
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
- (void)mdc_swipe:(MLSwipeDirection)direction view:(UIView *)view {
    // A swipe in no particular direction "finalizes" the swipe.
    if (direction == MLSwipeDirectionNone) {
        [self mdc_finalizePosition:view];
        return;
    }
    self.originalCenter = view.center;
    self.originalTransform = view.layer.transform;
    // Moves the view to the minimum point exceeding the threshold.
    // Transforms and executes pan callbacks as well.
    void (^animations)(void) = ^{
        CGPoint translation = [self mdc_translationExceedingThreshold:self.threshold
                                                            direction:direction view:view];
        view.center = MLCGPointAdd(view.center, translation);
        [self mdc_rotateForTranslation:translation
                     rotationDirection:MLRotationAwayFromCenter view:view];
        [self mdc_executeOnPanBlockForTranslation:translation view:view];
    };
    
    // Finalize upon completion of the animations.
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished) { [self mdc_finalizePosition:view]; }
    };
    
    [UIView animateWithDuration:self.swipeAnimationDuration
                          delay:0.0
                        options:self.swipeAnimationOptions | UIViewAnimationOptionAllowUserInteraction
                     animations:animations
                     completion:completion];
}

#pragma mark Translation
- (void)mdc_finalizePosition:(UIView *)view {
    [self mdc_finalizePosition:view velocity:0];
}

- (void)mdc_finalizePosition:(UIView *)view velocity:(CGFloat)velocity {
    MLSwipeDirection direction = [self mdc_directionOfExceededThreshold:view velocity:velocity];
    switch (direction) {
        case MLSwipeDirectionRight:
        case MLSwipeDirectionLeft: {
            CGPoint translation = MLCGPointSubtract(view.center,
                                                     self.originalCenter);
            [self mdc_exitSuperviewFromTranslation:translation view:view];
            break;
        }
        case MLSwipeDirectionNone:
            [self mdc_returnToOriginalCenter:view];
            [self mdc_executeOnPanBlockForTranslation:CGPointZero view:view];
            break;
    }
}

- (void)mdc_returnToOriginalCenter:(UIView *)view {
    UIView *nextView = [self getNextSwipeableView:view];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y+CGRectGetHeight(nextView.frame)/2.*0.05+10);
        nextView.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:nil];
    
    [UIView animateWithDuration:self.swipeCancelledAnimationDuration
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:self.swipeCancelledAnimationOptions | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.layer.transform = self.originalTransform;
                         view.center = self.originalCenter;
                     } completion:^(BOOL finished) {
                         if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableViewdidEndSwipe:swipingView:)]) {
                             [self.delegate swipeableViewdidEndSwipe:self swipingView:view];
                         }
                     }];
}

- (void)mdc_exitSuperviewFromTranslation:(CGPoint)translation view:(UIView *)view {
    MLSwipeDirection direction = [self mdc_directionOfExceededThreshold:view];
    
    if (direction == MLSwipeDirectionLeft && [self.delegate respondsToSelector:@selector(swipeableView:willSwipeLeft:)]) {
        if (![self.delegate swipeableView:self willSwipeLeft:view]) {
            [self mdc_returnToOriginalCenter:view];
            [self mdc_executeOnPanBlockForTranslation:CGPointZero view:view];
        }
    }
    
    if (direction == MLSwipeDirectionRight && [self.delegate respondsToSelector:@selector(swipeableView:willSwipeRight:)]) {
        if(![self.delegate swipeableView:self willSwipeRight:view]) {
            [self mdc_returnToOriginalCenter:view];
            [self mdc_executeOnPanBlockForTranslation:CGPointZero view:view];
        }
    }
    
    [self exitScreenOnChosenWithDuration:self.swipeClosedAnimationDuration options:self.swipeClosedAnimationDuration translation:translation direction:direction view:view];
}

- (void)mdc_executeOnPanBlockForTranslation:(CGPoint)translation view:(UIView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableView:swipingView:atLocation:panState:)]) {
        CGFloat thresholdRatio = MIN(1.f, fabs(translation.x)/self.threshold);
        
        MLSwipeDirection direction = MLSwipeDirectionNone;
        if (translation.x > 0.f) {
            direction = MLSwipeDirectionRight;
        } else if (translation.x < 0.f) {
            direction = MLSwipeDirectionLeft;
        }
        
        MLPanState *state = [MLPanState new];
        state.view = view;
        state.direction = direction;
        state.thresholdRatio = thresholdRatio;
        [self.delegate swipeableView:self swipingView:view atLocation:translation panState:state];
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(swipeableView:swipingView:atLocation:)]) {
        [self.delegate swipeableView:self swipingView:view atLocation:translation];
    }
}

- (void)exitScreenOnChosenWithDuration:(NSTimeInterval)duration
                               options:(UIViewAnimationOptions)options
                           translation:(CGPoint)translation
                             direction:(MLSwipeDirection)direction
                                  view:(UIView *)view {
    UIView *nextView = [self getNextSwipeableView:view];
    [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionAllowUserInteraction animations:^{
        nextView.center = CGPointMake(self.swipeableViewsCenter.x, self.swipeableViewsCenter.y);
        nextView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    
    CGRect destination = MLCGRectExtendedOutOfBounds(view.frame,
                                                      view.superview.bounds,
                                                      translation,
                                                      2);
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.center = CGPointMake(CGRectGetMidX(destination),
                                                         CGRectGetMidY(destination));
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [view removeFromSuperview];
                             if (direction == MLSwipeDirectionLeft && [self.delegate respondsToSelector:@selector(swipeableView:didSwipeLeft:)]) {
                                 [self.delegate swipeableView:self didSwipeLeft:view];
                             }
                             if (direction == MLSwipeDirectionRight && [self.delegate respondsToSelector:@selector(swipeableView:didSwipeRight:)]) {
                                 [self.delegate swipeableView:self didSwipeRight:view];
                             }
                             [self loadNextSwipeableViewsIfNeeded:NO];
                         }
                     }];
}


#pragma mark Rotation
- (void)mdc_rotateForTranslation:(CGPoint)translation
               rotationDirection:(MLRotationDirection)rotationDirection view:(UIView *)view {
    CGFloat rotation = MDCDegreesToRadians(translation.x/100 * self.rotationFactor);
    view.layer.transform = CATransform3DMakeRotation(rotationDirection * rotation, 0.0, 0.0, 1.0);
}

#pragma mark Threshold
- (CGPoint)mdc_translationExceedingThreshold:(CGFloat)threshold
                                   direction:(MLSwipeDirection)direction view:(UIView *)view {
    NSParameterAssert(direction != MLSwipeDirectionNone);
    
    CGFloat offset = threshold + 10.f;
    switch (direction) {
        case MLSwipeDirectionLeft:
            return CGPointMake(-offset, 0);
        case MLSwipeDirectionRight:
            return CGPointMake(offset, 0);
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invallid direction argument."];
            return CGPointZero;
    }
}

- (MLSwipeDirection)mdc_directionOfExceededThreshold:(UIView *)view{
    return [self mdc_directionOfExceededThreshold:view velocity:0];
}

- (MLSwipeDirection)mdc_directionOfExceededThreshold:(UIView *)view velocity:(CGFloat)velocity{
    if (velocity > self.escapeVelocityThreshold) {
        if (view.center.x > self.originalCenter.x + self.threshold/2) {
            return MLSwipeDirectionRight;
        } else if (view.center.x < self.originalCenter.x - self.threshold/2) {
            return MLSwipeDirectionLeft;
        } else {
            return MLSwipeDirectionNone;
        }
    } else {
        if (view.center.x > self.originalCenter.x + self.threshold) {
            return MLSwipeDirectionRight;
        } else if (view.center.x < self.originalCenter.x - self.threshold) {
            return MLSwipeDirectionLeft;
        } else {
            return MLSwipeDirectionNone;
        }
    }
}

@end
