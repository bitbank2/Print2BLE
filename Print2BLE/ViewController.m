//
//  ViewController.m
//  Print2BLE
//
//  Created by Laurence Bank on 8/31/21.
//

#import "ViewController.h"
#import "MyBLE.h"

MyBLE *BLEClass;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    BLEClass = [[MyBLE alloc] init];
    
    _myview = [DragDropView alloc];
    _myview.myVC = self; // give DragDropView access to our methods
    [[self view] addSubview:_myview];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(printFile:)
                                                 name:@"PrintFileNotification"
                                               object:nil];

}

- (void)viewDidLayout {
    // the outer frame size is known here, so set our drag/drop frame to the same size
    
    [_myview initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)ConnectPushed:(NSButton *)sender {
    NSLog(@"Connect!");
    [BLEClass startScan];
}

- (IBAction)TransmitPushed:(NSButton *)sender {
    NSLog(@"Transmit!");
}
// Process a new file
- (void)processFile:(NSString *)path
{
    _filename = [[NSString alloc] initWithString:path];
    NSLog(@"User dropped file %@", _filename);

} /* processFile */

- (void)printFile:(NSNotification *) notification
{
} /* printFile*/
@end
