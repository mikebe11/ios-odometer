#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface OdometerView : UIView

@property (strong, nonatomic, nullable) NSNumberFormatter *formatter;
@property (strong, nonatomic) UIFont *font;
@property (nonatomic) BOOL useFormatter;
@property (nonatomic) BOOL useLeadingZeros;

- (id)initWithFrame:(CGRect)frame duration:(NSNumber *)duration digitColorRGBA:(int [_Nonnull])digitColorRGBA borderColorRGBA:(int [_Nonnull])borderColorRGBA;

- (void)setupNumber:(int)number targetNumber:(int)target;

- (int)stopOdometerAndGetValue;

@end
NS_ASSUME_NONNULL_END
