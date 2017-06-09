# Base64编码学习
在使用文本编辑器打开二进制文件时，其二进制数据并不是全部可见的字符，所以会出现乱码。

为了避免这种情况，使用 Base64 编码的方式，将二进制数据编码为可见字符。注意 Base64 编码是一种编码方法并不是加密方法。

## 原理
将一段二进制数据进行 Base64 编码，步骤如下：

1. 将二进制数据每三个字节一组，进行分组，最后不足三个字节的补零构成3个字节
2. 将每组的3个字节分成4组，每组6个bit位，对每6个bit位高位补零，得到4个字节
3. 这样二进制的数据变长了，但每个字节的值均在0到63的范围内，进行查表替换为相应的字符
4. 字符表中共64个字符，包括42个英文字母（大写与小写字母各26个），0到9共10个数字，另外两个 ‘**+**’、‘**/**’ 字符，需要注意的是，若第一步进行了补零操作，那么，补充了几个字节，则最后的几个字节使用 ‘**=**’ 字符替换
5. 最终得到编码后的二进制数据，用 UTF-8 将该二进制数据编码，得到可见的字符串

将一段经过 Base64 编码得到的字符串解码为原二进制数据，步骤如下：

1. 将字符串转换为二进制数据
2. 将二进制数据分为每4个字节一组
3. 处理每个组的每一个字节，查表，找到该字节表示的字符的序号，取该序号的低6位
4. 每个组经过处理拼接后，得到24个bit位，共计3个字节
5. 处理最后一组4个字节时，检查最后有几个 ‘**=**’ 字符，若没有，正常处理，若有1个，那么丢弃3个字节中的最后一个字节，若有2个，则只保留3个字节中的第一个字节

## 实现

iOS 官方接口 **NSData** 的分类 **NSDataBase64Encoding** 中提供了 Base64 的相关方法，如下：

```
@interface NSData (NSDataBase64Encoding)

/* 
使用经过 Base64 编码后的字符串，初始化一个 NSData 类实例，
这里就是将 Base64 编码后的字符串进行了解码，得到原始的二进制数据
*/
- (instancetype)initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options NS_AVAILABLE(10_9, 7_0);

/* 
使用自身的二进制数据进行 Base64 编码，最后返回编码后的字符串
*/
- (NSString *)base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)options NS_AVAILABLE(10_9, 7_0);

/* 
使用经过 Base64 编码后得到的二进制数据，初始化一个 NSData 类实例，
这里就是将 Base64 编码后的二进制数据进行了解码，得到原始的二进制数据
*/
- (instancetype)initWithBase64EncodedData:(NSData *)base64Data options:(NSDataBase64DecodingOptions)options NS_AVAILABLE(10_9, 7_0);

/*
使用自身的二进制数据进行 Base64 编码，最后返回编码后的二进制数据
*/
- (NSData *)base64EncodedDataWithOptions:(NSDataBase64EncodingOptions)options NS_AVAILABLE(10_9, 7_0);

@end

上面4种方法，可看做两组方法，分别进行了编码和解码操作，
只是前两个方法，编码的结果和解码的入参都是字符串，后两种是二进制数据。
```

除了调用 iOS 提供的方法，还可以自己实现 Base64 编码及解码，如下：

```
#import <Foundation/Foundation.h>

@interface Base64 : NSObject

/**
 对提供的二进制数据进行Base64编码
 @param data 待编码的二进制数据
 */
+ (NSString *)base64Encode:(NSData *)data;


/**
 将经过Base64编码的字符串解码为原二进制数据
 @param base64String 待解码的Base64字符串
 */
+ (NSData *)base64Decode:(NSString *)base64String;

@end
```

```

#import "Base64.h"

@implementation Base64

#pragma mark - base64 编码
+ (NSString *)base64Encode:(NSData *)data
{
    NSMutableData *base64 = [NSMutableData new];
    
    NSRange range = NSMakeRange(0, 3);
    
    unsigned char buffer[3] = {0};
    unsigned char base[4] = {0};
    
    //三的整数倍数据
    double index = data.length / 3  * 3;
    while (range.location + range.length <= index) {
        [data getBytes:buffer range:range];
        
        //第一个 6 bit
        base[0] = base64_table[buffer[0] >> 2];
        
        //第二个 6 bit
        base[1] = base64_table[(buffer[0] & 0b11) << 4 | (buffer[1] >> 4)];
        
        //第三个 6 bit
        base[2] = base64_table[(buffer[1] & 0b1111) << 2 | (buffer[2] >> 6)];
        
        //第四个 6 bit
        base[3] = base64_table[buffer[2] & 0b111111];
        
        [base64 appendBytes:base length:4];
        range.location +=range.length;
    }
    
    //处理最后一个字节或两个字节数据
    if (data.length%3 == 1) {
        [data getBytes:buffer range:NSMakeRange(index, 1)];
        
        //第一个 6 bit
        base[0] = base64_table[buffer[0] >> 2];
        
        //第二个 6 bit
        base[1] = base64_table[(buffer[0] & 0b11) << 4 | 0];
        
        base[2] = '=';
        base[3] = '=';
        [base64 appendBytes:base length:4];
    }else if (data.length%3 == 2){
        [data getBytes:buffer range:NSMakeRange(index, 2)];
        
        //第一个 6 bit
        base[0] = base64_table[buffer[0] >> 2];
        
        //第二个 6 bit
        base[1] = base64_table[(buffer[0] & 0b11) << 4 | (buffer[1] >> 4)];
        
        //第三个 6 bit
        base[2] = base64_table[(buffer[1] & 0b1111) << 2 | 0];
        
        base[3] = '=';
        [base64 appendBytes:base length:4];
    }
    
    return [[NSString alloc] initWithData:base64 encoding:NSUTF8StringEncoding];
}

#pragma mark - base64 解码
+ (NSData *)base64Decode:(NSString *)base64String
{
    NSData *data = [base64String dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data.length % 4) {
        NSLog(@"Base64 decode error : %@",[NSError errorWithDomain:@"The source data is not base64 code ." code:0 userInfo:nil]);
        return nil;
    }
    
    NSMutableData *srcData = [NSMutableData new];
    
    unsigned char buffer[3] = {0};
    unsigned char base[4] = {0};
    
    int32_t temp = 0;
    
    NSRange range = NSMakeRange(0, 4);
    
    while (range.location + range.length < data.length) {
        [data getBytes:base range:range];
        
        temp |= deBase64_table[base[0]];
        temp <<= 6;
        temp |= deBase64_table[base[1]];
        temp <<= 6;
        temp |= deBase64_table[base[2]];
        temp <<= 6;
        temp |= deBase64_table[base[3]];
        
        buffer[0] = (temp & 0xFF0000) >> 16;
        buffer[1] = (temp & 0x00FF00) >> 8;
        buffer[2] = (temp & 0x0000FF);
        
        [srcData appendBytes:buffer length:3];
        
        temp = 0;
        range.location += 4;
    }
    
    [data getBytes:base range:range];
    
    if (base[2] == '=') {
        base[2] = 0;
        base[3] = 0;
        
        temp |= deBase64_table[base[0]];
        temp <<= 6;
        temp |= deBase64_table[base[1]];
        
        buffer[0] = temp >> 4;
        
        [srcData appendBytes:buffer length:1];
    }else if (base[3] == '='){
        base[3] = 0;
        
        temp |= deBase64_table[base[0]];
        temp <<= 6;
        temp |= deBase64_table[base[1]];
        temp <<= 6;
        temp |= deBase64_table[base[2]];
        
        buffer[0] = (temp >> 2 & 0xFF00) >> 8;
        buffer[1] = (temp >> 2 & 0x00FF);
        
        [srcData appendBytes:buffer length:2];
    }else {
        temp |= deBase64_table[base[0]];
        temp <<= 6;
        temp |= deBase64_table[base[1]];
        temp <<= 6;
        temp |= deBase64_table[base[2]];
        temp <<= 6;
        temp |= deBase64_table[base[3]];
        
        buffer[0] = (temp & 0xFF0000) >> 16;
        buffer[1] = (temp & 0x00FF00) >> 8;
        buffer[2] = (temp & 0x0000FF);
        
        [srcData appendBytes:buffer length:3];
    }
    
    return [NSData dataWithData:srcData];
}

static const char base64_table[64] =
{
    'A','B','C','D','E','F','G','H',
    'I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X',
    'Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n',
    'o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3',
    '4','5','6','7','8','9','+','/'
};

static const char deBase64_table[] =
{
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x3E,0x00,0x00,0x00,0x3F,
    0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,
    0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x00,0x00,0x00,0x00,0x00,
    0x00,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,
    0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,0x30,0x31,0x32,0x33,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
};

@end

```

测试代码如下：

```
- (IBAction)btnClickedOfBase64:(UIButton *)sender {
    NSString *test = @"this is a test string !";
    NSLog(@"origin string : %@",test);
    
    NSData *data = [test dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"origin data : %@",data);
    
    //编码
    NSString *baseString = [Base64 base64Encode:data];
    NSLog(@"baseString : %@",baseString);
    
    NSString *baseString1 = [data base64EncodedStringWithOptions:0];
    NSLog(@"baseString1 : %@",baseString1);
    
    //解码
    NSData *decodeData = [Base64 base64Decode:baseString];
    NSLog(@"decodeData : %@",decodeData);
    
    NSData *decodeData1 = [[NSData alloc]initWithBase64EncodedString:baseString options:0];
    NSLog(@"decodeData1 : %@",decodeData1);

    //编码
    NSData *base64Data = [data base64EncodedDataWithOptions:0];
    NSLog(@"base64Data : %@",base64Data);
    
    //解码
    NSData *base64DataDecode = [[NSData alloc]initWithBase64EncodedData:base64Data options:0];
    NSLog(@"base64DataDecode : %@",base64DataDecode);
    
    NSString *decodeString = [[NSString alloc]initWithData:base64DataDecode encoding:NSUTF8StringEncoding];
    NSLog(@"decodeString : %@",decodeString);
}
```

