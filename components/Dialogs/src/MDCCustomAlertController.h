//
//  MDCCustomAlertController.h
//  MaterialComponents
//
//  Created by typark on 2017. 11. 14..
//  Copyright © 2017년 typark. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MDCAlertController.h"

@interface MDCCustomAlertController : UIViewController
    
+ (nonnull instancetype)alertControllerWithTitle:(nullable NSString *)title
                                         customview:(nullable UIView *)customview;
    
    /** Alert controllers must be created with alertControllerWithTitle:message: */
- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                                 bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
    
    /** Alert controllers must be created with alertControllerWithTitle:message: */
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_UNAVAILABLE;
    
    
- (void)addAction:(nonnull MDCAlertAction *)action;
    
    
@property(nonatomic, nonnull, readonly) NSArray<MDCAlertAction *> *actions;

@property(nonatomic, nullable, copy) NSString *title;

@property(nonatomic, readwrite, setter=mdc_setAdjustsFontForContentSizeCategory:)
BOOL mdc_adjustsFontForContentSizeCategory UI_APPEARANCE_SELECTOR;
    
    /** MDCAlertController handles its own transitioning delegate. */
- (void)setTransitioningDelegate:
(_Nullable id<UIViewControllerTransitioningDelegate>)transitioningDelegate NS_UNAVAILABLE;
    
    /** MDCAlertController.modalPresentationStyle is always UIModalPresentationCustom. */
- (void)setModalPresentationStyle:(UIModalPresentationStyle)modalPresentationStyle NS_UNAVAILABLE;
    
    @end
