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
    return [self viewMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *evaluatedObject, __unused NSDictionary *bindings) {
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
    return [self viewsMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *evaluatedObject, __unused id bindings) {
        return [evaluatedObject tag] == tag;
    }]];
}

- (NSArray *)viewsWithTag:(NSInteger)tag ofClass:(Class)viewClass
{
    return [self viewsMatchingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *evaluatedObject, __unused id bindings) {
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

- (void)removeAllSubviewsWithClass:(Class)class {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:class]) {
            [view removeFromSuperview];
        }
    }
}

- (void)removeAllLayers {
    while (self.layer.sublayers.count) {
        CALayer *layer = self.layer.sublayers.lastObject;
        [layer removeFromSuperlayer];
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

- (UIImage *)snapshotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates {
    if (![self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        return [self snapshotImage];
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:afterUpdates];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (NSData *)snapshotPDF {
    CGRect bounds = self.bounds;
    NSMutableData *data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
    CGContextRef context = CGPDFContextCreate(consumer, &bounds, NULL);
    CGDataConsumerRelease(consumer);
    if (!context) return nil;
    CGPDFContextBeginPage(context, NULL);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self.layer renderInContext:context];
    CGPDFContextEndPage(context);
    CGPDFContextClose(context);
    CGContextRelease(context);
    return data;
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
    self.clipsToBounds = (cornerRadius > 0.0);
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
- (void)addTopLineWithColor:(UIColor *)color height:(CGFloat)height {
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, height)];
    topLine.backgroundColor = color;
    [self addSubview:topLine];
}

- (void)addTopLineWithColor:(UIColor *)color {
    [self addTopLineWithColor:color height:1.0];
}

- (void)addBottomLineWithColor:(UIColor *)color height:(CGFloat)height {
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.height - height, self.width, height)];
    bottomLine.backgroundColor = color;
    [self addSubview:bottomLine];
}

- (void)addBottomLineWithColor:(UIColor *)color {
    [self addBottomLineWithColor:color height:1.0];
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

@implementation UIView (AYGesture)

- (void)tapGestureWithBlock:(void (^)(UIView *selfView))block {
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(tapGestureAction)];
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    objc_setAssociatedObject(self, @selector(tapGestureAction), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)tapGestureAction {
    void(^_touchBlock)(UIView *selfView) = objc_getAssociatedObject(self, _cmd);
    __weak typeof(self) weakSelf = self;
    if (_touchBlock) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        _touchBlock(strongSelf);
    }
}

- (void)longPressGestureWithBlock:(void (^)(UIView *selfView))block {
    self.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
    longPressGesture.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPressGesture];
    objc_setAssociatedObject(self, @selector(longPressGestureAction:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)longPressGestureAction:(UIGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        void(^_touchBlock)(UIView *selfView) = objc_getAssociatedObject(self, _cmd);
        __weak typeof(self) weakSelf = self;
        if (_touchBlock) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            _touchBlock(strongSelf);
        }
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

- (void)fitTextWidth:(NSString *)text {
    self.text = text;
    self.width = [self sizeOfTextWithMaxWidth:HUGE].width;
}

- (CGSize)sizeOfTextWithMaxWidth:(CGFloat)maxWidth {
    if (self.text.length == 0) {
        return CGSizeMake(0, self.bounds.size.height);
    }
    
    NSDictionary *attributes = @{NSFontAttributeName : self.font ? : [UIFont systemFontOfSize:12]};
    
    CGSize labelSize = [self.text boundingRectWithSize:CGSizeMake(maxWidth, HUGE)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine
                                            attributes:attributes context:nil].size;
    
    return CGSizeMake(ceilf(labelSize.width), ceilf(labelSize.height));
}

@end

@implementation UITableView (ViewUtils)

- (void)registerClass:(Class)cellClass {
    [self registerClass:cellClass forCellReuseIdentifier:NSStringFromClass(cellClass)];
}



@end

@implementation UIScrollView (ViewUtils)

- (void)scrollToTop {
    [self scrollToTopAnimated:YES];
}

- (void)scrollToBottom {
    [self scrollToBottomAnimated:YES];
}

- (void)scrollToLeft {
    [self scrollToLeftAnimated:YES];
}

- (void)scrollToRight {
    [self scrollToRightAnimated:YES];
}

- (void)scrollToTopAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.y = 0 - self.contentInset.top;
    [self setContentOffset:off animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.y = MAX(self.contentSize.height - self.bounds.size.height + self.contentInset.bottom, 0.0);
    [self setContentOffset:off animated:animated];
}

- (void)scrollToLeftAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.x = 0 - self.contentInset.left;
    [self setContentOffset:off animated:animated];
}

- (void)scrollToRightAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
    [self setContentOffset:off animated:animated];
}

- (void)setContentHeight:(CGFloat)height {
    self.alwaysBounceVertical = YES;
    self.contentSize = CGSizeMake(self.width, MAX(height, self.height));
}

- (void)endRefreshing {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:NSSelectorFromString(@"mj_header")]) {
        [[self performSelector:NSSelectorFromString(@"mj_header")] performSelectorOnMainThread:NSSelectorFromString(@"endRefreshing") withObject:nil waitUntilDone:NO];
    }
    if ([self respondsToSelector:NSSelectorFromString(@"mj_footer")]) {
        [[self performSelector:NSSelectorFromString(@"mj_footer")] performSelectorOnMainThread:NSSelectorFromString(@"endRefreshing") withObject:nil waitUntilDone:NO];
    }
#pragma clang diagnostic pop
}

@end
