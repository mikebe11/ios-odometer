#import "ViewController.h"
#import "OdometerView.h"

@interface ViewController ()

@property (nonatomic, strong) OdometerView *odometerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
// Saved for future implementation of formatted numbers
//    [numberFormatter setGroupingSeparator:@","];
//    [numberFormatter setGroupingSize:3];
//    [numberFormatter setUsesGroupingSeparator:YES];
//    [numberFormatter setGeneratesDecimalNumbers:YES];
//    [numberFormatter setDecimalSeparator:@"."];
//    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//    [numberFormatter setMaximumFractionDigits:2];
    
    CGFloat fontSize = 48;
    
    // {red , green, blue, alpha} 0 - 255
    int digitColorRGBA[4] = {0, 0, 0, 255};
    
    // {red , green, blue, alpha} 0 - 255
    int borderColorRGBA[4] = {0, 0, 0, 255};
    
    // 0 - 255
    int backgroundColorRed = 255;
    int backgroundColorGreen = 255;
    int backgroundColorBlue = 255;
    
    self.odometerView = [[OdometerView alloc]
                         initWithFrame:CGRectZero
                         duration:[NSNumber numberWithFloat:.3]
                         digitColorRGBA:digitColorRGBA
                         borderColorRGBA:borderColorRGBA];
    self.odometerView.font = [UIFont systemFontOfSize:fontSize];
    self.odometerView.backgroundColor = [UIColor
                                         colorWithRed:(float)(backgroundColorRed / 255)
                                         green:(float)(backgroundColorGreen / 255)
                                         blue:(float)(backgroundColorBlue / 255)
                                         alpha:1.0];
    self.odometerView.formatter = numberFormatter;
    self.odometerView.useFormatter = NO;
    self.odometerView.alpha = 0.0;
    self.odometerView.useLeadingZeros = NO;
    
    [self.view addSubview:self.odometerView];
    
    self.odometerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.odometerView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.odometerView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    
    [self.view addConstraints:@[centerX, centerY]];
    
    [self.odometerView setupNumber:983 targetNumber:1008];
}

@end
