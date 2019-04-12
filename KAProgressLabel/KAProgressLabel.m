//
//  KAProgressLabel.m
//  KAProgressLabel
//
//  Created by Alex on 09/06/13.
//  Copyright (c) 2013 Alexis Creuzot. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "KAProgressLabel.h"

#define KADegreesToRadians(degrees) ((degrees)/180.0*M_PI)
#define KARadiansToDegrees(radians) ((radians)*180.0/M_PI)

@implementation KAProgressLabel {
    TPPropertyAnimation *_currentStartDegreeAnimation;
    TPPropertyAnimation *_currentEndDegreeAnimation;
}

@synthesize startDegree = _startDegree;
@synthesize endDegree = _endDegree;
@synthesize progress = _progress;

#pragma mark Core

+ (NSArray<NSString *> *) observedProperties
{
    return @[@"trackWidth",
             @"progressWidth",
             @"fillColor",
             @"trackColor",
             @"progressColor",
             @"shouldUseLineCap",
             @"showStartElipse",
             @"startElipseFillColor",
             @"startElipseBorderColor",
             @"startElipseBorderWidth",
             @"showEndElipse",
             @"endElipseFillColor",
             @"endElipseBorderColor",
             @"endElipseBorderWidth",
             @"startDegree",
             @"endDegree",
             @"roundedCornersWidth"];
}

- (void) dealloc
{
    // KVO
    for (NSString * observedProperty in [KAProgressLabel observedProperties]) {
        [self removeObserver:self forKeyPath:observedProperty];
    }

    [self.startLabel removeObserver:self forKeyPath:@"text"];
    [self.endLabel removeObserver:self forKeyPath:@"text"];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self baseInit];
    }
    return self;
}

-(void)baseInit
{
    // Logic
    _startDegree        = 0;
    _endDegree          = 0;
    _progress           = 0;

    // We need a square view
    // For now, we resize  and center the view
    if(self.frame.size.width != self.frame.size.height){
        CGRect frame = self.frame;
        float delta = ABS(self.frame.size.width-self.frame.size.height)/2;
        if(self.frame.size.width > self.frame.size.height){
            frame.origin.x += delta;
            frame.size.width = self.frame.size.height;
            self.frame = frame;
        }else{
            frame.origin.y += delta;
            frame.size.height = self.frame.size.width;
            self.frame = frame;
        }
    }
    [self setUserInteractionEnabled:YES];

    // Style
    self.textAlignment = NSTextAlignmentCenter;
    _trackWidth             = 5.0;
    _progressWidth          = 5.0;
    _roundedCornersWidth    = 0.0;
    _fillColor              = [UIColor clearColor];
    _trackColor             = [UIColor lightGrayColor];
    _progressColor          = [UIColor blackColor];
    _shouldUseLineCap       = NO;
    _showStartElipse        = YES;
    _showEndElipse          = YES;

    _startLabel = [[UILabel  alloc] initWithFrame:CGRectZero];
    _startLabel.textAlignment = NSTextAlignmentCenter;
    _startLabel.adjustsFontSizeToFitWidth = YES;
    _startLabel.minimumScaleFactor = .1;
    _startLabel.clipsToBounds = YES;

    _endLabel = [[UILabel  alloc] initWithFrame:CGRectZero];
    _endLabel.textAlignment = NSTextAlignmentCenter;
    _endLabel.adjustsFontSizeToFitWidth = YES;
    _endLabel.minimumScaleFactor = .1;
    _endLabel.clipsToBounds = YES;

    [self addSubview:self.startLabel];
    [self addSubview:self.endLabel];

    // KVO
    for (NSString * observedProperty in [KAProgressLabel observedProperties]) {
        [self addObserver:self forKeyPath:observedProperty options:NSKeyValueObservingOptionNew context:nil];
    }
    [self.startLabel addObserver:self forKeyPath:@"text"   options:NSKeyValueObservingOptionNew context:nil];
    [self.endLabel addObserver:self forKeyPath:@"text"    options:NSKeyValueObservingOptionNew context:nil];
}

-(void)drawRect:(CGRect)rect
{
    [self drawProgressLabelCircleInRect:self.bounds];
    [super drawTextInRect:self.bounds];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self setNeedsDisplay] ;

    if([keyPath isEqualToString:@"startDegree"] ||
       [keyPath isEqualToString:@"endDegree"]){

        KAProgressLabel *__unsafe_unretained weakSelf = self;
        if(self.labelVCBlock) {
            self.labelVCBlock(weakSelf);
        }
    }
}

#pragma mark - Getters

- (float) radius
{
    return MIN(self.frame.size.width,self.frame.size.height)/2;
}

- (CGFloat)startDegree
{
    return _startDegree + 90;
}

- (CGFloat)endDegree
{
    return _endDegree + 90;
}

- (CGFloat)progress
{
    return self.endDegree/360;
}

#pragma mark - Setters

-(void)setStartDegree:(CGFloat)startDegree
{
    if (self.endDegree < 0.0f && startDegree > 0.0f){
        _startDegree = startDegree - 90 - 360;
    } else {
        _startDegree = startDegree - 90;
    }
}

-(void)setEndDegree:(CGFloat)endDegree
{
    if (self.endDegree < 0.0f && endDegree > 0.0f){
        _endDegree = endDegree - 90 - 360;
    } else {
        _endDegree = endDegree - 90;
    }
}

-(void)setProgress:(CGFloat)progress
{
    [self setStartDegree:0];
    [self setEndDegree:progress*360];
}

#pragma mark - Animations

-(void)setStartDegree:(CGFloat)startDegree timing:(TPPropertyAnimationTiming)timing duration:(CGFloat)duration delay:(CGFloat)delay
{
    TPPropertyAnimation *animation = [TPPropertyAnimation propertyAnimationWithKeyPath:@"startDegree"];
    animation.delegate = self;
    animation.fromValue = @(_startDegree+90);
    animation.toValue = @(startDegree);
    animation.duration = duration;
    animation.startDelay = delay;
    animation.timing = timing;
    [animation beginWithTarget:self];

    _currentStartDegreeAnimation = animation;
}

-(void)setEndDegree:(CGFloat)endDegree timing:(TPPropertyAnimationTiming)timing duration:(CGFloat)duration delay:(CGFloat)delay
{
    TPPropertyAnimation *animation = [TPPropertyAnimation propertyAnimationWithKeyPath:@"endDegree"];
    animation.delegate = self;
    animation.fromValue = @(_endDegree+90);
    animation.toValue = @(endDegree);
    animation.duration = duration;
    animation.startDelay = delay;
    animation.timing = timing;
    [animation beginWithTarget:self];

    _currentEndDegreeAnimation = animation;
}

-(void)setProgress:(CGFloat)progress timing:(TPPropertyAnimationTiming)timing duration:(CGFloat)duration delay:(CGFloat)delay
{
    [self setStartDegree:0];
    [self setEndDegree:(progress*360) timing:timing duration:duration delay:delay];
}

- (void) stopAnimations
{
    if (_currentStartDegreeAnimation != nil) {
        [_currentStartDegreeAnimation cancel];
        _currentStartDegreeAnimation = nil;
    }
    if (_currentEndDegreeAnimation != nil) {
        [_currentEndDegreeAnimation cancel];
        _currentEndDegreeAnimation = nil;
    }
}

- (void)propertyAnimationDidFinish:(TPPropertyAnimation*)propertyAnimation
{
    _currentStartDegreeAnimation = nil;
    _currentEndDegreeAnimation = nil;

    if (self.labelAnimCompleteBlock) {
        self.labelAnimCompleteBlock(self);
    }
}

#pragma mark - Touch Interaction

// Limit touch to actual disc surface
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01) {
        return nil;
    }
    UIBezierPath *p = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    return  ([p containsPoint:point])? self : nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self moveBasedOnTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self moveBasedOnTouches:touches withEvent:event];
}

- (void)moveBasedOnTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    // No interaction enabled
    if(!self.isStartDegreeUserInteractive &&
       !self.isEndDegreeUserInteractive){
        return;
    }

    UITouch * touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];

    // Coordinates to polar
    float x = touchLocation.x - self.frame.size.width/2;
    float y = touchLocation.y - self.frame.size.height/2;
    int angle = KARadiansToDegrees(atan(y/x));
    angle += (x>=0)?  90 : 270;
    
    // Interact
    if(!self.isStartDegreeUserInteractive) // Only End
    {
        [self setEndDegree:angle];
    }
    else if(!self.isEndDegreeUserInteractive) // Only Start
    {
        [self setStartDegree:angle];
    }
    else // All,hence move nearest knob
    {
        float startDelta = sqrt(pow(self.startLabel.center.x-touchLocation.x,2) + pow(self.startLabel.center.y- touchLocation.y,2));
        float endDelta = sqrt(pow(self.endLabel.center.x-touchLocation.x,2) + pow(self.endLabel.center.y - touchLocation.y,2));
        if(startDelta<endDelta){
            [self setStartDegree:angle];
        }else{
            [self setEndDegree:angle];
        }
    }
}

#pragma mark - Drawing

-(void)drawProgressLabelCircleInRect:(CGRect)rect
{
    CGRect circleRect= [self rectForCircle:rect];
    CGFloat archXPos = rect.size.width/2 + rect.origin.x;
    CGFloat archYPos = rect.size.height/2 + rect.origin.y;
    CGFloat archRadius = (circleRect.size.width) / 2.0;

    if(isnan(_endDegree)){
        self.endDegree = 0;
    }

    if(isnan(_startDegree)){
        self.startDegree = 0;
    }
    
    int clockwise = 0;
    if (self.progress < 0.0f) {
        clockwise = 1;
    }

    CGFloat trackStartAngle = KADegreesToRadians(0);
    CGFloat trackEndAngle = KADegreesToRadians(360);
    CGFloat progressStartAngle = KADegreesToRadians(_startDegree);
    CGFloat progressEndAngle = KADegreesToRadians(_endDegree);

    CGContextRef context = UIGraphicsGetCurrentContext();

    // Circle
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    CGContextFillEllipseInRect(context, circleRect);
    if (self.shouldUseLineCap) CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokePath(context);

    // Track
    CGContextSetStrokeColorWithColor(context, self.trackColor.CGColor);
    CGContextSetLineWidth(context, _trackWidth);
    CGContextAddArc(context, archXPos,archYPos, archRadius, trackStartAngle, trackEndAngle, 1);
    CGContextStrokePath(context);

    // Progress
    CGContextSetStrokeColorWithColor(context, self.progressColor.CGColor);
    CGContextSetLineWidth(context, _progressWidth);
    CGContextAddArc(context, archXPos, archYPos, archRadius, progressStartAngle, progressEndAngle, clockwise);
    CGContextStrokePath(context);

    // Rounded corners
    if (_roundedCornersWidth > 0 && self.progress != 0.0f && (_showStartElipse || _showEndElipse)) {
        if (self.showStartElipse) {
            CGColorRef fillColor = self.startElipseFillColor?self.startElipseFillColor.CGColor:self.progressColor.CGColor;
            CGContextSetFillColorWithColor(context, fillColor);
            CGContextAddEllipseInRect(context, [self rectForDegree:_startDegree andRect:rect]);
            CGContextFillPath(context);
            
            if (self.startElipseBorderWidth>0) {
                CGColorRef borderColor = self.startElipseBorderColor?self.startElipseBorderColor.CGColor:self.progressColor.CGColor;
                CGContextSetStrokeColorWithColor(context, borderColor);
                CGContextSetLineWidth(context, self.startElipseBorderWidth);
                CGContextAddEllipseInRect(context, [self rectForDegree:_startDegree andRect:rect andBorder:_startElipseBorderWidth]);
                CGContextStrokePath(context);
            }
        }
        if (self.showEndElipse) {
            CGColorRef fillColor = self.endElipseFillColor?self.endElipseFillColor.CGColor:self.progressColor.CGColor;
            CGContextSetFillColorWithColor(context, fillColor);
            CGContextAddEllipseInRect(context, [self rectForDegree:_endDegree andRect:rect]);
            CGContextFillPath(context);
            
            if (self.endElipseBorderWidth>0) {
                CGColorRef borderColor = self.endElipseBorderColor?self.endElipseBorderColor.CGColor:self.progressColor.CGColor;
                CGContextSetStrokeColorWithColor(context, borderColor);
                CGContextSetLineWidth(context, self.endElipseBorderWidth);
                CGContextAddEllipseInRect(context, [self rectForDegree:_endDegree andRect:rect andBorder:_endElipseBorderWidth]);
                CGContextStrokePath(context);
            }
        }
    }

    self.startLabel.frame =  [self rectForDegree:_startDegree andRect:rect];
    self.endLabel.frame =  [self rectForDegree:_endDegree andRect:rect];
    self.startLabel.layer.cornerRadius = [self borderDelta];
    self.endLabel.layer.cornerRadius = [self borderDelta];
}

#pragma mark - Helpers

- (CGRect) rectForDegree:(float) degree andRect:(CGRect) rect
{
    return [self rectForDegree:degree andRect:rect andBorder:0];
}

- (CGRect) rectForDegree:(float) degree andRect:(CGRect) rect andBorder:(CGFloat) border
{
    float offset = border;
    float x = [self xPosRoundForAngle:degree andRect:rect] - _roundedCornersWidth/2 + offset/2;
    float y = [self yPosRoundForAngle:degree andRect:rect] - _roundedCornersWidth/2 + offset/2;
    return CGRectMake(x, y, _roundedCornersWidth - offset, _roundedCornersWidth - offset);
}

- (float) xPosRoundForAngle:(float) degree andRect:(CGRect) rect
{
    return cosf(KADegreesToRadians(degree))* [self radius]
    - cosf(KADegreesToRadians(degree)) * [self borderDelta]
    + rect.size.width/2;
}

- (float) yPosRoundForAngle:(float) degree andRect:(CGRect) rect
{
    return sinf(KADegreesToRadians(degree))* [self radius]
    - sinf(KADegreesToRadians(degree)) * [self borderDelta]
    + rect.size.height/2;
}

- (float) borderDelta
{
    return MAX(MAX(_trackWidth,_progressWidth),_roundedCornersWidth)/2;
}

-(CGRect)rectForCircle:(CGRect)rect
{
    CGFloat minDim = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat circleRadius = (minDim / 2) - [self borderDelta];
    CGPoint circleCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    return CGRectMake(circleCenter.x - circleRadius, circleCenter.y - circleRadius, 2 * circleRadius, 2 * circleRadius);
}

@end
