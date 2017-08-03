//
//  MLSwipeableView.h
//  MLSwipeableViewDemo
//
//  Created by Zhixuan Lai on 11/1/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MLPanState;
@class MLSwipeResult;

typedef NS_ENUM(NSInteger, MLSwipeDirection) {
    MLSwipeDirectionNone = 0,
    MLSwipeDirectionLeft,
    MLSwipeDirectionRight
};

typedef CGFloat MLRotationDirection;
extern const MLRotationDirection MDCRotationAwayFromCenter;
extern const MLRotationDirection MDCRotationTowardsCenter;

typedef void (^MDCSwipeToChooseOnPanBlock)(MLPanState *state);
typedef void (^MDCSwipeToChooseOnChosenBlock)(MLSwipeResult *state);
typedef void (^MDCSwipeToChooseOnCancelBlock)(UIView *swipedView);

@class MLSwipeableView;
// Delegate
@protocol MLSwipeableViewDelegate <NSObject>
@optional
- (BOOL)swipeableView: (MLSwipeableView *)swipeableView willSwipeLeft:(UIView *)view;
- (BOOL)swipeableView: (MLSwipeableView *)swipeableView willSwipeRight:(UIView *)view;
- (void)swipeableView: (MLSwipeableView *)swipeableView didSwipeLeft:(UIView *)view;
- (void)swipeableView: (MLSwipeableView *)swipeableView didSwipeRight:(UIView *)view;
- (void)swipeableView: (MLSwipeableView *)swipeableView swipingView:(UIView *)view atLocation:(CGPoint)location;
- (void)swipeableView: (MLSwipeableView *)swipeableView swipingView:(UIView *)view atLocation:(CGPoint)location panState:(MLPanState *)panState;
- (void)swipeableViewdidEndSwipe:(MLSwipeableView *)swipeableView swipingView:(UIView *)view;
@end

/*!
 * An object representing the state of the current pan gesture.
 * This is provided as an argument to `MDCSwipeToChooseOnPanBlock` callbacks.
 */
@interface MLPanState : NSObject

/*!
 * The view being panned.
 */
@property (nonatomic, strong) UIView *view;

/*!
 * The direction of the current pan. Note that a direction of `MDCSwipeDirectionRight`
 * does not imply that the threshold has been reached.
 */
@property (nonatomic, assign) MLSwipeDirection direction;

/*!
 * The ratio of the threshold that has been reached. This can take on any value
 * between `0.0f` and `1.0f`, with `1.0f` meaning the threshold has been reached.
 * A `thresholdRatio` of `1.0f` implies that were the user to end the pan gesture,
 * the current direction would be chosen.
 */
@property (nonatomic, assign) CGFloat thresholdRatio;

@end

typedef void (^MLSwipedOnCompletionBlock)(void);

/*!
 * An object representing the result of a swipe.
 * This is provided as an argument to `MDCSwipeToChooseOnChosenBlock` callbacks.
 */
@interface MLSwipeResult : NSObject

/*!
 * The view that was swiped.
 */
@property (nonatomic, strong) UIView *view;

/*!
 * The translation of the swiped view; i.e.: the distance it has been panned
 * from its original location.
 */
@property (nonatomic, assign) CGPoint translation;

/*!
 * The final direction of the swipe.
 */
@property (nonatomic, assign) MLSwipeDirection direction;

/*!
 * A callback to be executed after any animations performed by the `MDCSwipeOptions`
 * `onChosen` callback.
 */
@property (nonatomic, copy) MLSwipedOnCompletionBlock onCompletion;

@end

// DataSource
@protocol MLSwipeableViewDataSource <NSObject>
@required
- (UIView *)nextViewForSwipeableView:(MLSwipeableView *)swipeableView;
@end

@interface MLSwipeableView : UIView
@property (nonatomic, weak) id <MLSwipeableViewDataSource> dataSource;
@property (nonatomic, weak) id <MLSwipeableViewDelegate> delegate;

/**
 *  Enable this to rotate the views behind the top view. Default to YES.
 */
@property (nonatomic) BOOL isRotationEnabled;
/**
 *  Relative vertical offset of the center of rotation. From 0 to 1. Default to 0.3.
 */
@property (nonatomic) float rotationRelativeYOffsetFromCenter;
/**
 *  Magnitude in points per second.
 */
@property (nonatomic) CGFloat escapeVelocityThreshold;
/**
 *  Center of swipable Views. This property is animated.
 */
@property (nonatomic) CGPoint swipeableViewsCenter;

// 视图view
@property (strong, nonatomic) UIView *containerView;
/**
 *  Discard all swipeable views on the screen.
 */
-(void)discardAllSwipeableViews;
/**
 *  Load up to 3 swipeable views.
 */
-(void)loadNextSwipeableViewsIfNeeded;
/**
 *  Swipe top view to the left programmatically
 */
-(void)swipeTopViewToLeft;
/**
 *  Swipe top view to the right programmatically
 */
-(void)swipeTopViewToRight;

- (UIView *)topSwipeableView;

/*!
 * The duration of the animation that occurs when a swipe is cancelled. By default, this
 * animation simply slides the view back to its original position. A default value is
 * provided in the `-init` method.
 */
@property (nonatomic, assign) NSTimeInterval swipeClosedAnimationDuration;

/*!
 * Animation options for the swipe-cancelled animation. Default values are provided in the
 * `-init` method.
 */
@property (nonatomic, assign) UIViewAnimationOptions swipeClosedAnimationOptions;


/*!
 * The duration of the animation that occurs when a swipe is cancelled. By default, this
 * animation simply slides the view back to its original position. A default value is
 * provided in the `-init` method.
 */
@property (nonatomic, assign) NSTimeInterval swipeCancelledAnimationDuration;

/*!
 * Animation options for the swipe-cancelled animation. Default values are provided in the
 * `-init` method.
 */
@property (nonatomic, assign) UIViewAnimationOptions swipeCancelledAnimationOptions;

/*!
 * THe duration of the animation that moves a view to its threshold, caused when `mdc_swipe:`
 * is called. A default value is provided in the `-init` method.
 */
@property (nonatomic, assign) NSTimeInterval swipeAnimationDuration;

/*!
 * Animation options for the animation that moves a view to its threshold, caused when
 * `mdc_swipe:` is called. A default value is provided in the `-init` method.
 */
@property (nonatomic, assign) UIViewAnimationOptions swipeAnimationOptions;

/*!
 * The distance, in points, that a view must be panned in order to constitue a selection.
 * For example, if the `threshold` is `100.f`, panning the view `101.f` points to the right
 * is considered a selection in the `MDCSwipeDirectionRight` direction. A default value is
 * provided in the `-init` method.
 */
@property (nonatomic, assign) CGFloat threshold;

/*!
 * When a view is panned, it is rotated slightly. Adjust this value to increase or decrease
 * the angle of rotation.
 */
@property (nonatomic, assign) CGFloat rotationFactor;

/*!
 * A callback to be executed when the view is panned. The block takes an instance of
 * `MDCPanState` as an argument. Use this `state` instance to determine the pan direction
 * and the distance until the threshold is reached.
 */
@property (nonatomic, copy) MDCSwipeToChooseOnPanBlock onPan;

/*!
 * A callback to be executed when the view is swiped and the swipe is cancelled
 (i.e. because view:shouldBeChosen: delegate callback returned NO for swiped view).
 The view that was swiped is passed into this block so that you can restore its
 state in this callback. May be nil.
 */
@property (nonatomic, copy) MDCSwipeToChooseOnCancelBlock onCancel;

@end

