//
//  TiledTextureRenderer.swift
//  Metallic
//
//  Created by Akshay on 03/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit
import Metal

private let commandQueue = mtlDevice.makeCommandQueue()!

final class TiledTextureRenderer {

    private let tileEncoder : FTTextureTileEncoder
    private let finalRenderTexture : MTLTexture
    private let layer: CAMetalLayer
    private var mvpBuffer : MTLBuffer

    init(metalLayer:CAMetalLayer) {
        self.layer = metalLayer
        if let _pipeline = try? PipelineHelper.createTileTexturePipeline(pixelFormat: metalLayer.pixelFormat) {
            tileEncoder = FTTextureTileEncoder(pipeline: _pipeline)
            finalRenderTexture = TextureHelper.createTexture(with: metalLayer.bounds.size, device:mtlDevice)
            let vpSize = layer.bounds.size
            var projection = simd_float4x4.ortho2d(width: Float(vpSize.width), height: Float(vpSize.height))
            mvpBuffer = mtlDevice.makeBuffer(bytes: &projection,
                                             length: MemoryLayout<simd_float4x4>.stride,
                                             options: .storageModeShared)!

        } else {
            fatalError("unable to create the pipeline")
        }
    }

    func renderTiles(textures:[FTTextureTile]) {
        guard let drawble = layer.nextDrawable() else {
            preconditionFailure("Unable to get drawble")
        }
        executeRenderCommands { commandBuffer in
            for tile in textures {
                tileEncoder.encode(tile: tile,
                                   targetTexture: drawble.texture,
                                   commandbuffer: commandBuffer,
                                   mvpBuffer: mvpBuffer)
            }
            commandBuffer.present(drawble)
        }
    }

}

extension TiledTextureRenderer {

}

func executeRenderCommands(execution: (_ commandBuffer: MTLCommandBuffer) -> Void) {
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        fatalError("Failed to create on-screen command buffer");
    }
    execution(commandBuffer)
    commandBuffer.commit()
}
