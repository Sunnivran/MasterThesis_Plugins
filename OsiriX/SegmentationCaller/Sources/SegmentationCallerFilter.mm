#import "SegmentationCallerFilter.h"
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMObject.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/Notifications.h>

@implementation SegmentationCallerFilter

#define EMPTY_STRING @""

static NSString *chosedRadioButtonOption = @"FirstOption";

-(void)filesIn:(id)obj into:(NSMutableArray*)files {
	if ([obj isKindOfClass:[NSArray class]])
		for (id sobj in obj)
			[self filesIn:sobj into:files];
	else
		if ([obj isKindOfClass:[DicomAlbum class]])
			for (id study in ((DicomAlbum*)obj).studies)
				[self filesIn:study into:files];
		else
			if ([obj isKindOfClass:[DicomStudy class]])
				for (id series in ((DicomStudy*)obj).series)
					[self filesIn:series into:files];
			else
				if ([obj isKindOfClass:[DicomSeries class]])
					[files addObjectsFromArray:[((DicomSeries*)obj).images allObjects]];
}

-(NSArray*)filesIn:(NSArray*)arr {
	NSMutableArray* files = [NSMutableArray array];
	[self filesIn:arr into:files];
	return files;
}

-(NSString*)replacementForKey:(NSString*)str forImage:(DicomImage*)dicomImage asDcmObj:(DCMObject*)dcmObj {
	if ([str isEqual:@"BundleResourcesPath"])
		return [[NSBundle bundleForClass:[self class]] resourcePath];
	
	if ([str isEqual:@"DicomFilePath"])
		return dicomImage.completePathResolved;
	
	DCMAttributeTag* tag = [DCMAttributeTag tagWithName:str];
	if (!tag) tag = [DCMAttributeTag tagWithTagString:str];
	if (tag && tag.group && tag.element) {
		DCMAttribute* attr = [dcmObj attributeForTag:tag];
		NSString* val = [[attr value] description];
		if (val) return val;
	}
	
	NSLog(@"[SSC] Warning: key %@ unrecognized", str);
	return [NSString stringWithFormat:@"%%%@%%", str];
}

-(void)processImages:(DicomImage*)dicomImage toFile:(NSString*)outputPath withCallParams:(NSString*)callParams{
    NSLog(@"[SSC] Starting processing...");
	NSDictionary* info = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSArray* execParamsTemplate = [info objectForKey:@"Command"];
    
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:dicomImage.completePathResolved decodingPixelData:NO];
    
    NSMutableArray* params = [[execParamsTemplate mutableCopy] autorelease];
    for (NSUInteger i = 0; i < params.count; ++i) {
        NSMutableString* str = [[[params objectAtIndex:i] mutableCopy] autorelease];
        
        NSUInteger from = 0;
        NSRange r1;
        while (from < str.length && (r1 = [str rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(from, str.length-from)]).length) {
            NSRange r2 = [str rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(r1.location+r1.length, str.length-(r1.location+r1.length))];
            if (!r2.length) break;
            r1.length = r2.location+r2.length-r1.location;
            NSString* replaceFrom = [str substringWithRange:NSMakeRange(r1.location+1, r1.length-2)];
            NSString* replaceTo = [self replacementForKey:replaceFrom forImage:dicomImage asDcmObj:dcmObj];
            [str replaceCharactersInRange:r1 withString:replaceTo];
            from = r1.location+replaceTo.length;
        }
        
        [params replaceObjectAtIndex:i withObject:str];
    }
    
    NSString* path = [[[params objectAtIndex:0] retain] autorelease];
    [params removeObjectAtIndex:0];
    [params addObject:outputPath];
    [params addObject:callParams];
    
    NSLog(@"[SSC] Executing %@ with params [%@]", path, [params componentsJoinedByString:@", "]);
    [[NSTask launchedTaskWithLaunchPath:path arguments:params] waitUntilExit];
    
    [pool release];
    
    NSLog(@"[SSC] Processing ended.");
}

-(NSString*)showSaveFileDialog{
    NSString *savePath = EMPTY_STRING;
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    if([panel runModal] == NSFileHandlingPanelOKButton)
    {
        savePath = [[[panel URL] absoluteString] substringFromIndex:[@"file://" length]];
        NSLog(@"[SSC] User choosed save path: %@", savePath);
    }
    return savePath;
}

-(void)udpateProgresBarToStage:(int)stage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.0];
        [progresIndicator setIntValue:stage];
        [NSAnimationContext endGrouping];
    });
}

-(IBAction)closeDialog:(id)sender{
    if([sender tag] == 1)
    {
        NSLog(@"[SSC] Starting plugin...");
        
        NSInteger slider = [paramSlider intValue];
        NSString *textBox = [paramTextField stringValue];
        BOOL checkbox = false;
        if([paramCheckBox state]==NSOnState)
            checkbox = true;
        
        NSString *outputPath = [self showSaveFileDialog];
        if([outputPath isEqualToString:EMPTY_STRING])
        {
            NSLog(@"[SSC] User did not choosed path to save output file");
            return;
        }
        
        [self udpateProgresBarToStage:1];
        NSLog(@"[SSC] Readed call params: slider=%ld textBox=%@ checkBox=%hhd radioButton=%@", slider, textBox, checkbox, chosedRadioButtonOption);
        //All Dicom images have the same path to one file
        DicomImage* dicomImage = [[self filesIn:[[BrowserController currentBrowser] databaseSelection]] objectAtIndex:0];
        NSString *callParams = [NSString stringWithFormat:@"%ld|%@|%hhd|%@", slider, textBox, checkbox, chosedRadioButtonOption];
        [self processImages:dicomImage toFile:outputPath withCallParams:callParams];
        
        [self udpateProgresBarToStage:2];
        NSLog(@"[SSC] Script has ended segmentation");
        
        [BrowserController.currentBrowser.database
            addFilesAtPaths: [NSArray arrayWithObject:outputPath]
            postNotifications:YES
            dicomOnly:YES
            rereadExistingItems:YES
            generatedByOsiriX:NO];
        
        [self udpateProgresBarToStage:3];
        NSLog(@"[SSC] Segmentation presented in OsiriX Viewer");
    }
    
    NSLog(@"[SSC] Closing plugin...");
    [window orderOut:sender];
    [NSApp endSheet:window returnCode:[sender tag]];
}

-(IBAction)sliderValueChange:(NSSlider *)sender{
    [paramSliderLabel setIntValue:[paramSlider intValue]];
}

-(IBAction)radioButtonSelectChange:(NSButton *)sender{
    chosedRadioButtonOption = [sender title];
}

-(long)filterImage:(NSString*)menuTitle {
    [NSBundle loadNibNamed:@"Window" owner:self];
    [NSApp beginSheet:window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    return 0;
}

@end
