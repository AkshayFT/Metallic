//
//  FTImageRenderer.swift
//  Metallic
//
//  Created by Akshay on 19/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit

final class FTImageRenderer {

    private var mvpBuffer : MTLBuffer
    private var layer: CAMetalLayer

    private let commandQueue = mtlDevice.makeCommandQueue()!

    init(layer: CAMetalLayer) {
        self.layer = layer
        let vpSize = layer.bounds.size
        var projection = simd_float4x4.ortho2d(width: Float(vpSize.width),
                                               height: Float(vpSize.height))
        mvpBuffer = mtlDevice.makeBuffer(bytes: &projection,
                                         length: MemoryLayout<simd_float4x4>.stride,
                                         options: .storageModeShared)!
    }

    func updateSize(_ vpSize: CGSize) {
        var projection = simd_float4x4.ortho2d(width: Float(vpSize.width),
                                               height: Float(vpSize.height))        
        mvpBuffer = mtlDevice.makeBuffer(bytes: &projection,
                                         length: MemoryLayout<simd_float4x4>.stride,
                                         options: .storageModeShared)!
    }

    func render(image: UIImage, rect: CGRect, angle: Float) {

        guard let commandBuffer = commandQueue.makeCommandBuffer(), let drawble = layer.nextDrawable() else {
            preconditionFailure("Unable to create cpmmand Buffer")
        }
        let textureLoader = MTKTextureLoader(device: mtlDevice)
        let texture = textureLoader.texture(with: image)

//        let texture = TextureHelper.texture(with: image, multiSample: true)
        let imageRender = FTImageWithAngleEncoder()
        imageRender.encode(texture: texture,
                           rect: rect,
                           angle: angle,
                           mvpBuffer: mvpBuffer,
                           targetTexture: drawble.texture,
                           commandBuffer: commandBuffer)

        commandBuffer.present(drawble)
        commandBuffer.commit()
    }

}

extension MTKTextureLoader {
    func texture(with image:UIImage, loadOptions : [MTKTextureLoader.Option: Any]? = nil) -> MTLTexture {
        guard let cgImage = image.cgImage else {
            preconditionFailure("Unable to convert image to cgImage")
        }
        do {
            let options : [MTKTextureLoader.Option: Any] = [MTKTextureLoader.Option.allocateMipmaps : true,
                                                            MTKTextureLoader.Option.generateMipmaps : true,
                                                            MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
            let texture = try self.newTexture(cgImage: cgImage,
                                              options: loadOptions ?? options)
            return texture
        } catch {
            preconditionFailure("Unable to create Texture")
        }
    }
}
