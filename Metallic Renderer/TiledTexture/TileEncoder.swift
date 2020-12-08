//
//  TileEncoder.swift
//  Metallic
//
//  Created by Akshay on 04/12/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Metal


//TODO: Long term - Evaluate multiple View port rendering process
struct TileEncoder {
    let pipeline: MTLRenderPipelineState

    func encode(tile: TextureTile,
                targetTexture: MTLTexture,
                commandbuffer: MTLCommandBuffer,
                mvpBuffer: MTLBuffer,
                scissorRect: MTLScissorRect? = nil) {

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 1, alpha: 1)

        guard let encoder = commandbuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        if let _scissorRect = scissorRect {
            encoder.setScissorRect(_scissorRect)
        }
        encoder.setRenderPipelineState(pipeline)

        encoder.setVertexBuffer(tile.buffer.buffer, offset: 0, index: 0)
        encoder.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        encoder.setFragmentTexture(tile.texture, index: 0)
        encoder.label = "Tiling"
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandbuffer.addCompletedHandler { buffer in
            print("Buffer Completed")
        }
    }
}
