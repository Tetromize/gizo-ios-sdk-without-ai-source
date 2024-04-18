////
////  CVWrapper.m
////  CVOpenTemplate
////
////  Created by Washe on 02/01/2013.
////  Copyright (c) 2013 foundry. All rights reserved.
////
//
//#import "CVWrapper.h"
//#import <UIKit/UIKit.h>
//#ifdef __cplusplus
//#undef NO
//#undef YES
//
//#import <opencv2/stitching.hpp>
//#import <opencv2/imgcodecs.hpp>
//
//#endif
//
//@implementation UIImage (OpenCV)
//
//- (cv::Mat)CVMat {
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
//    CGFloat cols = self.size.width;
//    CGFloat rows = self.size.height;
//    
//    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
//    
//    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
//                                                    cols,                       // Width of bitmap
//                                                    rows,                       // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast |
//                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
//    
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
//    CGContextRelease(contextRef);
//    
//    return cvMat;
//}
//
//- (cv::Mat)CVMat3 {
//    cv::Mat result = [self CVMat];
//    cv::cvtColor(result , result , cv::COLOR_RGBA2RGB);
//    return result;
//}
//
//- (cv::Mat)CVGrayscaleMat {
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGFloat cols = self.size.width;
//    CGFloat rows = self.size.height;
//    
//    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
//    
//    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
//                                                    cols,                       // Width of bitmap
//                                                    rows,                       // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast |
//                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
//    
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
//    CGContextRelease(contextRef);
//    CGColorSpaceRelease(colorSpace);
//    
//    return cvMat;
//}
//
//+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat {
//    return [[UIImage alloc] initWithCVMat:cvMat];
//}
//
//- (id)initWithCVMat:(const cv::Mat&)cvMat {
//    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
//    CGColorSpaceRef colorSpace;
//    
//    if (cvMat.elemSize() == 1) {
//        colorSpace = CGColorSpaceCreateDeviceGray();
//    } else {
//        colorSpace = CGColorSpaceCreateDeviceRGB();
//    }
//    
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
//
//        // Creating CGImage from cv::Mat
//    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
//                                        cvMat.rows,                                 //height
//                                        8,                                          //bits per component
//                                        8 * cvMat.elemSize(),                       //bits per pixel
//                                        cvMat.step[0],                              //bytesPerRow
//                                        colorSpace,                                 //colorspace
//                                        kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,// bitmap info
//                                        provider,                                   //CGDataProviderRef
//                                        NULL,                                       //decode
//                                        false,                                      //should interpolate
//                                        kCGRenderingIntentDefault                   //intent
//                                        );
//    
//        // Getting UIImage from CGImage
//    self = [self initWithCGImage:imageRef];
//    CGImageRelease(imageRef);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(colorSpace);
//    
//    return self;
//}
//
//@end
//
//@implementation CVWrapper
//
//+ (UIImage *)rectangle:(UIImage *)image pt1:(CGPoint)point1 pt2:(CGPoint)point2 color:(UIColor *)color {
//    return [CVWrapper rectangle:image pt1:point1 pt2:point2 color:color thickness:8 lineType:cv::LINE_AA shift:0];
//}
//
//+ (UIImage *)rectangle:(UIImage *)image pt1:(CGPoint)point1 pt2:(CGPoint)point2 color:(UIColor *)color thickness:(int)thickness lineType:(int)lineType shift:(int)shift {
//    cv::Mat img = image.CVMat;
//    cv::Point pt1 = cv::Point(point1.x, point1.y);
//    cv::Point pt2 = cv::Point(point2.x, point2.y);
//    CGFloat red, green, blue, alpha = 0;
//    [color getRed:&red green:&green blue:&blue alpha:&alpha];
//    cv::Scalar color1 = cv::Scalar(red*255, green*255, blue*255, 255);
//    cv::rectangle(img, pt1, pt2, color1, thickness, lineType, shift);
//    return [UIImage imageWithCVMat:img];
//}
//
//+ (UIImage *)resize:(UIImage *)image dsize:(CGSize)dsize {
//    return [CVWrapper resize:image dsize:dsize interpolation:cv::INTER_LINEAR];
//}
//
//+ (UIImage *)resize:(UIImage *)image dsize:(CGSize)dsize interpolation:(int)interpolation {
//    cv::Mat img = image.CVMat;
//    cv::Size size = cv::Size(dsize.width, dsize.height);
//    cv::Mat img2;
//    cv::resize(img, img2, size, interpolation);
//    return [UIImage imageWithCVMat:img2];
//}
//
//+ (UIImage *)crop:(UIImage *)image dsize:(CGSize)dsize {
//    int left = (image.size.width-dsize.width)/2;
//    int top = image.size.height-dsize.height;
//    CGRect rect = CGRectMake(left, top, dsize.width, dsize.height);
//
//    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
//    UIImage *image1 = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
//    CGImageRelease(imageRef);
//    return image1;
//}
//
//+ (UIImage *)crop2:(UIImage *)image drect:(CGRect)rect {
//    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
//    UIImage *image1 = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
//    CGImageRelease(imageRef);
//    return image1;
//}
//
//+ (UIImage *)crop:(UIImage *)image drect:(CGRect)drect {
//    cv::Mat img = image.CVMat;
//    cv::Rect rect = cv::Rect(drect.origin.x, drect.origin.y, drect.size.width, drect.size.height);
//    cv::Mat img2 = img(rect);
//    return [UIImage imageWithCVMat:img2];
//}
//
//+ (UIImage *)fill:(UIImage *)image size:(CGSize)size rect:(CGRect)rect {
//    UIGraphicsBeginImageContext(size);
//    [image drawInRect:rect];
//    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return retImage;
//}
//
//+ (UIImage *)copyMakeBorder:(UIImage *)image top:(int)top bottom:(int)bottom left:(int)left right:(int)right color:(UIColor *)color {
//    return [CVWrapper copyMakeBorder:image top:top bottom:bottom left:left right:right color:color borderType:cv::BORDER_CONSTANT];
//}
//
//+ (UIImage *)copyMakeBorder:(UIImage *)image top:(int)top bottom:(int)bottom left:(int)left right:(int)right color:(UIColor *)color borderType:(int)borderType {
//    cv::Mat img = image.CVMat;
//    cv::Mat img2;
//    CGFloat red, green, blue, alpha = 0;
//    [color getRed:&red green:&green blue:&blue alpha:&alpha];
//    cv::Scalar color1 = cv::Scalar(red*255, green*255, blue*255, 255);
//    cv::copyMakeBorder(img, img2, top, bottom, left, right, borderType, color1);
//    return [UIImage imageWithCVMat:img2];
//}
//
//+ (CGSize)getTextSize:(NSString *)text font:(int)font fontScale:(double)fontScale thickness:(int)thickness {
//    int baseline = 0;
//    cv::Size size = cv::getTextSize([text cStringUsingEncoding:NSUTF8StringEncoding], font, fontScale, thickness, &baseline);
//    return CGSizeMake(size.width, size.height);
//}
//
//+ (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    CVImageBufferRef imageBuffer =  pixelBuffer;
//        
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
//    
//    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
//    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
//    
//    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
//    UIImage *image = [UIImage imageWithCGImage:cgImage];
//    CGImageRelease(cgImage);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(rgbColorSpace);
//    
//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    return image;
//}
//
//+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:true], kCVPixelBufferCGImageCompatibilityKey,
//                             [NSNumber numberWithBool:true], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
//    CVPixelBufferRef pxbuffer = NULL;
//    size_t width = CGImageGetWidth(image);
//    size_t height = CGImageGetHeight(image);
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pxbuffer);
//    if (status != kCVReturnSuccess) {
//        NSLog(@"CVPixelBufferCreate Fail");
//    }
//    CVPixelBufferLockBaseAddress(pxbuffer, 0);
//    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
//    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
//    
//    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
//    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
//    
//    CGColorSpaceRelease(rgbColorSpace);
//    CGContextRelease(context);
//    
//    return pxbuffer;
//}
//
//+ (void)releasePixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    CVPixelBufferRelease(pixelBuffer);
//}
//
//+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBufferRef {
//    CVImageBufferRef pxbuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
//    CIImage *ciImage = [CIImage imageWithCVImageBuffer:pxbuffer];
//    CIContext *ciContext = [CIContext contextWithOptions:nil];
//    CGImageRef cgImage = [ciContext createCGImage:ciImage fromRect:ciImage.extent];
//    UIImage *image = [UIImage imageWithCGImage:cgImage];
//    CGImageRelease(cgImage);
//    return image;
//}
//
//@end
