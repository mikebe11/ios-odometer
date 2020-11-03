# ios-odometer

ios-odometer is an Objective-C library for an odometer type animation

## Example

![](https://github.com/mikebe11/ios-odometer/blob/master/ios-odometer.gif?raw=true)

An example Xcode project can be found in the example folder. The minimum version of Xcode it was tested with was version 11.3.1


## Requirements

\>= ios 12.0 


## Configuration

Add the two OdometerView files to your Xcode project. Create an instance of OdometerView with a duration, digit color, and outline color.

This method sets up the odometer with a start and end value.

    - (void)setupNumber:(int)number targetNumber:(int)target

This method can be called from a button. It will stop the animation and return the current value seen on the odometer.

    - (int)stopOdometerAndGetValue

This table lists some properties shown in the example's ViewController.m file that can be used to customize the look of the odometer.

|property|description|
|--|--|
|digitColorRGBA|4 value integer array {red, green, blue, alpha}|
||value: 0-255|
||default: black|
||ex. {10, 20, 30, 255}|
|borderColorRGBA|4 value integer array {red, green, blue, alpha}|
||value: 0-255|
||default: black|
||ex. {10, 20, 30, 255}|
|fontSize|size in dp|
||default: 48|
|duration|Time, in seconds, for an odometer counter to scroll by 1|
||default: .3|
||If, for example, the odometer is scrolling from 89 to 90, then the 8 and 9 in 89 will individually be set to animate to the next number over 300 milliseconds.|
|useLeadingZeros|When the target value has more digits than the start value show 0's in the extra places on the right. Othewise start with a blank spot that scrolls to 1.|
||BOOL|
||default: NO|

The background color can also be set on the newly created instance of OdometerView.

See the ViewController.m file in the example for full details on setting up the odometer.

## Known Issues
A brief flicker between the Presentation and Model layers can be seen between number scrolls when running the library in an Xcode v12 simulator. This has been reported as a simulator bug. The odometer should animate fine on an actual device or simulator <= 12.

Tests worked with a duration >= .2 Lower values may provided inconsistent results. Test smaller durations before use in production.

## Acknowledgements

Thanks to [RbBtSn0w for RBSOdometer](https://github.com/RbBtSn0w/RBSOdometer). That project was a great jumping off point and example to learn how to build this component. 

## License

ios-odometer is available under the MIT license. See the LICENSE file for more info.
