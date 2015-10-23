//
//  Base64.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/01/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "Base64.h"


@implementation Base64

#define ArrayLength(x) (sizeof(x)/sizeof(*(x)))

static uint8_t encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static uint8_t decodingTable[128];

+ (void)initialize
{
    if ([Base64 class] == self)
    {
        memset(decodingTable, 0, ArrayLength(decodingTable));
        for (uint8_t i = 0; i < ArrayLength(encodingTable); i++)
        {
            decodingTable[(int)encodingTable[i]] = i;
        }
    }
}


+ (NSString*)encode:(const uint8_t*)input length:(size_t)length
{
    NSMutableData* data   = [NSMutableData dataWithLength:(NSUInteger)((length + 2) / 3) * 4];
    uint8_t*       output = (uint8_t*)data.mutableBytes;
    
    for (NSUInteger i = 0; i < length; i += 3)
    {
        NSInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++)
        {
            value <<= 8;
            
            if (j < length)
            {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    encodingTable[(value >> 18) & 0x3F];
        output[index + 1] =                    encodingTable[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? encodingTable[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? encodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}


+ (NSString*)encode:(NSData*)rawBytes
{
    return [self encode:(const uint8_t*) rawBytes.bytes length:rawBytes.length];
}


+ (NSData*)decode:(const char*)string length:(size_t)inputLength
{
    if ((string == NULL) || (inputLength % 4 != 0))
    {
        return nil;
    }
    
    while (inputLength > 0 && string[inputLength - 1] == '=')
    {
        inputLength--;
    }
    
    NSUInteger      outputLength = inputLength * 3 / 4;
    NSMutableData*  data         = [NSMutableData dataWithLength:outputLength];
    uint8_t*        output       = data.mutableBytes;
    
    NSUInteger      inputPoint   = 0;
    NSUInteger      outputPoint  = 0;
    while (inputPoint < inputLength)
    {
        int i0 = string[inputPoint++];
        int i1 = string[inputPoint++];
        int i2 = inputPoint < inputLength ? string[inputPoint++] : 'A'; /* 'A' will decode to \0 */
        int i3 = inputPoint < inputLength ? string[inputPoint++] : 'A';
        
        output[outputPoint++] = (uint8_t)((decodingTable[i0] << 2) | (decodingTable[i1] >> 4));
        if (outputPoint < outputLength)
        {
            output[outputPoint++] = (uint8_t)(((decodingTable[i1] & 0xf) << 4) | (decodingTable[i2] >> 2));
        }
        
        if (outputPoint < outputLength)
        {
            output[outputPoint++] = (uint8_t)(((decodingTable[i2] & 0x3) << 6) | decodingTable[i3]);
        }
    }
    
    return data;
}


+ (NSData*)decode:(NSString*)string
{
    if ([string isKindOfClass:[NSString class]])
    {
        return [self decode:[string cStringUsingEncoding:NSASCIIStringEncoding] length:string.length];
    }
    else
    {
        return nil;
    }
}

@end
