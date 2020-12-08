//
//  FTTextureCreation.swift
//  Metallic
//
//  Created by Akshay on 08/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import PDFKit
import MetalKit
import CoreGraphics

let maxTextureSize : Int = 4096;//max texture size allowed in metal is 16384;
let bytesPerPixel = 4

final class FTTextureCreation {
//    static func texture(forPage page: PDFPage, toFitIn rect:CGRect, scale: CGFloat) -> MTLTexture? {
//        let texture = generateBGImage(for: page, targetRect: rect, scale:scale)
//        return texture
//    }

//    static func textures(forPage page: PDFPage, tileRects:[CGRect], scale: CGFloat) -> MTLTexture {
//        guard let texture = createTextures(for: page, tileRects: tileRects, scale:scale) else {
//            fatalError("Texture is nil")
//        }
//
//        return texture
//    }


    static func tiles(forPage page: PDFPage, tileRects:[CGRect], scale: CGFloat) -> [TextureTile] {
        let textureTiles = createTextures(for: page, tileRects: tileRects, scale:scale)
        return textureTiles
    }

}

extension FTTextureCreation {

    private static func createTextures(for page: PDFPage, tileRects:[CGRect], scale: CGFloat) -> [TextureTile] {

        let pdfBox = PDFDisplayBox.cropBox;
        var pageRect = page.bounds(for: pdfBox)
        if (pageRect.size.width == 0 || pageRect.size.height == 0 ) {
            return [];
        }
        let originalPageRotation = page.rotation;
        let trasnform = page.transform(for: pdfBox);
        pageRect = pageRect.applying(trasnform)
        pageRect.origin = CGPoint.zero;

        var tiles = [TextureTile]()

        for (index, rect) in tileRects.enumerated() {

            let totalScaleFactor = scale*UIScreen.main.scale

            let tileRect = CGRectScale(rect:rect, scale: totalScaleFactor)
            let scaledPageRect = CGRectScale(rect:pageRect, scale: totalScaleFactor)
            print("Scaled Tile Rect",tileRect, "scaledPageRect", scaledPageRect)

            let width = Int(tileRect.width);
            let height = Int(tileRect.height);
            guard let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride) else {
                continue;
            }
            defer {
                page.rotation = originalPageRotation
                free(rawData);
            }

            guard let context = context(for: rawData, width: width, height: height, scale: scale) else {
                continue;
            }
            let drawTransorm = drawingTransform(pageRef: page, rect: pageRect, pdfBox: pdfBox)
            context.concatenate(drawTransorm);

            let dx : CGFloat = 0
            let dy : CGFloat = rect.maxY
            context.translateBy(x: dx, y: dy);

            //Scaling
            let sx : CGFloat = totalScaleFactor
            let sy : CGFloat = totalScaleFactor
            context.scaleBy(x: sx, y: -sy);


            page.displaysAnnotations = true;
            page.draw(with: pdfBox, to: context);

            #if DEBUG
            if let cgImage = context.makeImage() {
                print("Image", cgImage.width, cgImage.height, totalScaleFactor)
            }
            context.setStrokeColor(UIColor.yellow.cgColor)
            context.stroke(CGRect(origin: .zero, size: CGSize(width: width, height: height)), width: 5.0)
            context.drawPath(using: .stroke)
            #endif

            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            textureDescriptor.usage = .shaderRead;

            guard let texture = mtlDevice.makeTexture(descriptor: textureDescriptor) else {
                #if DEBUG
                fatalError("Unable to create Background Texture, DEBUG for the reason.")
                #else
                continue;
                #endif
            }
            let region = MTLRegionMake2D(0, 0, width, height)
            let bytesPerRow = bytesPerPixel * width
            texture.replace(region: region,
                            mipmapLevel: 0,
                            withBytes: rawData,
                            bytesPerRow: bytesPerRow)
            let tile = TextureTile(texture: texture, rect: rect);
            tiles.append(tile)
        }

        return tiles
    }



    private static func context(for data: UnsafeMutableRawPointer, width: Int, height: Int, scale: CGFloat) -> CGContext? {

        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let cref = CGColorSpaceCreateDeviceRGB();

        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext.init(data: data,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: cref,
                                           bitmapInfo: options) else {
                                            return nil
        }
        context.setFillColor(UIColor.white.cgColor);
        context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)));
        context.interpolationQuality = CGInterpolationQuality.none;
        return context
    }


}


func textureSizeWRTScreen(_ pageSize: CGSize) -> CGSize {
    let screenWidth = UIScreen.main.bounds.size.width;
    let screenHeight = UIScreen.main.bounds.size.height;

    var sizeToCreate = CGSize(width: min(screenWidth,screenHeight), height: max(screenWidth,screenHeight));
    if(pageSize.width > pageSize.height) {
        sizeToCreate = CGSize(width: max(screenWidth,screenHeight), height: min(screenWidth,screenHeight));
    }

    let aspectRect = aspectFittedRect(inRect:CGRect(origin: .zero, size: pageSize), maxRect: CGRect(origin: .zero, size: sizeToCreate));
    return aspectRect.size;
}

func textureScaleWRTScreen(_ pageSize: CGSize) -> CGFloat {
    let textureSize = textureSizeWRTScreen(pageSize);
    var pageScale = pageSize.width/textureSize.width;
    pageScale = bgTextureScale(pageScale);
    return pageScale;
}

func bgTextureScale(_ scale :  CGFloat) -> CGFloat
{
    if scale < 1.5 {
        return 1;
    } else if(scale > 1.5 && scale <= 2.5) {
        return 2;
    }
    else if(scale > 2.5 && scale <= 3.5) {
        return 3;
    }
    else if(scale > 3.5 && scale <= 4.5) {
        return 4;
    }
    else if(scale > 4.5 && scale <= 5.5) {
        return 5;
    }
    else if(scale > 5.5 && scale <= 6.5) {
        return 6;
    }
    else {
        return 1;
    }
}

func aspectFittedRect(inRect:CGRect, maxRect:CGRect) -> CGRect
{
    let originalAspectRatio = inRect.size.width / inRect.size.height
    let maxAspectRatio = maxRect.size.width / maxRect.size.height

    var newRect:CGRect = maxRect
    if originalAspectRatio > maxAspectRatio { // scale by width
        newRect.size.height = maxRect.size.width * inRect.size.height / inRect.size.width
        newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0
    } else {
        newRect.size.width = maxRect.size.height  * inRect.size.width / inRect.size.height
        newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0
    }
    return newRect.integral;
}


func drawingTransform(pageRef:PDFPage,
                      rect:CGRect,
                      pdfBox:PDFDisplayBox) -> CGAffineTransform
{
    var sTransform:CGAffineTransform = CGAffineTransform.identity
    var boxWidth:Float, boxHeight:Float
    var destWidth:Float, destHeight:Float

    var scaleX:Float, scaleY:Float

    let boxRect:CGRect = pageRef.bounds(for: pdfBox)
    boxWidth = Float(boxRect.width)
    boxHeight = Float(boxRect.height)

    var rotate:Int = pageRef.rotation
    // Adjust the page rotation angle to ensure that it is between 0-360 degrees.
    rotate %= 360
    if rotate < 0
        {rotate += 360}

    if rotate == 90 || rotate == 270 {
        let tmp:Float = boxWidth
        boxWidth = boxHeight
        boxHeight = tmp
    }

    // Obtain the origin, width and height of the destination rect.
    destWidth = Float(rect.width)
    destHeight = Float(rect.height)

    scaleX = destWidth/boxWidth
    scaleY = destHeight/boxHeight
    scaleX = min(scaleX, scaleY)
    scaleY = min(scaleX, scaleY)

    sTransform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))

    return sTransform
}

func CGRectScale(rect:CGRect, scale:CGFloat) -> CGRect
{
    var scaledRect:CGRect = rect
    scaledRect.origin.x *= scale
    scaledRect.origin.y *= scale
    scaledRect.size.width *= scale
    scaledRect.size.height *= scale
    return scaledRect
}



func aspectFittedSize(_ inSize : CGSize, max maxSize : CGSize) -> CGSize {
    if (inSize.width <= maxSize.width && inSize.height <= maxSize.height) {
        return inSize;
    }
    let originalAspectRatio = inSize.width / inSize.height;
    let maxAspectRatio = maxSize.width / maxSize.height;

    var newSize = maxSize;
    if (originalAspectRatio > maxAspectRatio) { // scale by width
        newSize.height = CGFloat(Int(maxSize.width * inSize.height / inSize.width));
    } else {
        newSize.width = CGFloat(Int(maxSize.height  * inSize.width / inSize.height));
    }
    return newSize;
}
