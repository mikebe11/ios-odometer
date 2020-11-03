#import "OdometerView.h"

static NSString *const kAnimationKey = @"odometerAnimationKey";

@implementation OdometerView {
    
    // Array of each digit in the starting number
    NSMutableArray<NSString *> *_startingNumberArray;
    
    // Array of scrollable unit counter layers
    NSMutableArray<CALayer *> *_scrollLayers;
    
    // Font data
    NSCache *_fontSizeCache;
    NSDictionary<NSAttributedStringKey,id> *_attributes;
    
    // User supplied start and end numbers
    float _startNumber;
    float _endNumber;
    
    // Length, in seconds, that the rightmost counter should scroll one digit
    float _duration;
    
    // Run animation flag
    BOOL _isAnimationRunning;
    
    // Max y value of the rightmost scroll layer
    CGFloat _maxY;
    
    // Single digit height
    int _characterHeight;
    
    // Number of times (end number - start number) the rightmost counter should scroll
    int _totalScrollIterations;
    
    // Digit color
    float _digitColorRGBA[4];
    
    // Outline colors
    float _borderColorRGBA[4];
    
    // Use leading zeros when the target value has more digits than the start value
    BOOL _useLeadingZeros;
}

- (void)setFont:(UIFont *)font {
    
    if (_font != font) {
        _font = font;
        _attributes = @{NSFontAttributeName: self.font};
        [_fontSizeCache removeAllObjects];
    }
}

- (id)initWithFrame:(CGRect)frame duration:(NSNumber *)duration digitColorRGBA:(int[4])digitColorRGBA borderColorRGBA:(int[4])borderColorRGBA {
    
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit:duration.floatValue digitColorRGBA:digitColorRGBA borderColorRGBA:borderColorRGBA];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder duration:(NSNumber *)duration digitColorRGBA:(int[4])digitColorRGBA borderColorRGBA:(int[4])borderColorRGBA {
    
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit:duration.floatValue digitColorRGBA:digitColorRGBA borderColorRGBA:borderColorRGBA];
    }

    return self;
}

- (void)commonInit:(float)duration digitColorRGBA:(int [4])digitColorRGBA borderColorRGBA:(int [4])borderColorRGBA {
    
    self.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
    _isAnimationRunning = YES;
    
    _startingNumberArray = [NSMutableArray arrayWithCapacity:8];
    
    _scrollLayers = [NSMutableArray arrayWithCapacity:11];
    
    _fontSizeCache = [[NSCache alloc] init];
    
    _maxY = 0;
    
    _duration = duration;
    
    _digitColorRGBA[0] = (float)digitColorRGBA[0] / 255; // red
    _digitColorRGBA[1] = (float)digitColorRGBA[1] / 255; // green
    _digitColorRGBA[2] = (float)digitColorRGBA[2] / 255; // blue
    _digitColorRGBA[3] = (float)digitColorRGBA[3] / 255; // alpha
    
    _borderColorRGBA[0] = (float)borderColorRGBA[0] / 255; // red
    _borderColorRGBA[1] = (float)borderColorRGBA[1] / 255; // green
    _borderColorRGBA[2] = (float)borderColorRGBA[2] / 255; // blue
    _borderColorRGBA[3] = (float)borderColorRGBA[3] / 255; // alpha
    
    _useLeadingZeros = self.useLeadingZeros;
}

- (int)stopOdometerAndGetValue {
    
    _isAnimationRunning = NO;

    return [self getCurrentValue];
}

// Get the current value of the stopped odometer
- (int)getCurrentValue {
    
    CALayer *layer;
    int runningTotal = 0;
    int x = 1;
    NSNumber *y;

    for (int index = (int)_scrollLayers.count - 1; index >= 0; index--) {
        layer = _scrollLayers[index];
        
        y = [layer.presentationLayer valueForKeyPath:@"sublayerTransform.translation.y"];

// This segment is no longer used now that animations are allowed to finish
//    before stopping but kept here in case that functionality is brought back.
//        CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
//        layer.speed = 0.0;
//        layer.timeOffset = pausedTime;
        
        if (layer.sublayers.count == 11) {
            int unitCounterValue = (int)ceilf(y.floatValue * -1 / _characterHeight);
            
            if (unitCounterValue != 10) {
                runningTotal += (unitCounterValue * x);
            }
            x *= 10;
        } else if (y.floatValue != 0.0) {
            int unitCounterValue = (int)ceilf(y.floatValue * -1 / _characterHeight);
            runningTotal += (unitCounterValue * x);
        }
    }
    
    return runningTotal;
}

- (void)setupNumber:(int)number targetNumber:(int)target {
    
    _startNumber = number;
    _endNumber = target;
    _totalScrollIterations = target - number;
    
    [self getTextSizes];
    
    [self prepareUnitCounters];

    [self setInitialScrollValues];
}

- (void)prepareUnitCounters {
    
    for (CALayer *layer in _scrollLayers) {
        [layer removeFromSuperlayer];
    }
    
    NSString *formattedStartNumberString = [self getFormattedNumberString:_startNumber];
    NSString *formattedEndingNumberString = [self getFormattedNumberString:_endNumber];
    
    // How many more digits that the target value has than the start value
    int fillXLength = (int)(formattedEndingNumberString.length - formattedStartNumberString.length);

    if (fillXLength > 0) {
        // Prepend the formatted number string with "x" placeholders
        
        NSString *leadingCharacter;
        
        if (_useLeadingZeros) {
            leadingCharacter = @"0%@";
        } else {
            leadingCharacter = @"x%@";
        }
        
        for (int i = 0; i < fillXLength; i++) {
            formattedStartNumberString = [NSString stringWithFormat:leadingCharacter, formattedStartNumberString];
        }
    }

    CGRect lastFrame = CGRectZero;
    for (int i = 0; i < [formattedEndingNumberString length]; i++) {
        NSString *startDigitString = [formattedStartNumberString substringWithRange:NSMakeRange(i, 1)];
        NSString *endingDigitString = [formattedEndingNumberString substringWithRange:NSMakeRange(i, 1)];
                             
        bool isStartingCharacterANumber = [self isTheStringANumber:startDigitString];
        
        NSValue *value = isStartingCharacterANumber ? [_fontSizeCache objectForKey:@"8"] : [_fontSizeCache objectForKey:@","];
        
        CGSize stringSize = value.CGSizeValue;
        
        CGFloat width = stringSize.width;
        CGFloat height = stringSize.height;
        
        CAScrollLayer *layer = [CAScrollLayer layer];
        
        // Create a non-scrolling text layer if the character isn't a digit
        if (!isStartingCharacterANumber) {
            CATextLayer *layer = [CATextLayer layer];
            layer.string = startDigitString;
        }
        
        layer.frame = CGRectMake(CGRectGetMaxX(lastFrame), CGRectGetMinY(lastFrame), width, height);
        
        lastFrame = layer.frame;
        layer.borderWidth = 1;
        layer.borderColor = [UIColor colorWithRed:_borderColorRGBA[0] green:_borderColorRGBA[1] blue:_borderColorRGBA[2] alpha:_borderColorRGBA[3]].CGColor;
        
        // Add numeric layers to scrollLayers array
        if (isStartingCharacterANumber) {
            layer.scrollMode = kCAScrollVertically;
            [_scrollLayers addObject:layer];
            [_startingNumberArray addObject:startDigitString];
        }
        
        [self.layer addSublayer:layer];
        
        [self createContentForLayer:layer withStartDigitString:startDigitString withEndingDigitString:endingDigitString];
    }
}

- (void)createContentForLayer:(CALayer *)scrollLayer withStartDigitString:(nullable NSString *)startDigitString withEndingDigitString:(NSString *)endingDigitString {
    
    NSMutableArray<NSString*> *textForScroll = [NSMutableArray array];
    
    BOOL startDigitIsNumber = [self isTheStringANumber:startDigitString];
    
    if ([startDigitString isEqual:@"x"]) {
        // When the target number has more digits than the start number prepend the odometer with a blank and fill with 1 - 9
        [textForScroll addObject:@" "];
        
        for (int x = 1; x < 10; x++) {
            [textForScroll addObject:[NSString stringWithFormat:@"%d", x]];
        }
    } else if (startDigitIsNumber) {
        for (int i = 0; i <= 10; i++) {
            [textForScroll addObject:[NSString stringWithFormat:@"%d", i % 10]];
        }
    } else {
        // Add non-digit character to layer
        [textForScroll addObject:startDigitString];
    }
        
    CGFloat mainScreenScale = [UIScreen mainScreen].scale;
    CGFloat offSetY = 0;
    for (NSString *text in textForScroll) {
        CGRect frame = CGRectMake(0, offSetY, CGRectGetWidth(scrollLayer.frame), CGRectGetHeight(scrollLayer.frame));
        CATextLayer *layer = [self getTextLayer:text];
        layer.contentsScale = mainScreenScale;
        layer.frame = frame;
        
        if (startDigitIsNumber) {
            // Add borders to numbers so we see the line between digits as it scrolls
            layer.borderWidth = 1;
            layer.borderColor = [UIColor colorWithRed:_borderColorRGBA[0] green:_borderColorRGBA[1] blue:_borderColorRGBA[2] alpha:_borderColorRGBA[3]].CGColor;
        }
        
        [scrollLayer addSublayer:layer];
        
        offSetY = CGRectGetMaxY(frame);
    }
}


// Create two size objects to use for digits and non-digit characters
- (void)getTextSizes {
    
    NSString *chars[2] = {@",", @"8"};
    
    for (int x = 0; x <= 1; x++) {
        NSString *text = chars[x];
        CGSize size = [text sizeWithAttributes:_attributes];
        float width = roundf(size.width);
        float height = roundf(size.height);
        size.width = width + 8;
        size.height = height;
        [_fontSizeCache setObject:[NSValue valueWithCGSize:size] forKey:text];
        
        if (_maxY == 0) {
            _maxY = size.height * -10;
            
            _characterHeight = size.height;
        }
    }
}

// Also include "x" as a digit as it represents the starting spinner without the 0's
- (BOOL)isTheStringANumber:(NSString*)string {
    
    if ([string isEqual:@"x"]) {
        return YES;
    }

    NSScanner *scanNumber = [NSScanner scannerWithString:string];

    return [scanNumber scanInt:0] && [scanNumber isAtEnd];
}

- (CATextLayer *)getTextLayer:(NSString *)text {
    
    CATextLayer *textlayer = [CATextLayer layer];

    CGFontRef fontRef = CGFontCreateWithFontName((__bridge CFStringRef)self.font.fontName);
    textlayer.font = fontRef;
    CGFontRelease(fontRef);

    textlayer.fontSize = self.font.pointSize;
    textlayer.alignmentMode = kCAAlignmentCenter;
    textlayer.string = text;
    textlayer.foregroundColor = [UIColor colorWithRed:_digitColorRGBA[0] green:_digitColorRGBA[1] blue:_digitColorRGBA[2] alpha:_digitColorRGBA[3]].CGColor;

    return textlayer;
}

// Scroll each digit to it's starting value then start the animation
- (void)setInitialScrollValues {
    
    for (int x = 0; x < _scrollLayers.count; x++) {
        float offsetY = [_startingNumberArray[x] intValue] * _characterHeight * -1;
        
        [CATransaction begin];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.translation.y"];
        animation.duration = 0;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.repeatCount = 0;
        
        animation.fromValue = @0;
        animation.toValue = [NSNumber numberWithFloat:offsetY];
        
        [CATransaction setCompletionBlock:^{
            // Wait until the last unit counter has finished scrolling into it's start position before starting the animation
            int leastSignificantDigitIndex = (int)self->_scrollLayers.count - 1;
                        
            if (x == leastSignificantDigitIndex) {
                self.alpha = 1.0;
                
                [self scrollLeastSignificantDigit:leastSignificantDigitIndex Total:self->_totalScrollIterations];
            }
        }];
        
        [_scrollLayers[x] addAnimation:animation forKey:kAnimationKey];
        
        [CATransaction commit];
    }
}

- (void)scrollLeastSignificantDigit:(int)index Total:(int)total {
    
    if (_isAnimationRunning && total > 0) {
        NSNumber *currentOffset = [_scrollLayers[index].presentationLayer valueForKeyPath:@"sublayerTransform.translation.y"];
        
        BOOL removeOnCompletion = NO;
        
        if (ceilf(currentOffset.floatValue - _characterHeight) == _maxY) {
            removeOnCompletion = YES;
        }
        
        [CATransaction begin];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.translation.y"];
        animation.duration = _duration;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.removedOnCompletion = removeOnCompletion;
        animation.fillMode = kCAFillModeForwards;
        animation.repeatCount = 0;
        animation.fromValue = currentOffset;
        animation.toValue = [NSNumber numberWithFloat:(currentOffset.floatValue - _characterHeight)];
        
        [CATransaction setCompletionBlock:^{
            [self scrollLeastSignificantDigit:index Total:(total - 1)];
        }];
        
        [_scrollLayers[index] addAnimation:animation forKey:kAnimationKey];
        
        [CATransaction commit];
        
        if (ceilf(currentOffset.floatValue - _characterHeight) == _maxY) {
            [self scrollOneDigit:(index - 1)];
        }
    }
}

- (void)scrollOneDigit:(int)index {
    
    NSNumber *currentOffset = [_scrollLayers[index].presentationLayer valueForKeyPath:@"sublayerTransform.translation.y"];

    BOOL removeOnCompletion = NO;
    if (ceilf(currentOffset.floatValue - _characterHeight) == _maxY) {
        removeOnCompletion = YES;
    }
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.translation.y"];
    animation.duration = _duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.removedOnCompletion = removeOnCompletion;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = 0;
    animation.fromValue = currentOffset;
    animation.toValue = [NSNumber numberWithFloat:(ceilf(currentOffset.floatValue - _characterHeight))];
    
    [_scrollLayers[index] addAnimation:animation forKey:kAnimationKey];

    if (ceilf(currentOffset.floatValue - _characterHeight) == _maxY) {
        [self scrollOneDigit: index - 1];
    }
}

- (CGSize)intrinsicContentSize {
    
    CGSize superSize = [super intrinsicContentSize];
    
    CGFloat width = 0;
    
    for (int i = 0; i < self.layer.sublayers.count; i++) {
        width += self.layer.sublayers[i].bounds.size.width;
        
        if (i == 0) {
            superSize.height = self.layer.sublayers[i].bounds.size.height;
        }
    }
    
//    for (int i = 0; i < [_value length]; i++) {
//        NSString *subString = [_value substringWithRange:NSMakeRange(i, 1)];
//
//        NSValue *value = [self isTheStringANumber:subString] ? [_fontSizeCache objectForKey:@","] : [_fontSizeCache objectForKey:@"8"];;
//        CGSize stringSize = value.CGSizeValue;
//
//        height = MAX(height, stringSize.height);
//    }
    
    superSize.width = width;
    
    return superSize;
}

// Return the number as the correct string, formatted or as-is
- (NSString *)getFormattedNumberString:(float)aNumber {
    
    return (self.useFormatter && self.formatter) ? [self.formatter stringFromNumber:@(aNumber)] : @(aNumber).stringValue;
}

@end
