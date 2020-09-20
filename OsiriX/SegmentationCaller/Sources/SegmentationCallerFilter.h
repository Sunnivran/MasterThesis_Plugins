#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface SegmentationCallerFilter : PluginFilter {
    IBOutlet NSWindow *window;
    IBOutlet NSSlider *paramSlider;
    IBOutlet NSTextField *paramSliderLabel;
    IBOutlet NSTextField *paramTextField;
    IBOutlet NSButton *paramCheckBox;
    IBOutlet NSLevelIndicator *progresIndicator;
}

-(long)filterImage:(NSString*)menuTitle;
-(IBAction)closeDialog:(id)sender;
-(IBAction)sliderValueChange:(NSSlider*)sender;
-(IBAction)radioButtonSelectChange:(NSButton*)sender;

@end
