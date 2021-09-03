//
//  MyBLE.h
//  Print2BLE
//
//  Created by Laurence Bank on 9/1/21.
//

#import <Foundation/Foundation.h>
#import "CoreBluetooth/CoreBluetooth.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyBLE : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

- (instancetype)init;
//- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue;
//- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue
//                serviceToScan: (CBUUID *) scanServiceId
//         characteristicToRead: (CBUUID *) characteristicId;
- (void)startScan;
- (uint8_t)findPrinter: (const char *) name;
- (void)writeData: (uint8_t *)pData withLength:(int)len withResponse:(bool)response;
- (void)preGraphics: (int)height;
- (void) postGraphics;
- (int)getWidth;
- (void) scanLine: (uint8_t *)pData withLength:(int)len;
- (uint8_t) CheckSum:(uint8_t *)pData withLength: (int) iLen;
@property (retain) NSMutableArray *discoveredPeripherals;
@property (strong, nonatomic) CBCentralManager * manager;
@property (atomic) int count;
@property (nonatomic) dispatch_queue_t bleQueue;
@property (nonatomic) CBPeripheral *myPeripheral;
@property (nonatomic) CBCharacteristic *myChar;
@property (nonatomic) bool shouldScan;
@property (nonatomic) bool bConnected;
@property (nonatomic) uint8_t ucPrinterType;
//@property (nonatomic) CBUUID *serviceUuid;
//@property (nonatomic) CBUUID *characteristicUuid;
@property (copy) NSString *manufacturer;

enum {
  PRINTER_MTP2=0,
  PRINTER_MTP3,
  PRINTER_CAT,
  PRINTER_PERIPAGEPLUS,
  PRINTER_PERIPAGE,
  PRINTER_COUNT
};

@end

NS_ASSUME_NONNULL_END
