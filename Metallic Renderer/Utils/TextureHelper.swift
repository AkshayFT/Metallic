//
//  Texture.swift
//  Metallic
//
//  Created by Akshay on 18/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class TextureHelper {

    static func texture(with image:UIImage) -> MTLTexture {
        guard let cgImage = image.cgImage else {
            preconditionFailure("Unable to convert image to cgImage")
        }
        do {
            let loadOptions : [MTKTextureLoader.Option: Any] = [MTKTextureLoader.Option.allocateMipmaps : false,
                                                                MTKTextureLoader.Option.generateMipmaps : false,
                                                                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
            let loader = MTKTextureLoader(device: mtlDevice)
            let texture = try loader.newTexture(cgImage: cgImage,
                                                options: loadOptions)
            return texture
        } catch {
            preconditionFailure("Unable to create Texture")
        }
    }

    static func createTexture(for imageRef:CGImage, device:MTLDevice) -> MTLTexture {
        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

        let context = CGContext(data: rawData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: options)
        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        let textureDesciptor = MTLTextureDescriptor()
        textureDesciptor.width = width
        textureDesciptor.height = height
        textureDesciptor.pixelFormat = .bgra8Unorm

        guard let texture = device.makeTexture(descriptor: textureDesciptor) else {
            fatalError("Unable to create texture buffer")
        }
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: width, height: height, depth: 1)
        let region = MTLRegion(origin: origin, size: size)

        texture.replace(region: region, mipmapLevel: 0, withBytes: rawData!, bytesPerRow: bytesPerRow)

        return texture
    }

    static func createTexture(with size: CGSize, device: MTLDevice) -> MTLTexture {
        let textureDesc = MTLTextureDescriptor()
        textureDesc.width = size.width.toInt
        textureDesc.height = size.height.toInt
        textureDesc.pixelFormat = .bgra8Unorm
        textureDesc.usage = [.renderTarget,.shaderRead]
        guard let texture = device.makeTexture(descriptor: textureDesc) else {
            fatalError("Unable to create texture")
        }
        return texture
    }


    static func createMultiSampleTexture(with size: CGSize, device: MTLDevice) -> MTLTexture {
        let textureDesc = MTLTextureDescriptor()
        textureDesc.width = size.width.toInt
        textureDesc.height = size.height.toInt
        textureDesc.pixelFormat = .bgra8Unorm
        textureDesc.textureType = .type2DMultisample
        textureDesc.usage = .renderTarget
        textureDesc.sampleCount = 4
        guard let texture = device.makeTexture(descriptor: textureDesc) else {
            fatalError("Unable to create Multi Sample texture")
        }
        return texture
    }
}

extension CGImage {

    static func cgImage(for name:String) -> CGImage {
        #if os(macOS)
        guard let image = NSImage(named: name), let imageRef = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                fatalError("\(name) Image doesn't exist")
        }
        #else
        guard let image = UIImage(named: name), let imageRef = image.cgImage else {
                fatalError("\(name) Image doesn't exist")
        }
        #endif

        return imageRef
    }
}
