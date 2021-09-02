//
//  MyBLE.m
//  Print2BLE
//
//  Created by Laurence Bank on 9/1/21.
//

#import "MyBLE.h"

static NSString *validServices[] = {@"18F0", @"18F0", @"AE30",@"FF00",@"FF00"};
static NSString *validChars[] = {@"2AF1", @"2AF1", @"AE01",@"FF02",@"FF02"};

@implementation MyBLE

- (instancetype)init
{
    _bConnected = false;
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    return [self initWithQueue:nil];
    self.discoveredPeripherals = [NSMutableArray array];
    self = [super init];
    return self;
}

//- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue
//{
//    return [self initWithQueue: centralDelegateQueue
//                 serviceToScan: nil
//          characteristicToRead: nil];
//                 serviceToScan: [CBUUID UUIDWithString: @"29D7544B-6870-45A4-BB7E-D981535F4525"]
//          characteristicToRead: [CBUUID UUIDWithString: @"B81672D5-396B-4803-82C2-029D34319015"]];
//}

//- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue
//                serviceToScan: (CBUUID *) scanServiceId
//         characteristicToRead: (CBUUID *) characteristicId
//{
//    self = [super init];
//    if (self)
//    {
//        self.discoveredPeripherals = [NSMutableArray array];
//        _count=0;
//        self.shouldScan = true;
//        _bleQueue = centralDelegateQueue;
//        self.serviceUuid = scanServiceId;
//        self.characteristicUuid = characteristicId;
//        _manager = [[CBCentralManager alloc] initWithDelegate: self
//                                                        queue: _bleQueue];
//    }
//    return self;
//}

//------------------------------------------------------------------------------
- (void)dealloc
{
    [self.centralManager stopScan];
    //    [_manager dealloc]
}

//------------------------------------------------------------------------------
#pragma mark Manager Methods

- (uint8_t)findPrinter: (const char *) name
{
    const char *szTypes[] = {"MTP-2", "MTP-3", "MTP-3F", "PeriPage+", "PeriPage_", "GT01", "GT02", "GB01", "GB02", NULL};
    const uint8_t ucTypes[] = {PRINTER_MTP2, PRINTER_MTP3, PRINTER_MTP3, PRINTER_PERIPAGEPLUS, PRINTER_PERIPAGE, PRINTER_CAT, PRINTER_CAT, PRINTER_CAT, PRINTER_CAT};
    char szTemp[32];
    uint8_t ucType = 255; // invalid
    int i=0;
    strcpy(szTemp, name); // truncate the PeriPage name because it has part of the MAC addr
    szTemp[9] = 0; // truncate after PeriPage_ or PeriPage+
    while (szTypes[i] != NULL) {
        if (strcmp(szTemp, szTypes[i]) == 0) {
            ucType = ucTypes[i];
            return ucType;
        } else {
            i++;
        }
    }
    return ucType;
} /* findPrinter */

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)aPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSMutableArray *peripherals =  [self mutableArrayValueForKey:@"discoveredPeripherals"];
    const char* deviceName = [[aPeripheral name] cStringUsingEncoding:NSASCIIStringEncoding];
    
//    if ([[aPeripheral name] isEqualToString: @"BaronVonTigglestest"])
//    {
//        [self connectToPeripheral: aPeripheral];
//    }
    if (deviceName) printf("Found device: %s\n", deviceName);
    if( deviceName && ![self.discoveredPeripherals containsObject:aPeripheral])
    {
        // check if it's one of the supported names
        _ucPrinterType = [self findPrinter:deviceName];
        if (_ucPrinterType < PRINTER_COUNT) {
            printf("Found a supported printer: %s, connecting...\n", deviceName);
            [peripherals addObject:aPeripheral];
            [self.discoveredPeripherals addObject:aPeripheral];
            [self connectToPeripheral: aPeripheral];
        }
    }
}

//------------------------------------------------------------------------------
- (void) centralManager: (CBCentralManager *)central
   didConnectPeripheral: (CBPeripheral *)aPeripheral
{
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central
 didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self.centralManager stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        _myPeripheral = [peripherals objectAtIndex:0];
        [self.centralManager connectPeripheral:_myPeripheral
                            options:nil];
    }
}

//------------------------------------------------------------------------------
- (void)centralManagerDidUpdateState:(CBCentralManager *)manager
{
    if ([self.centralManager state] == CBManagerStatePoweredOn && _shouldScan)
    {
        [self startScan];
    }
}
//------------------------------------------------------------------------------
// Invoked whenever an existing connection with the peripheral is torn down.
- (void) centralManager: (CBCentralManager *)central
didDisconnectPeripheral: (CBPeripheral *)aPeripheral
                  error: (NSError *)error
{
    printf("didDisconnectPeripheral\n");
}
//------------------------------------------------------------------------------
/// Invoked whenever the central manager fails to create a connection with the peripheral.
- (void) centralManager: (CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
}
//------------------------------------------------------------------------------
- (void) startScan
{
    printf("Start scanning\n");
    
//    if (!serviceUuid)
    {
        [self.centralManager scanForPeripheralsWithServices: nil
                                         options: nil];
    }
//    else
//    {
//        [_manager scanForPeripheralsWithServices: [NSArray arrayWithObject: serviceUuid]
//                                         options: nil];
//    }
}

- (void) connectToPeripheral: (CBPeripheral *)aPeripheral
{
    [self.centralManager stopScan];
    _myPeripheral = aPeripheral;
    NSDictionary *connectOptions = @{
        CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
        CBConnectPeripheralOptionNotifyOnNotificationKey: @YES,
        //        CBConnectPeripheralOptionEnableTransportBridgingKey:,
        //        CBConnectPeripheralOptionRequiresANCS:,
        CBConnectPeripheralOptionStartDelayKey: @0
    };
    [self.centralManager connectPeripheral:_myPeripheral options:connectOptions];
}
//------------------------------------------------------------------------------
#pragma mark Peripheral Methods

// Invoked upon completion of a -[discoverServices:] request.
// Discover available characteristics on interested services
- (void) peripheral: (CBPeripheral *)aPeripheral
didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
//#if DEBUG_MODE
        NSLog(@"Service found with UUID: %@", aService.UUID);
//#endif
//        [aPeripheral discoverCharacteristics:@[characteristicUuid] forService:aService];
        [aPeripheral discoverCharacteristics:nil /*@[[CBUUID UUIDWithString:@"2AF1"]]*/ forService:aService];
    }
}
//------------------------------------------------------------------------------

// Invoked upon completion of a -[discoverCharacteristics:forService:] request.
// Perform appropriate operations on interested characteristics
- (void) peripheral: (CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *aChar in service.characteristics)
    {
//#if DEBUG_MODE
        NSLog(@"Service: %@ with Char: %@", [aChar service].UUID, aChar.UUID);
//#endif
        CBUUID *theSvc = [CBUUID UUIDWithString:validServices[_ucPrinterType]];
        CBUUID *theChr = [CBUUID UUIDWithString:validChars[_ucPrinterType]];
        if ([[aChar service].UUID isEqual:theSvc] && [aChar.UUID isEqual:theChr]) {
            printf("Found the service+char we're looking for!\n");
        _myChar = aChar; // keep these since we will need them for communicating
        _bConnected = 1; // indicates that we're ready to send data
        
//        if (aChar.properties & CBCharacteristicPropertyRead)
        {
            static char *szMsg = "Hello from MacOS!\n";
            static unsigned char ucInit[] = {0x10, 0xff, 0xfe, 0x01};
            NSData *myInit = [NSData dataWithBytes:ucInit length:4];
            NSData *myData = [NSData dataWithBytes:szMsg length:strlen(szMsg)];
            
            if (_ucPrinterType == PRINTER_PERIPAGE || _ucPrinterType == PRINTER_PERIPAGEPLUS)
                [aPeripheral writeValue:myInit forCharacteristic:aChar type:CBCharacteristicWriteWithoutResponse];
//            [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
            [aPeripheral writeValue:myData forCharacteristic:aChar type:CBCharacteristicWriteWithoutResponse];
            //                [aPeripheral readValueForCharacteristic:aChar];
            //                [aPeripheral readValueForDescriptor:nil]
        }
        }
    }
}
//------------------------------------------------------------------------------

// Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
- (void) peripheral: (CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [self printCharacteristicData:characteristic];
}

- (void) printCharacteristicData: (CBCharacteristic *)characteristic
{
#if DEBUG_MODE
    NSLog(@"Read Characteristics: %@", characteristic.UUID);
    NSLog(@"%@", [characteristic description]);
#endif
    NSData * updatedValue = characteristic.value;
    printf("%s\n",(char*)updatedValue.bytes);
}

- (void) peripheral: (CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheral: (CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}
- (void)peripheral: (CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    exit(0);
}

- (void)writeData: (uint8_t *)pData withLength:(int)len withResponse:(bool)response
{
    NSData *myData = [NSData dataWithBytes:pData length:len];
    
    if (response)
        [_myPeripheral writeValue:myData forCharacteristic:_myChar type:CBCharacteristicWriteWithResponse];
    else
        [_myPeripheral writeValue:myData forCharacteristic:_myChar type:CBCharacteristicWriteWithoutResponse];

} /* writeData */

@end
