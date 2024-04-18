////
////  SimplifiedCamConversion.swift
////  Gizo
////
////  Created by Hepburn on 2023/9/25.
////
//
//import Foundation
//import UIKit
//
//class SimplifiedCamConversion {
//    public var rect_src2dst: CGRect = CGRect.zero
//    public var rect_dst2src: CGRect = CGRect.zero
//    public var src2dst_size: CGSize = CGSize.zero
//    
//    public let k_src = [[1.218400e+03, 0.000000e+00, 6.336272e+02],
//                     [0.000000e+00, 1.224400e+03, 3.650863e+02],
//                     [0.000000e+00, 0.000000e+00, 1.000000e+00]]
//    public let k_dst = [[7.215377e+02, 0.000000e+00, 6.095593e+02],
//                     [0.000000e+00, 7.215377e+02, 1.728540e+02],
//                     [0.000000e+00, 0.000000e+00, 1.000000e+00]]
//    public let imsize_src = [720.0, 1280.0]
//    public let imsize_dst = [384.0, 1242.0]
//    
//    static public let anchor_grid = [[[[[[12.0, 16.0]]],[[[19.0, 36.0]]],[[[40.0, 28.0]]]]],
//                   [[[[[ 36.0,75.0]]], [[[ 76.0,55.0]]],[[[ 72.0, 146.0]]]]],
//                   [[[[[142.0, 110.0]]], [[[192.0, 243.0]]], [[[459.0, 401.0]]]]]]
//    
//    static public let roi_size = [352, 704]
//    
//    init() {
//        // find the corresponding dst corner points in the src
//        var j1_dst2src = k_src[1][2] + k_src[1][1] * (1 - k_dst[1][2]) / k_dst[1][1]    // 1-based index
//        var j2_dst2src = k_src[1][2] + k_src[1][1] * (imsize_dst[0] - k_dst[1][2]) / k_dst[1][1]
//        var i1_dst2src = k_src[0][2] + k_src[0][0] * (1 - k_dst[0][2]) / k_dst[0][0]
//        var i2_dst2src = k_src[0][2] + k_src[0][0] * (imsize_dst[1] - k_dst[0][2]) / k_dst[0][0]
//        // handle outbound coordinates
//        j1_dst2src = max(j1_dst2src, 1)
//        i1_dst2src = max(i1_dst2src, 1)
//        j2_dst2src = min(j2_dst2src, imsize_src[0])
//        i2_dst2src = min(i2_dst2src, imsize_src[1])
//        // find the corresponding inbound corner points in the dst
//        var j1_src2dst = k_dst[1][2] + k_dst[1][1] * (j1_dst2src - k_src[1][2]) / k_src[1][1]    // 1-based index
//        var j2_src2dst = k_dst[1][2] + k_dst[1][1] * (j2_dst2src - k_src[1][2]) / k_src[1][1]
//        var i1_src2dst = k_dst[0][2] + k_dst[0][0] * (i1_dst2src - k_src[0][2]) / k_src[0][0]
//        var i2_src2dst = k_dst[0][2] + k_dst[0][0] * (i2_dst2src - k_src[0][2]) / k_src[0][0]
//        // round and make 0-based index (src coordinates)
//        j1_src2dst = round(j1_src2dst) - 1
//        j2_src2dst = round(j2_src2dst) - 1
//        i1_src2dst = round(i1_src2dst) - 1
//        i2_src2dst = round(i2_src2dst) - 1
//        // handle outbound coordinates in case of minor loss (just to be sure)
//        j1_src2dst = max(j1_src2dst, 0)
//        i1_src2dst = max(i1_src2dst, 0)
//        j2_src2dst = min(j2_src2dst, imsize_dst[0] - 1)
//        i2_src2dst = min(i2_src2dst, imsize_dst[1] - 1)
//        // round and make 0-based index (dst coordinates)
//        j1_dst2src = round(j1_dst2src) - 1
//        j2_dst2src = round(j2_dst2src) - 1
//        i1_dst2src = round(i1_dst2src) - 1
//        i2_dst2src = round(i2_dst2src) - 1
//
//        let w_src2dst = i2_src2dst - i1_src2dst
//        let h_src2dst = j2_src2dst - j1_src2dst
//
//        self.rect_src2dst = CGRect.init(x: i1_src2dst, y: j1_src2dst, width: w_src2dst, height: j2_src2dst)
//        self.rect_dst2src = CGRect.init(x: i1_dst2src, y: j1_dst2src, width: i2_dst2src, height: j2_dst2src)
//        self.src2dst_size = CGSize.init(width: w_src2dst, height: h_src2dst)      // (width, height) of src in dst
//    }
//    
//    public func convert(img: UIImage) -> UIImage {
//        var drect = self.rect_dst2src
//        let width = min(drect.size.width, img.size.width-drect.origin.x)
//        let height = min(drect.size.height, img.size.height-drect.origin.y)
//        drect.size = CGSize(width: width, height: height-1)
//        let img0 = CVWrapper.crop2(img, drect: drect)
//        let img1 = CVWrapper.resize(img0, dsize: self.src2dst_size)
//        let rect = self.rect_src2dst
//        return CVWrapper.fill(img1, size: CGSize.init(width: imsize_dst[1], height: imsize_dst[0]), rect: rect)
//    }
//}
