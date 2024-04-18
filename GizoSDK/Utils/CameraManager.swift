//
//  CameraManager.swift
//  Gizo
//
//  Created by Meysam Farmani on 2/19/24.
//

import AVFoundation
import UIKit
import Combine
import CoreMedia
import simd

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var isSessionRunning = false
    var isRecording = false
    var getImage = false
    var matrixText: String = ""
    var isRecordingTTC = false
    var isEnableAi = true
    private var collisionThreshold: Float = 0.5
    var onChangedImage: ((CIImage) -> Void) = {_ in }
//    var ttcAlertPublisher = PassthroughSubject<TTCAlert, Never>()
//    var depthTTCPublisher = PassthroughSubject<Float64?, Never>()
    let context = CIContext(options: nil)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var captureSession: AVCaptureSession?
    private var frameOutput = AVCaptureVideoDataOutput()
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var videoCompressionSettings: [String: Any]?

    var previewLayer: AVCaptureVideoPreviewLayer?
    private var startTime: CMTime?
    private let frameProcessingQueue = DispatchQueue(label: "FrameProcessingQueue")
    
//    private var dataManager = DataManager.shared
//    private var gpsManager = GPSManager.shared
    
    static let shared = CameraManager()
    
    override init() {
        super.init()
    }

//    static func checkCameraPermission() -> AuthorizationStatus {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            return .authorized
//        case .denied:
//            return .denied
//        case .restricted:
//            return .restricted
//        case .notDetermined:
//            return .notDetermined
//        }
//    }

    static func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
        }
    }
    
    public func checkPermissionsAndSetupSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        default:
            print("Access to the camera is denied or restricted")
        }
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Unable to access back camera")
            return
        }
        
        captureSession?.beginConfiguration()
        
        captureSession?.sessionPreset = .hd1280x720
        
        if captureSession?.canAddInput(input) ?? false {
            captureSession?.addInput(input)
        }

        frameOutput.alwaysDiscardsLateVideoFrames = true
        frameOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        if captureSession?.canAddOutput(frameOutput) ?? false {
            captureSession?.addOutput(frameOutput)
        }

        frameOutput.setSampleBufferDelegate(self, queue: frameProcessingQueue)
        frameOutput.connection(with: .video)?.isCameraIntrinsicMatrixDeliveryEnabled = true

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        self.adjustPreviewLayerOrientation(previewLayer!)
        captureSession?.commitConfiguration()
        setFocusModeLocked(camera: backCamera)
    }
    
    func setFocusModeLocked(camera: AVCaptureDevice){
        do {
            try camera.lockForConfiguration()

            if camera.isFocusModeSupported(.locked) && camera.isLockingFocusWithCustomLensPositionSupported {
                camera.setFocusModeLocked(lensPosition: 1.0) { time in
                }
            }

            camera.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    private func adjustPreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
        if let previewConnection = previewLayer.connection, previewConnection.isVideoOrientationSupported {
            previewConnection.videoOrientation = .landscapeRight
        }
    }

    func startSession() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let captureSession = self.captureSession, !captureSession.isRunning else { return }
            captureSession.startRunning()
            self.isSessionRunning = true
        }
    }

    func stopSession() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let captureSession = self.captureSession, captureSession.isRunning else { return }
            captureSession.stopRunning()
            self.isSessionRunning = false
        }
    }

    private func setupWriter(to folderURL: URL) {
        let fileURL = folderURL.appendingPathComponent("video").appendingPathExtension("mp4")
        
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
            
            let numPixels = UIScreen.main.bounds.width * UIScreen.main.bounds.height
            let bitsPerPixel: CGFloat = 12.0
            let bitsPerSecond = Int(numPixels * bitsPerPixel)
            
            let compressionProperties: [String: Any] = [
                AVVideoAverageBitRateKey: bitsPerSecond,
                AVVideoExpectedSourceFrameRateKey: 15,
                AVVideoMaxKeyFrameIntervalKey: 15,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
            
            let width: CGFloat = 1280
            let height: CGFloat = 720
            videoCompressionSettings = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
                AVVideoCompressionPropertiesKey: compressionProperties
            ]
            
            guard let videoCompressionSettings = videoCompressionSettings else { return }

            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true
            
            if let assetWriter = assetWriter, assetWriter.canAdd(assetWriterInput!) {
                assetWriter.add(assetWriterInput!)
            }
            
            let sourcePixelBufferAttributesDictionary: [String: Any] = [
                String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32ARGB),
                String(kCVPixelBufferWidthKey): 1280,
                String(kCVPixelBufferHeightKey): 720
            ]
            assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput!, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            
        } catch {
            print("Error setting up video writer: \(error.localizedDescription)")
            teardownWriter()
        }
    }
    
    private func teardownWriter() {
        assetWriter = nil
        assetWriterInput = nil
        assetWriterPixelBufferInput = nil
    }
    
    func startRecording(to folderURL: URL)  {
        guard !isRecording else { return }
        setupWriter(to: folderURL)
        isRecording = assetWriter?.startWriting() ?? false
        if isRecording {
            startTime = nil
        } else {
            print("Failed to start writing.")
            teardownWriter()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        assetWriterInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            self?.teardownWriter()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if matrixText.isEmpty {
            getCameraMatrix(sampleBuffer: sampleBuffer)
        }
//        if isEnableAi{
//            let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
//            processFrame(image!)
//        }
       
        guard isRecording, let assetWriterPixelBufferInput = assetWriterPixelBufferInput, let assetWriterInput = assetWriterInput, assetWriterInput.isReadyForMoreMediaData else { return }
       
       if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), startTime != nil {
           let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
           assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: currentTime)
       } else if startTime == nil {
           startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
           assetWriter?.startSession(atSourceTime: startTime!)
       }
   }
   
   private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CIImage? {
       guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
       return CIImage(cvPixelBuffer: imageBuffer)
   }
    
   private func getCameraMatrix(sampleBuffer: CMSampleBuffer) {
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            let intrinsicMatrixPointer = UnsafeRawPointer(CFDataGetBytePtr((cameraIntrinsicData as! CFData))).assumingMemoryBound(to: matrix_float3x3.self)
            let intrinsicMatrix = intrinsicMatrixPointer.pointee
            
            var text = "["
            var matrixs = Array(repeating: Array(repeating: Float(0), count: 3), count: 3)
            
            for i in 0..<3 {
                let column = [intrinsicMatrix.columns.0, intrinsicMatrix.columns.1, intrinsicMatrix.columns.2][i]
                matrixs[i][0] = column[0]
                matrixs[i][1] = column[1]
                matrixs[i][2] = column[2]
            }

            for j in 0..<3 {
                let first = formatFloat(matrixs[0][j])
                let second = formatFloat(matrixs[1][j])
                let third = formatFloat(matrixs[2][j])
                text += "{\"first\":\"\(first)\",\"second\":\"\(second)\",\"third\":\"\(third)\"}"
                if j < 2 {
                    text += ","
                }
            }
            
            text += "]"
            
            self.matrixText = text
        }
    }
    
    private func formatFloat(_ value: Float) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value) // No decimal part
        } else {
            return String(format: "%.3f", value).replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        }
    }
    
//    private func processFrame(_ frame: CIImage) {
//        guard !getImage, PythonManager.sharedInstance.isModelLoaded else { return }
//        getImage = true
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            if let uiImage = self.convertCIImageToUIImage(ciImage: frame) {
//                DispatchQueue.main.async {
//                    let startTime = CFAbsoluteTimeGetCurrent()
//                    let processedImage = PythonManager.sharedInstance.infer(img: uiImage)
//                    let depth = PythonManager.sharedInstance.predict(image: processedImage)
//                    var ttcAllert = self.ttcDepthAnalyze(depthPtn: depth != nil ? String(depth!) : "None", speed: Float(self.gpsManager.locationModel?.speed ?? 0), collisionThreshold: self.collisionThreshold)
//                    self.ttcAlertPublisher.send(ttcAllert)
//                    if self.isRecordingTTC {
//                        self.recordTTC(depth: depth.map { String($0) } ?? "None")
//                    }
//                    self.getImage = false
//                    let endTime = CFAbsoluteTimeGetCurrent()
//                    print("Processing time: \(endTime - startTime) seconds")
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.getImage = false
//                }
//            }
//        }
//    }
    
    private func convertCIImageToUIImage(ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
//    func startRecordingTTC(){
//        self.isRecordingTTC = true
//    }
//    
//    private func recordTTC(depth: String?) {
//        let model = TripCSVTTCModel.init()
//        let speedTTC = GPSManager.shared.locationModel?.speed
//        
//        model.speed = speedTTC
//        if depth?.contains("None") == true {
//            model.ttc = depth ?? "None"
//            model.depth = "N/A"
//        } else if (Int(speedTTC ?? 0)) == 0 {
//            model.ttc = "inf"
//            model.depth = depth ?? "None"
//        } else {
//            if let speed = speedTTC, let depthPtnFloat = Double(depth ?? "0"), speed > 0 {
//                var ttcValue = depthPtnFloat / speed
//                if 11.1 <= speed, speed < 13.89 {
//                    ttcValue = (depthPtnFloat - 2) / speed - 0.1
//                } else if speed >= 13.89 {
//                    ttcValue = (depthPtnFloat - 2) / speed
//                }
//                model.ttc = String(ttcValue)
//            } else {
//                model.ttc = String((depth.flatMap { Float($0) } ?? 0) / (speedTTC.flatMap { Float($0) } ?? 0))
//            }
//            model.depth = depth ?? "0"
//        }
//        dataManager.appendTTCCSV(model: model)
//    }
//        
//    private func ttcDepthAnalyze(depthPtn: String, speed: Float?, collisionThreshold: Float) -> TTCAlert {
//        let limitSpeed: Float = 11.1
//        guard let speed = speed, speed != 0, depthPtn.contains("None") == false else {
//            return .none
//        }
//
//        var ttc = Float(depthPtn) ?? 0 / speed
//        switch speed {
//        case 11.1..<13.89:
//            ttc = (Float(depthPtn) ?? 0 - 2) / speed - 0.1
//        case 13.89...:
//            ttc = (Float(depthPtn) ?? 0 - 2) / speed
//        default:
//            break
//        }
//
//        switch ttc {
//        case _ where speed > limitSpeed && ttc < 1 && ttc > collisionThreshold:
//            return .warning
//        case _ where speed > limitSpeed && ttc <= collisionThreshold:
//            return .danger
//        default:
//            return .none
//        }
//    }
    
    func stopRecordingTTC(){
        self.isRecordingTTC = false
    }
    
    func disableAi(){
        self.isEnableAi = false
    }
    
    func enableAi(){
        self.isEnableAi = true
    }
}

