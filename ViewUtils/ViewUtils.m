//
//  ViewUtils.m
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

#import "ViewUtils.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma GCC diagnostic ignored "-Wgnu"


@implementation UIView (ViewUtils)

//nib loading

+ (id)instanceWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundleOrNil owner:(id)owner
{
    //default values
    NSString *nibName = nibNameOrNil ?: NSStringFromClass(self);
    NSBundle *bundle = bundleOrNil ?: [NSBundle mainBundle];
    
    //cache nib to prevent unnecessary filesystem access
    static NSCache *nibCache = nil;
    if (nibCache == nil)
    {
        nibCache = [[NSCache alloc] init];
    }
    NSString *pathKey = [NSString stringWithFormat:@"%@.%@", bundle.bundleIdentifier, nibName];
    UINib *nib = [nibCache objectForKey:pathKey];
    if (nib == nil)
    {
        NSString *nibPath = [bundle pathForResource:nibName ofType:@"nib"];
        if (nibPath) nib = [UINib nibWithNibName:nibName bundle:bundle];
        [nibCache setObject:nib ?: [NSNull null] forKey:pathKey];
    }
    else if ([nib isKindOfClass:[NSNull class]])
    {
        nib = nil;
    }
    
    if (nib)
    {
        //attempt to load from nib
        NSArray *contents = [nib instantiateWithOwner:owner options:nil];
        UIView *view = [contents count]? [contents objectAtIndex:0]: nil;
        NSAssert ([view isKindOfClass:self], @"First object in nib '%@' was '%@'. Expected '%@'", nibName, view, self);
        return view;
    }
    
    //return empty view
    return [[[self class] alloc] init];
}

- (void)loadContentsWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundleOrNil
{
    NSString *nibName = nibNameOrNil ?: NSStringFromClass([self class]);
    UIView *view = [UIView instanceWithNibName:nibName bundle:bundleOrNil owner:self];
    if (view)
    {
        if (CGSizeEqualToSize(self.frame.size, CGSizeZero))
        {
            //if we have zero size, set size from content
            self.size = view.size;
        }
        else
        {
            //otherwise set content size to match our size
            view.frame = self.contentBounds;
        }
        [self addSubview:view];
    }
}

+ (instancetype)loadViewWithNibName:(NSString *)name {
    NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:name owner:self options:nil];
    return nibs[0];
}

//view searching

- (UIView *)viewMatchingPredicate:(NSPredicate *)predicate
{
    if ([predicate evaluateWithObject:self])
    {
        return self;
    }
    for (UIView *view in self.subviews)
    {
        UIView *match = [view viewMatchingPredicate:predicate];
        if (match) return match;
    }
    return nil;
}

- (UIView *)viewWithTag:(NSInteger)tag ofClass:(Class)viewClass
{
    return [self viewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused NSDictionary *bindings) {
        return [evaluatedObject tag] == tag && [evaluatedObject isKindOfClass:viewClass];
    }]];
}

- (UIView *)viewOfClass:(Class)viewClass
{
    return [self viewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:viewClass];
    }]];
}

- (NSArray *)viewsMatchingPredicate:(NSPredicate *)predicate
{
    NSMutableArray *matches = [NSMutableArray array];
    if ([predicate evaluateWithObject:self])
    {
        [matches addObject:self];
    }
    for (UIView *view in self.subviews)
    {
        //check for subviews
        //avoid creating unnecessary array
        if ([view.subviews count])
        {
        	[matches addObjectsFromArray:[view viewsMatchingPredicate:predicate]];
        }
        else if ([predicate evaluateWithObject:view])
        {
            [matches addObject:view];
        }
    }
    return matches;
}

- (NSArray *)viewsWithTag:(NSInteger)tag
{
    return [self viewsMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused id bindings) {
        return [evaluatedObject tag] == tag;
    }]];
}

- (NSArray *)viewsWithTag:(NSInteger)tag ofClass:(Class)viewClass
{
    return [self viewsMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused id bindings) {
        return [evaluatedObject tag] == tag && [evaluatedObject isKindOfClass:viewClass];
    }]];
}

- (NSArray *)viewsOfClass:(Class)viewClass
{
    return [self viewsMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused id bindings) {
        return [evaluatedObject isKindOfClass:viewClass];
    }]];
}

- (UIView *)firstSuperviewMatchingPredicate:(NSPredicate *)predicate
{
    if ([predicate evaluateWithObject:self])
    {
        return self;
    }
    return [self.superview firstSuperviewMatchingPredicate:predicate];
}

- (UIView *)firstSuperviewOfClass:(Class)viewClass
{
    return [self firstSuperviewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *superview, __unused id bindings) {
        return [superview isKindOfClass:viewClass];
    }]];
}

- (UIView *)firstSuperviewWithTag:(NSInteger)tag
{
    return [self firstSuperviewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *superview, __unused id bindings) {
        return superview.tag == tag;
    }]];
}

- (UIView *)firstSuperviewWithTag:(NSInteger)tag ofClass:(Class)viewClass
{
    return [self firstSuperviewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *superview, __unused id bindings) {
        return superview.tag == tag && [superview isKindOfClass:viewClass];
    }]];
}

- (BOOL)viewOrAnySuperviewMatchesPredicate:(NSPredicate *)predicate
{
    if ([predicate evaluateWithObject:self])
    {
        return YES;
    }
    return [self.superview viewOrAnySuperviewMatchesPredicate:predicate];
}

- (BOOL)viewOrAnySuperviewIsKindOfClass:(Class)viewClass
{
    return [self viewOrAnySuperviewMatchesPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *superview, __unused id bindings) {
        return [superview isKindOfClass:viewClass];
    }]];
}

- (BOOL)isSuperviewOfView:(UIView *)view
{
    return [self firstSuperviewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *superview, __unused id bindings) {
        return superview == view;
    }]] != nil;
}

- (BOOL)isSubviewOfView:(UIView *)view
{
    return [view isSuperviewOfView:self];
}

- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView *child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}

//responder chain

- (UIViewController *)firstViewController
{
    id responder = self;
    while ((responder = [responder nextResponder]))
    {
        if ([responder isKindOfClass:[UIViewController class]])
        {
            return responder;
        }
    }
    return nil;
}

- (UIView *)firstResponder
{
    return [self viewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __unused id bindings) {
        return [evaluatedObject isFirstResponder];
    }]];
}

//frame accessors

- (CGPoint)origin
{
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)top
{
    return self.origin.y;
}

- (void)setTop:(CGFloat)top
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)left
{
    return self.origin.x;
}

- (void)setLeft:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)right
{
    return self.left + self.width;
}

- (void)setRight:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom
{
    return self.top + self.height;
}

- (void)setBottom:(CGFloat)bottom
{
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)width
{
    return self.size.width;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.size.height;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY
{
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)minX
{
    return CGRectGetMinX(self.frame);
}

- (CGFloat)midX
{
    return CGRectGetMidX(self.frame);
}

- (CGFloat)maxX
{
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)minY
{
    return CGRectGetMinY(self.frame);
}

- (CGFloat)midY
{
    return CGRectGetMidY(self.frame);
}

- (CGFloat)maxY
{
    return CGRectGetMaxY(self.frame);
}

- (CGFloat)width_2
{
    return self.size.width / 2.0;
}

- (CGFloat)height_2
{
    return self.size.height / 2.0;
}

//bounds accessors

- (CGSize)boundsSize
{
    return self.bounds.size;
}

- (void)setBoundsSize:(CGSize)size
{
    CGRect bounds = self.bounds;
    bounds.size = size;
    self.bounds = bounds;
}

- (CGFloat)boundsWidth
{
    return self.boundsSize.width;
}

- (void)setBoundsWidth:(CGFloat)width
{
    CGRect bounds = self.bounds;
    bounds.size.width = width;
    self.bounds = bounds;
}

- (CGFloat)boundsHeight
{
    return self.boundsSize.height;
}

- (void)setBoundsHeight:(CGFloat)height
{
    CGRect bounds = self.bounds;
    bounds.size.height = height;
    self.bounds = bounds;
}

//content getters

- (CGRect)contentBounds
{
    return CGRectMake(0.0f, 0.0f, self.boundsWidth, self.boundsHeight);
}

- (CGPoint)contentCenter
{
    return CGPointMake(self.boundsWidth/2.0f, self.boundsHeight/2.0f);
}

#pragma mark - Border & Radius
- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.clipsToBounds = YES;
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor {
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth color:(UIColor *)borderColor {
    self.layer.borderWidth = borderWidth;
    self.layer.borderColor = borderColor.CGColor;
}

//additional frame setters

- (void)setLeft:(CGFloat)left right:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    frame.size.width = right - left;
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width right:(CGFloat)right
{
    CGRect frame = self.frame;
    frame.origin.x = right - width;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setTop:(CGFloat)top bottom:(CGFloat)bottom
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    frame.size.height = bottom - top;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height bottom:(CGFloat)bottom
{
    CGRect frame = self.frame;
    frame.origin.y = bottom - height;
    frame.size.height = height;
    self.frame = frame;
}

//animation

- (void)crossfadeWithDuration:(NSTimeInterval)duration
{
    //jump through a few hoops to avoid QuartzCore framework dependency
    CAAnimation *animation = [NSClassFromString(@"CATransition") animation];
    [animation setValue:@"kCATransitionFade" forKey:@"type"];
    animation.duration = duration;
    [self.layer addAnimation:animation forKey:nil];
}

- (void)crossfadeWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    [self crossfadeWithDuration:duration];
    if (completion)
    {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
        dispatch_after(time, dispatch_get_main_queue(), completion);
    }
}

//add sub-views
- (void)addTopLineWithColor:(UIColor *)color width:(CGFloat)width {
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, width)];
    topLine.backgroundColor = color;
    [self addSubview:topLine];
}

- (void)addTopLineWithColor:(UIColor *)color {
    [self addTopLineWithColor:color width:1.0];
}

- (void)addBottomLineWithColor:(UIColor *)color width:(CGFloat)width {
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.height - 1.0, self.width, 1.0)];
    bottomLine.backgroundColor = color;
    [self addSubview:bottomLine];
}

- (void)addBottomLineWithColor:(UIColor *)color {
    [self addBottomLineWithColor:color width:1.0];
}

- (void)addLeftLineWithColor:(UIColor *)color width:(CGFloat)width {
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0, self.height)];
    bottomLine.backgroundColor = color;
    [self addSubview:bottomLine];
}

- (void)addLeftLineWithColor:(UIColor *)color {
    [self addLeftLineWithColor:color width:1.0];
}

- (void)addRightLineWithColor:(UIColor *)color width:(CGFloat)width {
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(self.width - 1.0, 0, 1.0, self.height)];
    bottomLine.backgroundColor = color;
    [self addSubview:bottomLine];
}

- (void)addRightLineWithColor:(UIColor *)color {
    [self addRightLineWithColor:color width:1.0];
}

- (void)addSeparateLineWithColor:(UIColor *)color row:(NSUInteger)row column:(NSUInteger)column {
    if (row < 2 && column < 2) {
        return;
    }
    
    CGFloat width = floorf(self.width / column);
    CGFloat height = floorf(self.height / row);
    
    for (NSInteger i = 1; i < column; i++) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(width * i, 0, 0.5, self.height)];
        line.backgroundColor = color;
        [self addSubview:line];
    }
    
    for (NSInteger i = 1; i < row; i++) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, height * i, self.width, 0.5)];
        line.backgroundColor = color;
        [self addSubview:line];
    }
}

@end

@implementation UILabel (ViewUtils)

- (void)setFontSize:(CGFloat)fontSize {
    objc_setAssociatedObject(self, &"AYFontSizeKey", @(fontSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.font = [UIFont systemFontOfSize:fontSize];
}

- (CGFloat)fontSize {
    return [objc_getAssociatedObject(self, &"AYFontSizeKey") floatValue];
}

- (void)widthToFit {
    self.width = [self sizeOfTextWithMaxWidth:[UIScreen mainScreen].bounds.size.width].width;
}

- (CGSize)sizeOfTextWithMaxWidth:(CGFloat)maxWidth {
    if (self.text.length == 0) {
        return CGSizeZero;
    }
    
    NSDictionary *attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:self.fontSize]};
    
    CGSize labelSize = [self.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading |NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
    
    return CGSizeMake(ceilf(labelSize.width), ceilf(labelSize.height));
}

@end

