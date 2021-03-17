//
//  FTTiledTextureCreation.swift
//  Metallic
//
//  Created by Akshay on 21/12/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import PDFKit

final class FTTiledTextureCreation {

    private static func createTextures(for page: PDFPage, tileRects:[CGRect], scale: CGFloat) -> [FTTextureTile] {

        let pdfBox = PDFDisplayBox.cropBox;
        var pageRect = page.bounds(for: pdfBox)
        if (pageRect.size.width == 0 || pageRect.size.height == 0 ) {
            return [];
        }
        let originalPageRotation = page.rotation;
        let trasnform = page.transform(for: pdfBox);
        pageRect = pageRect.applying(trasnform)
        pageRect.origin = CGPoint.zero;

        var tiles = [FTTextureTile]()

        for rect in tileRects {

            let totalScaleFactor = scale*UIScreen.main.scale

            let scaledTileRect = CGRectScale(rect:rect, scale: totalScaleFactor)
            let scaledPageRect = CGRectScale(rect:pageRect, scale: totalScaleFactor)

            let width = Int(scaledTileRect.width);
            let height = Int(scaledTileRect.height);
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

            context.translateBy(x: 0, y: CGFloat(height));
            context.scaleBy(x: 1, y: -1)

            let dx : CGFloat = -scaledTileRect.origin.x
            let dy : CGFloat = -(scaledTileRect.origin.y)
            context.translateBy(x: dx, y: dy);

            let drawTransorm = drawingTransform(pageRef: page, rect: scaledPageRect, pdfBox: pdfBox)
            context.concatenate(drawTransorm);

            page.displaysAnnotations = true;
            page.draw(with: pdfBox, to: context);

            #if DEBUG
            context.setStrokeColor(UIColor.yellow.cgColor)
            context.stroke(context.boundingBoxOfClipPath, width: 5.0)
            #endif

            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            textureDescriptor.usage = .shaderRead;

            guard let texture = mtlDevice.makeTexture(descriptor: textureDescriptor) else {
                #if DEBUG
                fatalError("Unable to create Tiles Texture, DEBUG for the reason.\(scaledTileRect)")
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
            let tile = FTTextureTile(texture: texture, rect: scaledTileRect);
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
