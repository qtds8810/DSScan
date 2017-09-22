//
//  UIImage+QRCode.swift
//  12-QRCode
//
//  Created by 左得胜 on 2017/1/2.
//  Copyright © 2017年 左得胜. All rights reserved.
//

import UIKit
import CoreImage
import ZXingObjC

extension UIImage {
    
    /// 识别图片二维码：zxing识别结果，系统的cidetector在iOS8不能用
    ///
    /// - Returns: 二维码内容
    func recognizeQRCodeWithZXing() -> String? {
        let source = ZXCGImageLuminanceSource(cgImage: self.cgImage!)
        let binarizer = ZXHybridBinarizer(source: source)
        let bitmap = ZXBinaryBitmap(binarizer: binarizer)
        
        let hints = ZXDecodeHints()
        let reader = ZXMultiFormatReader()
        let result = try? reader.decode(bitmap, hints: hints)
        
        if result != nil {
            QL1(result?.text)
            return result?.text
        } else {
            return nil
        }
    }
    
    /// 识别图片二维码：利用系统侧cidetecotor来识别
    ///
    /// - Returns: 二维码内容
    func recognizeQRCode() -> String? {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        guard let features = detector?.features(in: CoreImage.CIImage(cgImage: self.cgImage!)) else {
            return nil
        }
        guard features.count > 0 else {
            return nil
        }
        let feature = features.first as? CIQRCodeFeature
        return feature?.messageString
    }
        
    /// 获取圆角图片（带边框）
    func getRoundRectImage(size: CGFloat, radius: CGFloat, borderWidth: CGFloat? = nil, borderColor: UIColor? = nil) -> UIImage {
        let scale = self.size.width / size
        
        // 初始化
        var defaultBorderWidth: CGFloat = 0
        var defaultDorderColor = UIColor.clear
        
        if let borderWidth = borderWidth {
            defaultBorderWidth = borderWidth * scale
        }
        if let borderColor = borderColor {
            defaultDorderColor = borderColor
        }
        
        let radius = radius * scale
        let react = CGRect(x: defaultBorderWidth, y: defaultBorderWidth, width: self.size.width - 2 * defaultBorderWidth, height: self.size.height - 2 * defaultBorderWidth)
        
        // 绘制图片
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let path = UIBezierPath(roundedRect: react, cornerRadius: radius)
        
        // 绘制边框
        path.lineWidth = defaultBorderWidth
        defaultDorderColor.setStroke()
        path.stroke()
        path.addClip()
        
        // 画图片
        draw(in: react)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
