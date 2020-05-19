//
//  ShapeRenderer.swift
//  Metallic
//
//  Created by Akshay on 20/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import MetalKit

final class ShapeRenderer {
    private let device : MTLDevice!
    private let metalLayer : CAMetalLayer!
    private let commandQueue: MTLCommandQueue!

    private var vertexBuffer: MTLBuffer?
    private var mvpBuffer: MTLBuffer?


    private let pipeline_fill: MTLRenderPipelineState!

    init(metalLayer:CAMetalLayer) {
        self.device = metalLayer.device!
        self.metalLayer = metalLayer
        commandQueue = device.makeCommandQueue()

        do {
            pipeline_fill = try PipelineHelper.createFillShapePipeline(device: device, pixelFormat: self.metalLayer.pixelFormat)
        } catch {
            fatalError("Unable to create Fill pipeline \(error)")
        }

        var projection = simd_float4x4.ortho2d(width: metalLayer.bounds.width.toFloat,
                                               height: metalLayer.bounds.height.toFloat)
        mvpBuffer = device.makeBuffer(bytes: &projection,
                                      length: MemoryLayout<simd_float4x4>.stride,
                                      options: .storageModeShared)


    }

    func drawCircle(drawble: CAMetalDrawable, vertices:[simd_float2]) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].texture = drawble.texture

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}

        renderEncoder.setRenderPipelineState(pipeline_fill)
        renderEncoder.setVertexBytes(vertices, length: vertices.count, index: 0)
        renderEncoder.setVertexBuffer(mvpBuffer, offset: 0, index: 1)

        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

        renderEncoder.endEncoding()
        commandBuffer.present(drawble)
        commandBuffer.commit()

    }
}
