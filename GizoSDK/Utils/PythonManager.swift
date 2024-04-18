////
////  PythonManager.swift
////  Gizo
////
////  Created by Hepburn on 2023/8/30.
////
//
//import Foundation
//@_implementationOnly import PythonKit
//@_implementationOnly import NumPySupport
//@_implementationOnly import PythonSupport
//import UIKit
//import CoreML
//import AVFoundation
//
//class PythonManager {
//    private var numpy: PythonObject?
//    private var demo: PythonObject?
//    private var model: MLModel?
//    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
//    public var isModelLoaded: Bool = false
//    static let sharedInstance = PythonManager()
//    
//    init() {
//        PythonSupport.initialize()
//        do {
//            let sys = Python.import("sys")
//            print("Python \(sys.version_info.major).\(sys.version_info.minor)")
//            print("Python Version: \(sys.version)")
//            print("Python Encoding: \(sys.getdefaultencoding().upper())")
//            
//            let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
//            print("%@", docPath as Any)
//            if (UserDefaults.standard.object(forKey: "isInstalled") == nil) {
//                print("unzip file")
//                copyPythonFile(name: "python-stdlib", dstPath: docPath!)
//                copyPythonFile(name: "site-packages", dstPath: docPath!)
//                UserDefaults.standard.set("1", forKey: "isInstalled")
//                UserDefaults.standard.synchronize()
//                print("unzip file ok")
//            }
//            sys.path.append(docPath)
//            let path1 = docPath!+"/python-stdlib"
//            sys.path.append(path1)
//            let path2 = docPath!+"/site-packages"
//            sys.path.insert(1, path2)
//            print("Python Path: \(sys.path)")
//            
//            copyPythonFile(name: "demo.py", dstPath: docPath!)
//            copyPythonFile(name: "roi.py", dstPath: docPath!)
//
//            NumPySupport.sitePackagesURL.insertPythonPath()
//            PythonSupport.runSimpleString("print('hello')")
//            self.numpy = Python.import("numpy")
//            self.demo = Python.import("demo")
//            
//        }
//        catch {
//            print(error)
//            print("Failed")
//        }
//    }
//    
//    func loadModelInThread(modelPath: String) {
//        print("loadModelInThread modelPath=:\(modelPath)")
//        DispatchQueue.global().async {
//            print("耗时操作 \(Thread.current)")
//            self.loadModel(modelPath: modelPath)
//            DispatchQueue.main.async {
//                print("完成 \(Thread.current)")
//                NSLog("back to main thread")
//                if (self.isModelLoaded) {
//                    GizoCommon.shared.delegate?.setLoadModelObserver(status: LoadModelStatus.LOADED)
//                }
//                else {
//                    GizoCommon.shared.delegate?.setLoadModelObserver(status: LoadModelStatus.NOT_LOADED)
//                }
//            }
//        }
//    }
//    
//    func loadModel(modelPath: String) {
//        do {
//            print("MLModel start")
//            print("modelPath: \(modelPath)")
//            let config: MLModelConfiguration = MLModelConfiguration.init()
//            config.computeUnits = .all
//            self.model = try MLModel.init(contentsOf: URL.init(fileURLWithPath: modelPath), configuration: config)
//            print("MLModel end")
//            self.isModelLoaded = true
//        }
//        catch {
//            print(error)
//            print("Failed")
//        }
//    }
//    
//    func _make_grid(nx: Int=20, ny: Int=20) {
//        let grid = self.demo!._make_grid(nx: nx, ny: ny)
//        print(grid)
//    }
//    
//    func infer(img: UIImage) -> UIImage {
//        let roi_size = SimplifiedCamConversion.roi_size
//        let img1 = OpenCVManager.shared.bottom_crop(image: img, crop_size: CGSize.init(width: roi_size[1], height: roi_size[0]))
//        let model = OpenCVManager.shared.letterbox(image: img1)
////        LogManager.shared().printLog("预处理时间")
//        return model.image!
//        
////        DispatchQueue.global().async {
////            print("耗时操作 \(Thread.current)")
////            let ret = predict(image: model.image!)
////            DispatchQueue.main.async {
////                print("完成 \(Thread.current)")
////                NSLog("back to main thread")
////            }
////        }
//    }
//    
//    func copyPythonFile(name: String, dstPath: String) {
//        do {
//            var bundlePath = Bundle.main.path(forResource: "GizoSDK-iOS_GizoSDK-iOS", ofType: "bundle")
//            if (bundlePath == nil) {
//                print("Gizo.bundle not found")
//                return
//            }
//            bundlePath = bundlePath!.appending("/Gizo.bundle")
//            if (!FileManager.default.fileExists(atPath: bundlePath!)) {
//                print("Gizo.bundle not found!")
//                return
//            }
//            let srcPath = NSURL.fileURL(withPath: bundlePath!).appendingPathComponent(name).path
//            let pyDstPath = NSString.init(string: dstPath).appendingPathComponent(name)
//            print(srcPath)
//            print(pyDstPath)
//            if (FileManager.default.fileExists(atPath: pyDstPath)) {
//                try FileManager.default.removeItem(atPath: pyDstPath)
//            }
//            try FileManager.default.copyItem(atPath: srcPath, toPath: pyDstPath)
//        }
//        catch {
//            print("copyPythonFile Failed")
//        }
//    }
//    
//    func getArrayShape(arr: MLMultiArray) -> [Int] {
//        if #available(iOS 15.0, *) {
//            let array = MLShapedArray<Float32>(converting: arr)
//            return array.shape
//        }
//        else {
//            var numArr: [Int] = [0, 0, 0, 0]
//            var index = 0
//            for i in arr.shape {
//                numArr[index] = i.intValue
//                index = index + 1
//            }
//            return numArr
//        }
//    }
//    
//    func getArrayBuffer(arr: MLMultiArray) -> [Float32] {
//        let c2 = arr.dataPointer.bindMemory(to: Float32.self, capacity: arr.count)
//        return [Float32](UnsafeBufferPointer(start: c2, count: arr.count))
//    }
//    
//    func predict(image: UIImage) -> Float64? {
//        do {
//            if (self.model == nil) {
//                return nil
//            }
//            let pixelBuffer: CVPixelBuffer = CVWrapper.pixelBuffer(from: image.cgImage!).takeUnretainedValue()
//            let input = try MLDictionaryFeatureProvider.init(dictionary: ["colorImage" : pixelBuffer])
//            let output = try self.model!.prediction(from: input)
////            LogManager.shared().printLog("推理时间")
//            let mlarr1 = output.featureValue(for: "var_1506")?.multiArrayValue
//            if (mlarr1 == nil) {
//                return nil
//            }
//            let arr1 = getArrayBuffer(arr: mlarr1!)
//            let shape1 = getArrayShape(arr: mlarr1!)
//            
//            let mlarr2 = output.featureValue(for: "var_1517")?.multiArrayValue
//            if (mlarr2 == nil) {
//                return nil
//            }
//            let arr2 = getArrayBuffer(arr: mlarr2!)
//            let shape2 = getArrayShape(arr: mlarr2!)
//            
//            let mlarr3 = output.featureValue(for: "var_1528")?.multiArrayValue
//            if (mlarr3 == nil) {
//                return nil
//            }
//            let arr3 = getArrayBuffer(arr: mlarr3!)
//            let shape3 = getArrayShape(arr: mlarr3!)
//            
//            let mlarr4 = output.featureValue(for: "var_1773")?.multiArrayValue
//            if (mlarr4 == nil) {
//                return nil
//            }
//            let arr4 = getArrayBuffer(arr: mlarr4!)
//            let shape4 = getArrayShape(arr: mlarr4!)
//            
//            let mlarr5 = output.featureValue(for: "var_2068")?.multiArrayValue
//            if (mlarr5 == nil) {
//                return nil
//            }
//            let arr5 = getArrayBuffer(arr: mlarr5!)
//            let shape5 = getArrayShape(arr: mlarr5!)
//            
//            if (self.demo == nil) {
//                return nil
//            }
//            let ret3 = try self.demo!.test2(arr1, shape1, arr2, shape2, arr3, shape3, arr4, shape4, arr5, shape5)
//            CVWrapper.release(pixelBuffer)
////            LogManager.shared().printLog("模型后处理")
//            return Float64(ret3)
//        }
//        catch {
//            print("Failed")
//        }
//        return nil
//    }
//
//}
