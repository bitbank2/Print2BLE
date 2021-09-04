//
//  ViewController.h
//  Print2BLE
//
//  Created by Laurence Bank on 8/31/21.
//

#import <Cocoa/Cocoa.h>
#import "DragDropView.h"
#import "MyBLE.h"

@interface ViewController : NSViewController

@property (nonatomic, retain) DragDropView *myview;
@property (nonatomic) NSString *filename;
@property (weak) IBOutlet NSImageView *myImage;
@property (weak) IBOutlet NSTextField *StatusLabel;

// Process a new file
- (void)processFile:(NSString *)path;
- (void)ditherFile:(NSNotification *) notification;
- (uint8_t *)DitherImage:(uint8_t*)pPixels width:(int)iWidth height:(int)iHeight;
- (void) printImage;
@end

