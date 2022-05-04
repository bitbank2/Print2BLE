//
//  MyBLE.m
//  Print2BLE
//
//  Created by Larry Bank
//  Copyright (c) 2021 BitBank Software Inc. All rights reserved.
//

#import "MyBLE.h"

static NSString *validServices[] = {@"18F0", @"18F0", @"AE30",@"FF00",@"FF00",@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"};
static NSString *validChars[] = {@"2AF1", @"2AF1", @"AE01",@"FF02",@"FF02",@"49535343-8841-43F4-A8D4-ECBE34729BB3"};
const int8_t cChecksumTable[] = {0, 7, 14, 9, 28, 27, 18, 21, 56, 63, 54, 49, 36, 35, 42, 45, 112, 119, 126, 121, 108, 107, 98, 101, 72, 79, 70, 65, 84, 83, 90, 93, -32, -25, -18, -23, -4, -5, -14, -11, -40, -33, -42, -47, -60, -61, -54, -51, -112, -105, -98, -103, -116, -117, -126, -123, -88, -81, -90, -95, -76, -77, -70, -67, -57, -64, -55, -50, -37, -36, -43, -46, -1, -8, -15, -10, -29, -28, -19, -22, -73, -80, -71, -66, -85, -84, -91, -94, -113, -120, -127, -122, -109, -108, -99, -102, 39, 32, 41, 46, 59, 60, 53, 50, 31, 24, 17, 22, 3, 4, 13, 10, 87, 80, 89, 94, 75, 76, 69, 66, 111, 104, 97, 102, 115, 116,
                     125, 122, -119, -114, -121, -128, -107, -110, -101, -100, -79, -74, -65, -72, -83, -86, -93, -92, -7, -2, -9, -16, -27, -30, -21, -20, -63, -58, -49, -56, -35, -38, -45, -44, 105, 110, 103, 96, 117, 114, 123, 124, 81, 86, 95, 88, 77, 74, 67, 68, 25, 30, 23, 16, 5, 2, 11, 12, 33, 38, 47, 40, 61, 58, 51, 52, 78, 73, 64, 71, 82, 85, 92, 91, 118, 113, 120, 127, 106, 109, 100, 99, 62, 57, 48, 55, 34, 37, 44, 43, 6, 1, 8, 15, 26, 29, 20, 19, -82, -87, -96, -89, -78, -75, -68, -69, -106, -111, -104, -97, -118, -115, -124, -125, -34, -39, -48, -41, -62, -59, -52, -53, -26, -31, -24, -17, -6, -3, -12, -13};
/* Table of byte flip values to mirror-image data */
const unsigned char ucMirror[256]=
     {0, 128, 64, 192, 32, 160, 96, 224, 16, 144, 80, 208, 48, 176, 112, 240,
      8, 136, 72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248,
      4, 132, 68, 196, 36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244,
      12, 140, 76, 204, 44, 172, 108, 236, 28, 156, 92, 220, 60, 188, 124, 252,
      2, 130, 66, 194, 34, 162, 98, 226, 18, 146, 82, 210, 50, 178, 114, 242,
      10, 138, 74, 202, 42, 170, 106, 234, 26, 154, 90, 218, 58, 186, 122, 250,
      6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214, 54, 182, 118, 246,
      14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190, 126, 254,
      1, 129, 65, 193, 33, 161, 97, 225, 17, 145, 81, 209, 49, 177, 113, 241,
      9, 137, 73, 201, 41, 169, 105, 233, 25, 153, 89, 217, 57, 185, 121, 249,
      5, 133, 69, 197, 37, 165, 101, 229, 21, 149, 85, 213, 53, 181, 117, 245,
      13, 141, 77, 205, 45, 173, 109, 237, 29, 157, 93, 221, 61, 189, 125, 253,
      3, 131, 67, 195, 35, 163, 99, 227, 19, 147, 83, 211, 51, 179, 115, 243,
      11, 139, 75, 203, 43, 171, 107, 235, 27, 155, 91, 219, 59, 187, 123, 251,
      7, 135, 71, 199, 39, 167, 103, 231, 23, 151, 87, 215, 55, 183, 119, 247,
      15, 143, 79, 207, 47, 175, 111, 239, 31, 159, 95, 223, 63, 191, 127, 255};

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

- (void)dealloc
{
    [self.centralManager stopScan];
    //    [_manager dealloc]
}

- (uint8_t)findPrinter: (const char *) name
{
    const char *szTypes[] = {"MTP-II", "MTP-2", "MTP-3", "MTP-3F", "PeriPage+", "PeriPage_", "GT01", "GT02", "GB01", "GB02", "GB03", "YHK-54A8", NULL};
    const uint8_t ucTypes[] = {PRINTER_MTP2, PRINTER_MTP2, PRINTER_MTP3, PRINTER_MTP3, PRINTER_PERIPAGEPLUS, PRINTER_PERIPAGE, PRINTER_CAT, PRINTER_CAT, PRINTER_CAT, PRINTER_CAT, PRINTER_CAT, PRINTER_PANDA};
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

- (bool)isConnected
{
    return _bConnected;
} /* isConnected */

- (NSString *)getName
{
    return [_myPeripheral name];
} /* getName */

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
}
//------------------------------------------------------------------------------
// Invoked whenever an existing connection with the peripheral is torn down.
- (void) centralManager: (CBCentralManager *)central
didDisconnectPeripheral: (CBPeripheral *)aPeripheral
                  error: (NSError *)error
{
    printf("didDisconnectPeripheral\n");
    _bConnected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StatusChangedNotification"
                                                        object:self userInfo:nil];

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
    NSLog(@"Start scanning");
    
    [self.centralManager scanForPeripheralsWithServices: nil options: nil];
} /* startScan */

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

// Invoked upon completion of a -[discoverServices:] request.
// Discover available characteristics on interested services
- (void) peripheral: (CBPeripheral *)aPeripheral
didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        [aPeripheral discoverCharacteristics:nil forService:aService];
    }
}
//------------------------------------------------------------------------------

// Invoked upon completion of a -[discoverCharacteristics:forService:] request.
// Perform appropriate operations on interested characteristics
- (void) peripheral: (CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *aChar in service.characteristics)
    {
        NSLog(@"Service: %@ with Char: %@", [aChar service].UUID, aChar.UUID);
        CBUUID *theSvc = [CBUUID UUIDWithString:validServices[_ucPrinterType]];
        CBUUID *theChr = [CBUUID UUIDWithString:validChars[_ucPrinterType]];
        if ([[aChar service].UUID isEqual:theSvc] && [aChar.UUID isEqual:theChr]) {
            printf("Found the service+char we're looking for!\n");
        _myChar = aChar; // keep these since we will need them for communicating
        _bConnected = YES; // indicates that we're ready to send data
            [[NSNotificationCenter defaultCenter] postNotificationName:@"StatusChangedNotification"
                                                                object:self userInfo:nil];
        }
    }
}

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

- (void)feedPaper
{
    uint8_t ucTemp[16];
    const uint8_t paperFeed[] = {0x51, 0x78, 0xa1, 0, 2, 0, 30, 90, 0xff, 0xff};
    int iLen = 0;
    if (_bConnected) {
        if (_ucPrinterType == PRINTER_CAT) {
            // needs special byte sequence
            int iLines = 1; // number of 1/6" lines
            memcpy(ucTemp, paperFeed, sizeof(paperFeed));
            ucTemp[6] = (uint8_t)(iLines >> 8);
            ucTemp[7] = (uint8_t)iLines;
            ucTemp[8] = [self CheckSum:&ucTemp[6] withLength: 2];
            iLen = sizeof(paperFeed);
        } else {
            iLen = 2;
            ucTemp[0] = 0xd;
            ucTemp[1] = 0xa;
        }
        [self writeData:ucTemp withLength:iLen withResponse:NO];
    }
} /* feedPaper */

- (int)getWidth
{
    const int iPrinterWidths[] = {384, 576, 384, 576, 384, 384};
    if (_ucPrinterType < PRINTER_COUNT)
        return iPrinterWidths[_ucPrinterType];
    return 0;
} /* getWidth */

- (void)preGraphics:(int)height
{
    uint8_t ucTemp[512];
    int iWidth = [self getWidth];
    const int8_t printImage[] = {81, 120, -66, 0, 1, 0, 0, 0, -1};
    
    switch (_ucPrinterType) {
        case PRINTER_PANDA:
        {
            int iHeight = 1; // DEBUG
            int iImageSize = iWidth * iHeight;
            int iSize = ((iImageSize * 5) >> 3) + 4;
            int i, i4;
            ucTemp[0] = 1;
            ucTemp[1] = 0x42;
            ucTemp[2] = (uint8_t)((iSize-4) & 0xff);
            ucTemp[3] = (uint8_t)((iSize-4) >> 8);
            i4 = 4;
            i = 0;
            while (i < iImageSize/8 && i4 < iSize) {
//                int i5 = i * 8;
                int intValue = 1; //((Integer) arrayList.get(i5)).intValue();
                int intValue2 = 1; //((Integer) arrayList.get(i5 + 1)).intValue();
                int intValue3 = 1; //((Integer) arrayList.get(i5 + 2)).intValue();
                int intValue4 = 1; //((Integer) arrayList.get(i5 + 3)).intValue();
                int intValue5 = 1; //((Integer) arrayList.get(i5 + 4)).intValue();
                int intValue6 = 1; //((Integer) arrayList.get(i5 + 5)).intValue();
                int intValue7 = 1; //((Integer) arrayList.get(i5 + 6)).intValue();
                int i6 = (intValue2 >> 3) | (intValue3 << 2) | ((intValue4 & 1) << 7);
                int i7 = (intValue4 >> 1) | ((intValue5 & 15) << 4);
                int i8 = ((intValue5 & 16) >> 4) | (intValue6 << 1) | ((intValue7 & 3) << 6);
                int i9 = i4 + 1;
                ucTemp[i4] = (uint8_t)(intValue | ((intValue2 & 7) << 5));
                int i10 = i9 + 1;
                ucTemp[i9] = (uint8_t) i6;
                int i11 = i10 + 1;
                ucTemp[i10] = (uint8_t) i7;
                int i12 = i11 + 1;
                ucTemp[i11] = (uint8_t) i8;
                ucTemp[i12] = (uint8_t) ((1 /*arrayList.get(i5 + 7)).intValue()*/ << 3) | ((intValue7 & 28) >> 2));
                i++;
                i4 = i12 + 1;
            } // while generating output
            [self writeData:ucTemp withLength:iSize withResponse:NO];
        }
            break;
        case PRINTER_MTP2:
        case PRINTER_MTP3:
            ucTemp[0] = 0x1d; ucTemp[1] = 'v';
            ucTemp[2] = '0'; ucTemp[3] = '0';
            ucTemp[4] = iWidth/8; ucTemp[5] = 0;
            ucTemp[6] = (uint8_t)height; ucTemp[7] = (uint8_t)(height>>8);
            [self writeData:ucTemp withLength:8 withResponse:NO];
            break;
        case PRINTER_CAT:
            [self writeData:(uint8_t *)printImage withLength:sizeof(printImage) withResponse:NO];
            break;
        case PRINTER_PERIPAGEPLUS:
        case PRINTER_PERIPAGE:
            ucTemp[0] = 0x10; ucTemp[1] = 0xff;
            ucTemp[2] = 0xfe; ucTemp[3] = 0x01; // start of command
            [self writeData:ucTemp withLength:4 withResponse:NO];
            memset(ucTemp, 0, 12);
            [self writeData:ucTemp withLength:12 withResponse:NO]; // 12 0's (not sure why)
            ucTemp[0] = 0x1d; ucTemp[1] = 0x76;
            ucTemp[2] = 0x30; ucTemp[3] = 0x00;
            ucTemp[4] = (uint8_t)((iWidth+7)>>3); ucTemp[5] = 0x00; // width in bytes
            ucTemp[6] = (uint8_t)height; ucTemp[7] = (uint8_t)(height>>8); // height (little endian)
            [self writeData:ucTemp withLength:8 withResponse:NO];
            break;
    } // switch on printer type
} /* preGraphics */

- (uint8_t) CheckSum:(uint8_t *)pData withLength: (int) iLen
{
int i;
uint8_t cs = 0;

    for (i=0; i<iLen; i++)
        cs = cChecksumTable[(cs ^ pData[i])];
    return cs;
} /* CheckSum */
- (void) scanLine: (uint8_t *)pData withLength:(int)len
{
    uint8_t ucTemp[64+8];
    static int iCount = 0; // for knowing when to request an ACK (withResponse)
    int i;
    if (_ucPrinterType == PRINTER_CAT) {
        ucTemp[0] = 0x51;
        ucTemp[1] = 0x78;
        ucTemp[2] = 0xa2; // gfx, uncompressed
        ucTemp[3] = 0;
        ucTemp[4] = (uint8_t)len; // data length
        ucTemp[5] = 0;
        for (i=0; i<len; i++) { // reverse the bits
          ucTemp[6+i] = ucMirror[pData[i]];
        } // for each byte to mirror
        ucTemp[6 + len] = 0;
        ucTemp[6 + len + 1] = 0xff;
        ucTemp[6 + len] = [self CheckSum:&ucTemp[6] withLength: len];
        [self writeData:ucTemp withLength:8 + len withResponse:(iCount & 0xf) == 0];
    } else if (_ucPrinterType == PRINTER_MTP2 || _ucPrinterType == PRINTER_MTP3 || _ucPrinterType == PRINTER_PERIPAGE || _ucPrinterType == PRINTER_PERIPAGEPLUS) {
        [self writeData:pData withLength:len withResponse:(iCount & 0xf) == 0];
    }
      // NB: To reliably send lots of data over BLE, you either use WRITE with
      // response (which waits for each packet to be acknowledged), or you can
      // use withoutResponse, but this creates a new problem. If enough packets
      // are sent without asking for a response, the peripheral (server) end will
      // close the connection. For our usage, we ask for withResponse every 16 packets
    iCount++; // ack counter
} /* scanLine */
- (void) postGraphics
{
    if (_ucPrinterType == PRINTER_PERIPAGE || _ucPrinterType == PRINTER_PERIPAGEPLUS)
    {
        uint8_t ucTemp[] = {0x1b, 0x4a, 0x40, 0x10, 0xff, 0xfe, 0x45};
        [self writeData:ucTemp withLength:sizeof(ucTemp) withResponse:NO];
    }
} /* postGraphics */
@end
