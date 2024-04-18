////
////  OpenCVManager.swift
////  Gizo
////
////  Created by Hepburn on 2023/9/25.
////
//
//import Foundation
//import UIKit
//@_implementationOnly import PythonKit
//
//class OpenCVManager {
//    private let sc: SimplifiedCamConversion = SimplifiedCamConversion()
//    public var np: PythonObject?
//    static let shared = OpenCVManager()
//    
//    init() {
//        self.np = Python.import("numpy")
////        let dw = np!.mod(80, 32)
////        print("dw=", dw)
//    }
//    
//    func getRandomColor() -> Int {
//        let number: Int = Int(arc4random())
//        return number%255
//    }
//    
//    func plot_one_box(x: [Int], img: UIImage, color: UIColor?=nil, label: String?=nil, line_thickness: Int=3) {
//        // Plots one bounding box on image img
//        let color = UIColor.init(red: 0, green: 1, blue: 1, alpha: 1.0)
//        let p1 = CGPoint.init(x: x[0], y: x[1])
//        var p2 = CGPoint.init(x: x[2], y: x[3])
//        // yellow box
//        CVWrapper.rectangle(img, pt1: p1, pt2: p2, color: color)
//        if label != nil {
//            let tl = round(0.002 * (img.size.width + img.size.height) / 2) + 1
//            let tf = max(tl - 1, 1)  // font thickness
//            let t_size = CVWrapper.getTextSize(label!, font: 0, fontScale: tl/3, thickness: Int32(tf))
//            p2 = CGPoint.init(x: p1.x+t_size.width, y: p1.y-t_size.height-3)
////            let t_size = cv2.getTextSize(label, 0, fontScale=tl / 3, thickness=tf)[0]
////            c2 = c1[0] + t_size[0], c1[1] - t_size[1] - 3
//        }
//    }
//    
//    func saveImage(image: UIImage, name: String = "ddd.jpg") {
//        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
//        do {
//            let path = NSString.init(string: docPath!).appendingPathComponent(name)
//            let data = image.jpegData(compressionQuality: 0.9)
//            try data!.write(to: URL.init(fileURLWithPath: path))
//        } catch {
//            print(error)
//        }
//    }
//    
//    func bottom_crop(image: UIImage, crop_size: CGSize) -> UIImage {
//        let img0 = sc.convert(img: image)
////        LogManager.shared().printLog("SimplifiedCamConversion")
//        return CVWrapper.crop(img0, dsize: crop_size)
//    }
//    
//    func letterbox(image: UIImage, new_shape: CGSize=CGSize.init(width:320, height:320), color: UIColor=UIColor.init(white: 0.45, alpha: 1.0), auto: Bool=true, scaleFill: Bool=false, scaleup: Bool=true, stride: Int=32) -> LetterBoxModel {
//        let width = image.size.width
//        let height = image.size.height
//        var r = min(new_shape.width/width, new_shape.height/height)
//        if (!scaleup) {
//            r = min(r, 1.0)
//        }
//        var ratio = CGSize.init(width: r, height: r)
//        var new_unpad = CGSize.init(width: round(width*r), height: round(height*r))
//        var dw = new_shape.width-new_unpad.width
//        var dh = new_shape.height-new_unpad.height
//        if (auto) {
//            if (dw > 0) {
//                let w = np!.mod(Int(dw), stride)
//                dw = CGFloat((w.description as NSString).doubleValue)
//            }
//            let h = np!.mod(Int(dh), stride)
//            dh = CGFloat((h.description as NSString).doubleValue)
//        }
//        else if (scaleFill) {
//            dw = 0
//            dh = 0
//            new_unpad = CGSize.init(width: new_shape.width, height: new_shape.height)
//            ratio = CGSize.init(width: new_shape.width/width, height: new_shape.height/height)
//        }
//        dw = dw/2
//        dh = dh/2
//        
//        var img: UIImage = image
//        if (round(width) != round(new_unpad.width) || round(height) != round(new_unpad.height)) {
//            img = CVWrapper.resize(image, dsize: new_unpad)
//        }
//        let top = Int32(round(dh-0.1))
//        let bottom = Int32(round(dh+0.1))
//        let left = Int32(round(dw-0.1))
//        let right = Int32(round(dw+0.1))
//        img = CVWrapper.copyMakeBorder(img, top: top, bottom: bottom, left: left, right: right, color: color)
//        var result = LetterBoxModel()
//        result.image = img
//        result.ratio = ratio
//        result.dstSize = CGSize.init(width: dw, height: dh)
//        return result
//    }
//
//}
