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
    [BLEClass startScan]; // scan and connect to any printers in the area

}

- (void)viewDidLayout {
    // the outer frame size is known here, so set our drag/drop frame to the same size
    
//    _myview.frame = NSMakeRect(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
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

- (uint8_t *)DitherImage:(uint8_t*)pPixels width:(int)iWidth height:(int)iHeight
{
    int x, y, xmask=0, iDestPitch=0;
    int32_t cNew, lFErr, v=0, h;
    int32_t e1,e2,e3,e4;
    uint8_t cOut; // forward errors for gray
    uint8_t *pSrc, *pDest, *errors, *pErrors=NULL, *d, *s; // destination 8bpp image
    uint8_t pixelmask=0, shift=0;
    uint8_t ucTemp[640];
    
        errors = ucTemp; // plenty of space here for the bitmaps we'll generate
        errors[0] = errors[1] = errors[2] = 0;
        pSrc = pPixels; // write the new pixels over the original
        iDestPitch = (iWidth+7)/8;
        pDest = (uint8_t *)malloc(iDestPitch * iHeight);
        pixelmask = 0x80;
        shift = 1;
        xmask = 7;
        for (y=0; y<iHeight; y++)
        {
            s = &pSrc[y * iWidth];
            d = &pDest[y * iDestPitch];
            pErrors = &errors[1]; // point to second pixel to avoid boundary check
            lFErr = 0;
            cOut = 0;
            for (x=0; x<iWidth; x++)
            {
                cNew = *s++; // get grayscale uint8_t pixel
                // add forward error
                cNew += lFErr;
                if (cNew > 255) cNew = 255;     // clip to uint8_t
                cOut <<= shift;                 // pack new pixels into a byte
                cOut |= (cNew >> (8-shift));    // keep top N bits
                if ((x & xmask) == xmask)       // store it when the byte is full
                {
                    *d++ = ~cOut; // color is inverted
                    cOut = 0;
                }
                // calculate the Floyd-Steinberg error for this pixel
                v = cNew - (cNew & pixelmask); // new error for N-bit gray output (always positive)
                h = v >> 1;
                e1 = (7*h)>>3;  // 7/16
                e2 = h - e1;  // 1/16
                e3 = (5*h) >> 3;   // 5/16
                e4 = h - e3;  // 3/16
                // distribute error to neighbors
                lFErr = e1 + pErrors[1];
                pErrors[1] = (uint8_t)e2;
                pErrors[0] += e3;
                pErrors[-1] += e4;
                pErrors++;
            } // for x
        } // for y
    return pDest;
} /* DitherImage */

- (void)printFile:(NSNotification *) notification
{
    // load the file into an image object
    NSData *theFileData = [[NSData alloc] initWithContentsOfFile:_filename options: NSDataReadingMappedAlways error: nil]; // read file into memory
    if (theFileData) {
        // decode the image into a bitmap
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:theFileData];
        if (bitmap) {
            // convert to grayscale
            NSColorSpace *targetColorSpace = [NSColorSpace genericGrayColorSpace];
            NSBitmapImageRep *grayBitmap = [bitmap bitmapImageRepByConvertingToColorSpace: targetColorSpace renderingIntent: NSColorRenderingIntentDefault];
                                           
                                           //bitmapImageRepByConvertingToColorSpace(NSColorSpace.genericGrayColorSpace(), renderingIntent: NSColorRenderingIntent.Default)];

            int iWidth, iHeight;
            // scale to correct size (576 or 384 pixels wide)
            int iNewWidth, iNewHeight;
            float ratio;
            iWidth = bitmap.size.width;
            iHeight = bitmap.size.height;
            iNewWidth = [BLEClass getWidth]; // get printer width in pixels
            ratio = (float)iWidth / (float)iNewWidth;
            iNewHeight = (int)((float)iHeight / ratio);
            NSSize newSize;
            newSize.width = iNewWidth;
            newSize.height = iNewHeight;
            // now resize it
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                      initWithBitmapDataPlanes:NULL
                                    pixelsWide:newSize.width
                                    pixelsHigh:newSize.height
                                 bitsPerSample:8
                               samplesPerPixel:1
                                      hasAlpha:NO
                                      isPlanar:NO
                                colorSpaceName:NSCalibratedWhiteColorSpace
                                   bytesPerRow:0
                                  bitsPerPixel:0];
            rep.size = newSize;
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
            [grayBitmap drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height)];
            [NSGraphicsContext restoreGraphicsState];
            uint8_t *pPixels = [rep bitmapData];
            uint8_t *pOut = [self DitherImage:pPixels width:iNewWidth height:iNewHeight];
            // Now send it to the printer
            [BLEClass preGraphics:iNewHeight];
            int iPitch = iNewWidth/8;
            uint8_t *s = pOut;
            for (int y=0; y<iNewHeight; y++) {
                [BLEClass scanLine:s withLength:iPitch];
                s += iPitch;
            }
            [BLEClass postGraphics];
        }
    }
} /* printFile*/
@end
