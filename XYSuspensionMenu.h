//
//  SuspensionView.h
//  SuspensionView
//
//  Created by xiaoyuan on 17/2/25.
//  Copyright © 2017年 alpface All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SuspensionViewLeanEdgeType) {
    SuspensionViewLeanEdgeTypeHorizontal = 1,
    SuspensionViewLeanEdgeTypeEachSide
};

@class SuspensionView, SuspensionMenuView, MenuBarHypotenuseButton, HypotenuseAction;

#pragma mark *** Protocol ***

@protocol SuspensionViewDelegate <NSObject>

@optional
/// 拖动suspensionView时回调
- (void)suspensionView:(SuspensionView *)suspensionView locationChange:(UIPanGestureRecognizer *)pan;
/// 根据此方法返回的坐标设置suspensionView的最终的center
- (CGPoint)leanToNewTragetPosionForSuspensionView:(SuspensionView *)suspensionView;
/// 手指拖动suspensionView结束后，它最终根据上下左右的距离计算其接近那个边距比较近，最终停靠在最近的边缘
- (void)suspensionView:(SuspensionView *)suspensionView didAutoLeanToTargetPosition:(CGPoint)position;
- (void)suspensionView:(SuspensionView *)suspensionView willAutoLeanToTargetPosition:(CGPoint)position;

@end

@protocol SuspensionMenuViewDelegate <NSObject>

@optional
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedHypotenuseButtonAtIndex:(NSInteger)buttonIndex;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedMoreButtonAtIndex:(NSInteger)buttonIndex fromHypotenuseItem:(HypotenuseAction *)hypotenuseItem;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView clickedCenterButton:(SuspensionView *)centerButton;
- (void)suspensionMenuViewDidOpened:(SuspensionMenuView *)suspensionMenuView;
- (void)suspensionMenuViewDidClose:(SuspensionMenuView *)suspensionMenuView;
- (void)suspensionMenuView:(SuspensionMenuView *)suspensionMenuView centerButtonLocationChange:(UIPanGestureRecognizer *)pan;


@end

@protocol XYSuspensionWindowProtocol <NSObject>
- (UIWindow *)xy_window;
- (void)xy_removeWindow;
@end

#pragma mark *** SuspensionView ***

@interface SuspensionView : UIButton <XYSuspensionWindowProtocol>

@property (nonatomic, weak, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak, nullable) id<SuspensionViewDelegate> delegate;
@property (nonatomic, assign) SuspensionViewLeanEdgeType leanEdgeType;
@property (nonatomic, assign) UIEdgeInsets leanEdgeInsets;
@property (nonatomic, assign, readonly) BOOL isMoving;
@property (nonatomic, assign, getter=isAutoLeanEdge) BOOL autoLeanEdge;
@property (nonatomic, assign) BOOL shouldLeanToPreviousPositionWhenAppStart;
@property (nonatomic, assign, getter=isAllowMoe) BOOL allowMove;
@property (nonatomic, assign, readonly) CGPoint previousCenter;
/// 当屏幕旋转时反转坐标
@property (nonatomic, assign) BOOL needReversePoint;
/// 移动移动到屏幕中心位置
- (void)moveToDisplayCenter;
/// 移动到上一次停靠的位置
- (void)moveToPreviousLeanPosition;
- (void)checkTargetPosition;
/// 自动移动到边缘，此方法在手指松开后会自动移动到目标位置
- (void)autoLeanToTargetPosition:(CGPoint)point animated:(BOOL)animated;

/// 界面方向发生改变，子类可重写此方法，进行布局
- (void)didChangeInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end


#pragma mark *** SuspensionMenuView ***

@interface SuspensionMenuView : UIView <XYSuspensionWindowProtocol>
@property (nonatomic, weak, nullable) id<SuspensionMenuViewDelegate> delegate;
@property (nonatomic, weak, readonly) UIImageView *backgroundImageView;
@property (nonatomic, weak, readonly) HypotenuseAction *currentResponderItem;
@property (nonatomic, strong, readonly) SuspensionView *centerButton;
@property (nonatomic, copy) void (^ _Nullable menuBarClickBlock)(NSInteger index);
@property (nonatomic, copy) void (^ _Nullable moreButtonClickBlock)(NSInteger index);
@property (nonatomic, assign) BOOL shouldLeanToScreenCenterWhenOpened;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *menuBarItems;
@property (nonatomic, assign) CGFloat usingSpringWithDamping;
@property (nonatomic, assign) CGFloat initialSpringVelocity;
@property (nonatomic, assign) BOOL shouldHiddenCenterButtonWhenOpen;
@property (nonatomic, assign) BOOL shouldCloseWhenDeviceOrientationDidChange;
@property (nonatomic, strong, readonly) UIWindow *xy_window;

- (instancetype)initWithFrame:(CGRect)frame itemSize:(CGSize)itemSize NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)showWithCompetion:(void (^ _Nullable)(void))competion;

- (void)addAction:(HypotenuseAction *)action;

- (void)showViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)open;
- (void)openWithCompetion:(void (^ _Nullable)(BOOL finished))competion;
- (void)close;
- (void)closeWithCompetion:(void (^ _Nullable)(BOOL finished))competion;
@end

#pragma mark *** SuspensionMenuWindow ***

@interface XYSuspensionMenu : SuspensionMenuView

@property (nonatomic, assign) BOOL shouldOpenWhenViewWillAppear;

+ (instancetype)menuWindowWithFrame:(CGRect)frame itemSize:(CGSize)itemSize;

@end

#pragma mark *** HypotenuseAction ***

@interface HypotenuseAction : NSObject

@property (nonatomic, strong, readonly) UIButton *hypotenuseButton;
@property (nonatomic, strong, readonly) NSArray<HypotenuseAction *> *moreHypotenusItems;
@property (nonatomic, assign) CGRect orginRect;
+ (instancetype)actionWithType:(UIButtonType)buttonType
                       handler:(void (^__nullable)(HypotenuseAction *action, SuspensionMenuView *menuView))handler;
- (void)addMoreAction:(HypotenuseAction *)action;

@end

#pragma mark *** UIWindow (SuspensionWindow) ***

@interface UIWindow (SuspensionWindow)

@property (nonatomic, strong, nullable) SuspensionView *suspensionView;
@property (nonatomic, strong, nullable) SuspensionMenuView *suspensionMenuView;

@end

@interface UIApplication (XYSuspensionMenuExtension)

- (nullable XYSuspensionMenu *)xy_suspensionMenu;
- (nullable UIWindow *)xy_suspensionCenterWindow;
@end

NS_ASSUME_NONNULL_END



