//
//  String+QRCode.swift
//  12-QRCode
//
//  Created by 左得胜 on 2017/1/2.
//  Copyright © 2017年 左得胜. All rights reserved.
//

/*
 CIImage
 带便图像的对象
 CIFilter
 表示滤镜，使用key-value coding设置输入值，滤镜强度和输入的CIImage 包含了一个对输入图像的引用以及需要应用于数据的滤镜
 CIContext
 用于渲染CIImage，当一个图片被渲染，作用于图片的滤镜链会被应用到原始的图像数据上。 CIContext可以是基于CPU的，输出为CGImageRef，也可以是基与GPU的，开发者可通过Open ES 2.0 画出来
 CIDetector
 CIDetector用于分析CIImage，以得到CIFeature，每个CIDetector都要用一个探测器类型（NSString）来初始化。这个类型用于告诉探测器要找什么特征
 CIFeatureCIFaceFeature
 当一个CIDetector 分析一个图像，返回值是一个根据探测器类型探测到的CIFeature数组。每一个CIFaceFeature都包含了一个面部的CGRect引用，以及检测到的面孔的左眼、右眼、嘴部对应的CGpoint
 */

import UIKit

extension String {
//    /// 生成二维码
//    ///
//    /// - Returns: 黑白普通二维码（大小为300）
//    func generateQRCode() -> UIImage {
//        return generateQRCode(size: nil)
//    }
//    
//    /// 生成二维码
//    ///
//    /// - Parameter size: 设置大小
//    /// - Returns: 生成带大小参数的黑白普通二维码
//    func generateQRCode(size: CGFloat?) -> UIImage {
//        return generateQRCode(size: size, logo: nil)
//    }
//    
//    /// 生成二维码
//    ///
//    /// - Parameter logo: 大小
//    /// - Returns: 图标
//    func generateQRCode(logo: UIImage?) -> UIImage {
//        return generateQRCode(size: nil, logo: logo)
//    }
//    
//    /// 生成二维码
//    ///
//    /// - Parameters:
//    ///   - size: 大小
//    ///   - logo: 图标
//    /// - Returns: 生成大小和Logo的二维码
//    func generateQRCode(size: CGFloat? = nil, logo: UIImage? = nil) -> UIImage {
//        let color = UIColor.black
//        let bgColor = UIColor.white
//        
//        return generateQRCode(size: size, color: color, bgColor: bgColor, logo: logo)
//    }
//    
//    /// 生成二维码
//    ///
//    /// - Parameters:
//    ///   - size: 指定大小
//    ///   - color: 指定颜色
//    ///   - bgColor: 指定背景色
//    ///   - logo: 指定图标
//    /// - Returns: 生成二维码
//    func generateQRCode(size: CGFloat? = nil, color: UIColor? = UIColor.black, bgColor: UIColor? = UIColor.white, logo: UIImage? = nil) -> UIImage {
//        let radius : CGFloat = 5//圆角
//        let borderLineWidth : CGFloat = 1.5//线宽
//        let borderLineColor = UIColor.gray//线颜色
//        let boderWidth : CGFloat = 8//白带宽度
//        let borderColor = UIColor.white//白带颜色
//        
//        return generateQRCode(size: size, color: color, bgColor: bgColor, logo: logo,radius:radius,borderLineWidth: borderLineWidth,borderLineColor: borderLineColor,boderWidth: boderWidth,borderColor: borderColor)
//    }
    
    /// 生成二维码
    ///
    /// - Parameters:
    ///   - size: 指定大小
    ///   - color: 指定颜色
    ///   - bgColor: 指定背景色
    ///   - logo: 指定图标
    ///   - radius: 指定圆角
    ///   - borderLineWidth: 指定线宽
    ///   - borderLineColor: 指定线颜色
    ///   - boderWidth: 指定带宽
    ///   - borderColor: 指定带颜色
    /// - Returns: 生成二维码
    func generateQRCode(size:CGFloat? = nil, color:UIColor? = UIColor.black, bgColor:UIColor? = UIColor.white, logo:UIImage? = nil, radius:CGFloat = 5, borderLineWidth: CGFloat? = 1.5, borderLineColor: UIColor? = UIColor.gray, boderWidth: CGFloat? = 8, borderColor: UIColor? = UIColor.white) -> UIImage {
        let ciImage = generateCIImage(size: size, color: color, bgColor: bgColor)
        let image = UIImage(ciImage: ciImage)
        
        guard let QRCodeLogo = logo else { return image }
        
        let logoWidth = image.size.width/4
        let logoFrame = CGRect(x: (image.size.width - logoWidth) /  2, y: (image.size.width - logoWidth) / 2, width: logoWidth, height: logoWidth)
        
        // 绘制logo
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        //线框
        let logoBorderLineImagae = QRCodeLogo.getRoundRectImage(size: logoWidth, radius: radius, borderWidth: borderLineWidth, borderColor: borderLineColor)
        //边框
        let logoBorderImagae = logoBorderLineImagae.getRoundRectImage(size: logoWidth, radius: radius, borderWidth: boderWidth, borderColor: borderColor)
        
        logoBorderImagae.draw(in: logoFrame)
        
        let QRCodeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return QRCodeImage!
    }
    
    /// 生成CIImage
    func generateCIImage(size: CGFloat?, color: UIColor?, bgColor: UIColor?) -> CIImage {
        //1.缺省值
        var QRCodeSize : CGFloat = 300//默认300
        var QRCodeColor = UIColor.black//默认黑色二维码
        var QRCodeBgColor = UIColor.white//默认白色背景
        
        if let size = size { QRCodeSize = size }
        if let color = color { QRCodeColor = color }
        if let bgColor = bgColor { QRCodeBgColor = bgColor }
        
        
        //2.二维码滤镜
        let contentData = self.data(using: String.Encoding.utf8)
        let fileter = CIFilter(name: "CIQRCodeGenerator")
        
        fileter?.setValue(contentData, forKey: "inputMessage")
        fileter?.setValue("H", forKey: "inputCorrectionLevel")
        
        let ciImage = fileter?.outputImage
        
        
        //3.颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")
        
        colorFilter?.setValue(ciImage, forKey: "inputImage")
        colorFilter?.setValue(CIColor(cgColor: QRCodeColor.cgColor), forKey: "inputColor0")// 二维码颜色
        colorFilter?.setValue(CIColor(cgColor: QRCodeBgColor.cgColor), forKey: "inputColor1")// 背景色
        
        
        //4.生成处理
        let outImage = colorFilter!.outputImage
        let scale = QRCodeSize / outImage!.extent.size.width;
        
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        
        let transformImage = colorFilter!.outputImage!.transformed(by: transform)
        
        return transformImage
    }
    
}
