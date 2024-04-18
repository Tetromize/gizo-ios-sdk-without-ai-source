//
//  VideoCaptureManager.m
//  LXFAVFoundation
//
//  Created by Hepburn on 2023/10/16.
//

#import "VideoCaptureManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "CVWrapper.h"
//#import "LogManager.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define START_VIDEO_ANIMATION_DURATION 0.2f                         // 录制视频前的动画时间


typedef enum {
    VideoRecorderStatus_Start,
    VideoRecorderStatus_Stop,
    VideoRecorderStatus_Pause,
    VideoRecorderStatus_Resume,
    VideoRecorderStatus_Status
} VideoRecorderStatus;

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface VideoCaptureManager() <AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate/**, AVCaptureAudioDataOutputSampleBufferDelegate**/>

@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (strong, nonatomic) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, assign) BOOL canWrite;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (assign, nonatomic) Boolean isCameraMatrix;

@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) UIView *previewView;
@property (assign, nonatomic) BOOL previewEnable;

@property (nonatomic, nonatomic) NSString* matrixText;

@end

@implementation VideoCaptureManager

- (id)init {
    self = [super init];
    if (self) {
        _isShooting = NO;
        _canWrite = NO;
        _isCameraMatrix = NO;
        _isPythonUsing = NO;
        _isLowBattery = NO;
    }
    return self;
}

- (void)attachPreview:(UIView *)previewView {
    self.previewView = previewView;
    if (previewView != nil) {
        [self setupCaptureVideoPreviewLayer];
    }
    else {
        [self cleanCaptureVideoPreviewLayer];
    }
}

- (void)lockPreview {
    if (!_previewEnable) {
        return;
    }
    _previewEnable = false;
    [self cleanCaptureVideoPreviewLayer];
    self.previewView = nil;
}

- (void)unlockPreview:(UIView *)previewView {
    if (_previewEnable) {
        return;
    }
    _previewEnable = true;
    self.previewView = previewView;
    [self setupCaptureVideoPreviewLayer];
}

- (void)cleanCaptureVideoPreviewLayer {
    if (_captureVideoPreviewLayer) {
        [_captureVideoPreviewLayer removeFromSuperlayer];
        _captureVideoPreviewLayer = nil;
    }
}

- (void)setupCaptureVideoPreviewLayer {
    [self cleanCaptureVideoPreviewLayer];
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    CALayer *layer = self.previewView.layer;
    _captureVideoPreviewLayer.frame = self.previewView.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    [layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
}

- (void)startVideoCapture {
    NSLog(@"startVideoCapture");
    [self requestAuthorizationForVideo];
    [self setupVideo];
    [self startSession];
}

- (void)stopVideoCapture {
    NSLog(@"stopVideoCapture");
    [self stopSession];
}


#pragma mark - 懒加载
- (AVCaptureSession *)captureSession {
    if (_captureSession == nil){
        _captureSession = [[AVCaptureSession alloc] init];
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
    }
    return _captureSession;
}

- (dispatch_queue_t)videoQueue {
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("VideoCaptureManager", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}

- (void)setupVideo {
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    if (!captureDevice){
        NSLog(@"captureDevice failed");
        return;
    }
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"videoInput error:%@", error);
        return;
    }
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    }
    AVCaptureConnection* connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([connection isCameraIntrinsicMatrixDeliverySupported]) {
        [connection setCameraIntrinsicMatrixDeliveryEnabled:YES];
    }
    [self updateFocusLocked:captureDevice lensPosition:0.8];
}

- (void)updateFocusLocked:(AVCaptureDevice *)captureDevice lensPosition:(float)lensPosition {
    NSLog(@"updateFocusLocked %f", lensPosition);
    if ([captureDevice isLockingFocusWithCustomLensPositionSupported]) {
        NSError *error = nil;
        if ([captureDevice lockForConfiguration:&error]) {
            __weak AVCaptureDevice *cd = captureDevice;
            [captureDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:^(CMTime syncTime) {
                [cd unlockForConfiguration];
            }];
        }
    }
}

- (void)startSession {
    if (![self.captureSession isRunning]) {
        [self.captureSession startRunning];
    }
}

- (void)stopSession{
    if (_captureSession == nil) {
        return;
    }
    if ([self.captureSession isRunning]) {
        [self.captureSession stopRunning];
    }
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession =  [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    for (AVCaptureDevice *device in deviceDiscoverySession.devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange {
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }
    else{
        NSLog(@"changeDeviceProperty error:%@",error.localizedDescription);
    }
}

- (void)startVideoRecorder:(NSString *)videoPath {
    if (videoPath != nil) {
        self.videoURL = [NSURL fileURLWithPath:videoPath];
    }
    NSLog(@"startVideoRecorder");
    [self.delegate videoCameraIntrinsicMatrix:_matrixText];
    _isShooting = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(START_VIDEO_ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setUpWriter];
    });
}

- (void)stopVideoRecorder {
    NSLog(@"stopVideoRecorder");
    if (_isShooting) {
        _isShooting = NO;
        __weak __typeof(self)weakSelf = self;
        if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                weakSelf.canWrite = NO;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterVideoInput = nil;
                if ([weakSelf.delegate respondsToSelector:@selector(onRecordingEvent:)]) {
                    [weakSelf.delegate onRecordingEvent:VideoRecorderStatus_Stop];
                }
            }];
        }
    }
}

- (void)setUpWriter {
    if (self.videoURL == nil) {
        return;
    }
    NSError *error = nil;
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:&error];
    if (error != nil) {
        if ([self.delegate respondsToSelector:@selector(onRecordingEvent:)]) {
            [self.delegate onRecordingEvent:VideoRecorderStatus_Stop];
        }
        return;
    }
    NSInteger numPixels = kScreenWidth * kScreenHeight;
    
    CGFloat bitsPerPixel = 12.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(15),
                                             AVVideoMaxKeyFrameIntervalKey : @(15),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    CGFloat width = 1280;
    CGFloat height = 720;
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
                                       AVVideoWidthKey : @(width),
                                       AVVideoHeightKey : @(height),
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;

    if ([_assetWriter canAddInput:_assetWriterVideoInput]){
        [_assetWriter addInput:_assetWriterVideoInput];
        if ([self.delegate respondsToSelector:@selector(onRecordingEvent:)]) {
            [self.delegate onRecordingEvent:VideoRecorderStatus_Start];
        }
    }
    else{
        NSLog(@"AssetWriter videoInput append Failed");
        if ([self.delegate respondsToSelector:@selector(onRecordingEvent:)]) {
            [self.delegate onRecordingEvent:VideoRecorderStatus_Stop];
        }
    }
    
    _canWrite = NO;
}

- (void)getCameraIntrinsicMatrix:(CMSampleBufferRef)sampleBuffer {
    if (!_isCameraMatrix) {
        CFTypeRef cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil);
        if (cameraIntrinsicData != nil) {
            CFDataRef cfdr = (CFDataRef)cameraIntrinsicData;
            matrix_float3x3* intrinsicMatrix = (matrix_float3x3*)(CFDataGetBytePtr(cfdr));
            if (intrinsicMatrix != nil) {
                NSMutableString *text = [[NSMutableString alloc] init];
                [text appendString:@"["];
                float matrixs[3][3];
                for (int i = 0; i < 3; i ++) {
                    simd_float3 simi = intrinsicMatrix->columns[i];
                    matrixs[i][0] = simi[0];
                    matrixs[i][1] = simi[1];
                    matrixs[i][2] = simi[2];
                }
                for (int j = 0; j < 3; j ++) {
                    NSString *first = [self formatFloat:matrixs[0][j]];
                    NSString *second = [self formatFloat:matrixs[1][j]];
                    NSString *third = [self formatFloat:matrixs[2][j]];
                    [text appendFormat:@"{\"first\":\"%@\",\"second\":\"%@\",\"third\":\"%@\"}", first, second, third];
                    if (j > 0) {
                        [text appendString:@","];
                    }
                }
                [text appendString:@"]"];
                NSLog(@"intrinsicMatrix:%@", text);
                _matrixText = text;
//                [self.delegate videoCameraIntrinsicMatrix:text];
            }
        }
        _isCameraMatrix = YES;
    }
}

- (NSString *)formatFloat:(float)value {
    NSString *str = [NSString stringWithFormat:@"%.3f", value];
    str = [str stringByReplacingOccurrencesOfString:@"0.000" withString:@"0"];
    str = [str stringByReplacingOccurrencesOfString:@"1.000" withString:@"1"];
    return str;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
        if (self.isLowBattery) {
            return;
        }
        @synchronized(self){
            @autoreleasepool{
                [self getCameraIntrinsicMatrix:sampleBuffer];
                if (!self.isPythonUsing && self.delegate && [self.delegate respondsToSelector:@selector(videoCaptureSampleBuffer:)]) {
//                    [LogManager.shared printLog:@"Start"];
//                    UIImage *image = [CVWrapper imageFromSampleBuffer:sampleBuffer];
//                    [self.delegate videoCaptureSampleBuffer:image];
                }
                if (_isShooting) {
                    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                }
            }
        }
    }
}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    @autoreleasepool{
        if (!self.canWrite && mediaType == AVMediaTypeVideo){
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            self.canWrite = YES;
        }
        if (mediaType == AVMediaTypeVideo){
            if (self.assetWriterVideoInput.readyForMoreMediaData){
                BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                if (!success){
                    NSLog(@"assetWriterVideoInput appendSampleBuffer fail");
                    @synchronized (self){
                        [self stopVideoRecorder];
                    }
                }
            }
        }
    }
}

#pragma mark - Authorization
- (void)requestAuthorizationForVideo {
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus != AVAuthorizationStatusAuthorized) {
        NSLog(@"No Camera Authorization");
    }
}
#define kDocumentPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

+ (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+ (void)makeColorVideo {
    UIImage *image = [VideoCaptureManager imageWithColor:UIColor.blackColor size:CGSizeMake(1280, 720)];
    NSDate *date = [NSDate date];
    NSString *string = [NSString stringWithFormat:@"%ld.mp4",(unsigned long)(date.timeIntervalSince1970 * 1000)];
    NSString *cachePath = [kDocumentPath stringByAppendingPathComponent:string];
    [VideoCaptureManager compressImages:@[image, image] path:cachePath completion:^(NSURL * _Nonnull outurl) {
        NSLog(@"compressImages url:%@", outurl);
    }];
}

+ (void)compressImages:(NSArray <UIImage *> *)images path:(NSString *)path completion:(void(^)(NSURL *outurl))block {
    if (images.count == 0) {
        return;
    }
    CGSize size = CGSizeMake(1280, 720);
    NSMutableArray *imageArray = [NSMutableArray array];
//    for (UIImage *image in images) {
//        UIImage *finalImage = [CVWrapper resize:image dsize:size];
//        [imageArray addObject:finalImage];
//    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL *exportUrl = [NSURL fileURLWithPath:path];
    __block AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:exportUrl fileType:AVFileTypeMPEG4 error:nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecTypeH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput]) {
        [videoWriter addInput:writerInput];
    }
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    int __block frame = 0;
    int seconds = 1;
    int frameRate = 30;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([writerInput isReadyForMoreMediaData]) {
            if (++frame > seconds * frameRate) {
                [writerInput markAsFinished];
                //[videoWriter_ finishWriting];
                if(videoWriter.status == AVAssetWriterStatusWriting){
                    NSCondition *cond = [[NSCondition alloc] init];
                    [cond lock];
                    [videoWriter finishWritingWithCompletionHandler:^{
                        [cond lock];
                        [cond signal];
                        [cond unlock];
                    }];
                    [cond wait];
                    [cond unlock];
                    !block?:block(exportUrl);
                }
                break;
            }
            int idx = (int)(frame/frameRate * images.count/seconds);
            if (idx >= images.count) {
                idx = (int)(images.count - 1);
            }
            UIImage *img = imageArray[idx];
            CVPixelBufferRef buffer = [VideoCaptureManager pixelBufferFromCGImage:img.CGImage size:size];
            if (buffer) {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, frameRate)]) {
                    NSLog(@"fail");
                }
                else {
                    NSLog(@"success:%d",(int)frame);
                }
                CFRelease(buffer);
            }
        }
    }];
}

@end
