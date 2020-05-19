//
//  FTTextureQuadEncoder.swift
//  NSMetalRender
//
//  Created by Akshay on 12/02/20.
//  Copyright © 2020 Fluid Touch. All rights reserved.
//

import MetalKit

final class FTTextureQuadEncoder {

    private let mpQuad: FTQuadEncoder

    init(textureSize: CGSize, contentScale: CGFloat) {
        mpQuad = FTQuadEncoder(with: textureSize, scale: contentScale)
    }

    func copy(sourceTexture: MTLTexture,
              targetTexture: MTLTexture,
              commandBuffer: MTLCommandBuffer,
              mvpMatrixBuffer: MTLBuffer,
              pixelFormat: MTLPixelFormat) {

        let pipelineToUse = try! PipelineHelper.createTextureCopyPipeline(device: mtlDevice, pixelFormat: pixelFormat)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 1, green: 1, blue: 1, alpha: 1)

        //Render the points into the canvas
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return;
        }

        commandEncoder.setRenderPipelineState(pipelineToUse)
        commandEncoder.setVertexBuffer(mvpMatrixBuffer, offset: 0, index: 2)

        commandEncoder.setFragmentTexture(sourceTexture, index: 0)
        mpQuad.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: targetTexture.width, height: targetTexture.height));
        mpQuad.encode(renderEncoder: commandEncoder, commandBuffer: commandBuffer)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
        commandEncoder.endEncoding()
    }
}
