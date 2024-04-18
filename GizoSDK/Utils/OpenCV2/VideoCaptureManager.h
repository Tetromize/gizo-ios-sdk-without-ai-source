////
////  VideoCaptureManager.h
////  LXFAVFoundation
////
////  Created by Hepburn on 2023/10/16.
////
//
//#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
//
//NS_ASSUME_NONNULL_BEGIN
//
//@protocol VideoCaptureManagerDelegate <NSObject>
//
//@optional
//
//- (void)videoCaptureSampleBuffer:(UIImage *)image;
//- (void)videoCameraIntrinsicMatrix:(NSString *)text;
//- (void)onRecordingEvent:(int)status;
//
//@end
//
//@interface VideoCaptureManager : NSObject
//
//@property(nonatomic, strong, nullable) id<VideoCaptureManagerDelegate> delegate;
//@property(nonatomic, assign) BOOL isPythonUsing;
//@property(nonatomic, assign) BOOL isLowBattery;
//@property(nonatomic, assign) Boolean isShooting;
//
//- (void)startVideoCapture;
//- (void)stopVideoCapture;
//- (void)startVideoRecorder:(nullable NSString *)videoPath;
//- (void)stopVideoRecorder;
//
//- (void)attachPreview:(nullable UIView *)previewView;
//- (void)lockPreview;
//- (void)unlockPreview:(UIView *)previewView;
//
//+ (void)makeColorVideo;
//
//@end
//
//NS_ASSUME_NONNULL_END
