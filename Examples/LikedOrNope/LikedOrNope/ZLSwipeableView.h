//
//  ZLSwipeableView.h
//  ZLSwipeableViewDemo
//
//  Created by Zhixuan Lai on 11/1/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDCPanState;
@class MDCSwipeResult;

typedef void (^MDCSwipeToChooseOnPanBlock)(MDCPanState *state);
typedef void (^MDCSwipeToChooseOnChosenBlock)(MDCSwipeResult *state);
typedef void (^MDCSwipeToChooseOnCancelBlock)(UIView *swipedView);

typedef CGFloat MDCRotationDirection;
extern const MDCRotationDirection MDCRotationAwayFromCenter;
extern const MDCRotationDirection MDCRotationTowardsCenter;

@class ZLSwipeableView;

// Delegate
@protocol ZLSwipeableViewDelegate <NSObject>
@optional
- (BOOL)swipeableView: (ZLSwipeableView *)swipeableView willSwipeLeft:(UIView *)view;
- (BOOL)swipeableView: (ZLSwipeableView *)swipeableView willSwipeRight:(UIView *)view;
- (void)swipeableView: (ZLSwipeableView *)swipeableView didSwipeLeft:(UIView *)view;
- (void)swipeableView: (ZLSwipeableView *)swipeableView didSwipeRight:(UIView *)view;
- (void)swipeableView: (ZLSwipeableView *)swipeableView swipingView:(UIView *)view atLocation:(CGPoint)location;
- (void)swipeableViewdidEndSwipe:(ZLSwipeableView *)swipeableView swipingView:(UIView *)view;
@end


// DataSource
@protocol ZLSwipeableViewDataSource <NSObject>
@required
- (UIView *)nextViewForSwipeableView:(ZLSwipeableView *)swipeableView;
@end

@interface ZLSwipeableView : UIView
@property (nonatomic, weak) id <ZLSwipeableViewDataSource> dataSource;
@property (nonatomic, weak) id <ZLSwipeableViewDelegate> delegate;

/**
 *  Enable this to rotate the views behind the top view. Default to YES.
 */
@property (nonatomic) BOOL isRotationEnabled;
/**
 *  Magnitude of the rotation in degrees
 */
@property (nonatomic) float rotationDegree;
/**
 *  Relative vertical offset of the center of rotation. From 0 to 1. Default to 0.3.
 */
@property (nonatomic) float rotationRelativeYOffsetFromCenter;
/**
 *  Magnitude in points per second.
 */
@property (nonatomic) CGFloat escapeVelocityThreshold;

@property (nonatomic) CGFloat relativeDisplacementThreshold;
/**
 *  Magnitude of velocity at which the swiped view will be animated.
 */
@property (nonatomic) CGFloat pushVelocityMagnitude;
/**
 *  Center of swipable Views. This property is animated.
 */
@property (nonatomic) CGPoint swipeableViewsCenter;

/**
 *  Mangintude of rotation for swiping views manually
 */
@property (nonatomic) CGFloat manualSwipeRotationRelativeYOffsetFromCenter;
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
 * A callback to be executed when the view is swiped and chosen. The default
 is the block returned by the `-exitScreenOnChosenWithDuration:block:` method.
 
 @warning that this block must execute the `MDCSwipeResult` argument's `onCompletion`
 block in order to properly notify the delegate of the swipe result.
 */
@property (nonatomic, copy) MDCSwipeToChooseOnChosenBlock onChosen;

/*!
 * A callback to be executed when the view is swiped and the swipe is cancelled
 (i.e. because view:shouldBeChosen: delegate callback returned NO for swiped view).
 The view that was swiped is passed into this block so that you can restore its
 state in this callback. May be nil.
 */
@property (nonatomic, copy) MDCSwipeToChooseOnCancelBlock onCancel;

@end

