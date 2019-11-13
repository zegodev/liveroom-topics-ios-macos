//
//  ZGCustomTokenHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGCustomTokenHelper.h"
#import "ZGJsonHelper.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation ZGCustomTokenHelper

+ (NSString *)generateThirdTokenWithAppID:(unsigned int)appID timeout:(long)timeout idName:(NSString *)idName serverSecret:(NSString *)serverSecret {
    NSDictionary *dic =
    @{@"app_id":@(appID),
      @"timeout":@(timeout),
      @"nonce":@(11111111),
      @"id_name":idName};

    NSString *jsonContent = [ZGJsonHelper encodeToJSON:dic];
    
    // 16 字节长度随机初始向量
    NSString *iv = [self randomStringWithLength:16];
    // zego 提供的 key 是 32 字节
    NSData *contentData = [self encryptAES:jsonContent key:serverSecret keySize:32 iv:iv];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    // 将 iv、密文拼接，并对拼接内容 base64 编码
    // 将 version，base64编码拼接就是third_token
    NSMutableData *finalData = [[NSMutableData alloc] initWithCapacity:(contentData.length + ivData.length)];
    [finalData appendData:ivData];
    [finalData appendData:contentData];
    NSString *base64Final = [finalData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    // 将 version，base64编码拼接就是third_token
    NSString *thirdToken = [NSString stringWithFormat:@"01%@", base64Final];
    return thirdToken;
}

+ (NSData *)encryptAES:(NSString *)content key:(NSString *)key keySize:(size_t)keySize iv:(NSString *)iv {
    NSData *initVector = [iv dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = contentData.length;
    
    // 密文长度 <= 明文长度 + BlockSize
    size_t encryptSize = dataLength + kCCBlockSizeAES128;
    
    void *encryptedBytes = malloc(encryptSize);
    size_t actualOutSize = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,  // 系统默认使用 CBC，然后指明使用 PKCS7Padding
                                          keyData.bytes,
                                          keySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          encryptedBytes,
                                          encryptSize,
                                          &actualOutSize);
    
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytes:encryptedBytes length:actualOutSize];
    }
    free(encryptedBytes);
    return nil;
}

+ (NSString *)randomStringWithLength: (int) len {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    return randomString;
}

@end
