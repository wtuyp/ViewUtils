//
//  ViewUtils.h
//
//  Version 1.1.2
//
//  Created by Nick Lockwood on 19/11/2011.
//  Copyright (c) 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/ViewUtils
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#import <UIKit/UIKit.h>

@interface UIView (ViewUtils)

//nib loading

+ (id)instanceWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundleOrNil owner:(id)owner;
- (void)loadContentsWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundleOrNil;
+ (instancetype)loadViewWithNibName:(NSString *)name;

//hierarchy

- (UIView *)viewMatchingPredicate:(NSPredicate *)predicate;
- (UIView *)viewWithTag:(NSInteger)tag ofClass:(Class)viewClass;
- (UIView *)viewOfClass:(Class)viewClass;
- (NSArray *)viewsMatchingPredicate:(NSPredicate *)predicate;
- (NSArray *)viewsWithTag:(NSInteger)tag;
- (NSArray *)viewsWithTag:(NSInteger)tag ofClass:(Class)viewClass;
- (NSArray *)viewsOfClass:(Class)viewClass;

- (UIView *)firstSuperviewMatchingPredicate:(NSPredicate *)predicate;
- (UIView *)firstSuperviewOfClass:(Class)viewClass;
- (UIView *)firstSuperviewWithTag:(NSInteger)tag;
- (UIView *)firstSuperviewWithTag:(NSInteger)tag ofClass:(Class)viewClass;

- (BOOL)viewOrAnySuperviewMatchesPredicate:(NSPredicate *)predicate;
- (BOOL)viewOrAnySuperviewIsKindOfClass:(Class)viewClass;
- (BOOL)isSuperviewOfView:(UIView *)view;
- (BOOL)isSubviewOfView:(UIView *)view;
- (void)removeAllSubviews;

- (UIViewController *)firstViewController;
- (UIView *)firstResponder;

//frame accessors

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat right;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

@property (nonatomic, readonly) CGFloat minX;
@property (nonatomic, readonly) CGFloat midX;
@property (nonatomic, readonly) CGFloat maxX;
@property (nonatomic, readonly) CGFloat minY;
@property (nonatomic, readonly) CGFloat midY;
@property (nonatomic, readonly) CGFloat maxY;

@property (nonatomic, readonly) CGFloat width_2;    // width / 2.0
@property (nonatomic, readonly) CGFloat height_2;   // height / 2.0

//bounds accessors

@property (nonatomic, assign) CGSize boundsSize;
@property (nonatomic, assign) CGFloat boundsWidth;
@property (nonatomic, assign) CGFloat boundsHeight;

//content getters

@property (nonatomic, readonly) CGRect contentBounds;
@property (nonatomic, readonly) CGPoint contentCenter;

//layer accessors
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;

- (void)setBorderWidth:(CGFloat)borderWidth color:(UIColor *)borderColor;

//additional frame setters

- (void)setLeft:(CGFloat)left right:(CGFloat)right;
- (void)setWidth:(CGFloat)width right:(CGFloat)right;
- (void)setTop:(CGFloat)top bottom:(CGFloat)bottom;
- (void)setHeight:(CGFloat)height bottom:(CGFloat)bottom;

//animation

- (void)crossfadeWithDuration:(NSTimeInterval)duration;
- (void)crossfadeWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

//add sub-views
- (void)addTopLineWithColor:(UIColor *)color;
- (void)addBottomLineWithColor:(UIColor *)color;
- (void)addLeftLineWithColor:(UIColor *)color;
- (void)addRightLineWithColor:(UIColor *)color;

- (void)addTopLineWithColor:(UIColor *)color width:(CGFloat)width;
- (void)addBottomLineWithColor:(UIColor *)color width:(CGFloat)width;
- (void)addLeftLineWithColor:(UIColor *)color width:(CGFloat)width;
- (void)addRightLineWithColor:(UIColor *)color width:(CGFloat)width;

- (void)addSeparateLineWithColor:(UIColor *)color row:(NSUInteger)row column:(NSUInteger)column;


@end

@interface UILabel (ViewUtils)

@property (nonatomic, assign) CGFloat fontSize;

- (void)widthToFitTextWidth;     //max width is screen width
- (CGSize)sizeOfTextWithMaxWidth:(CGFloat)maxWidth;

@end
