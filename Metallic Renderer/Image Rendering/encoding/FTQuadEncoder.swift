//
//  FTQuadEncoder.swift
//  NSMetalRender
//
//  Created by Amar on 28/11/18.
//  Copyright © 2018 Fluid Touch. All rights reserved.
//

import UIKit
import simd

class FTQuadEncoder {
    private lazy var  vertexBufferPool : FTLockableBufferPool<FTMetalBuffer<float2>> = {
        return FTLockableBufferPool(withCount: maxBuffersCount, factoryFunction: { () -> FTMetalBuffer<float2> in
            return FTMetalBuffer(vertices: kQuadTexCoords, expand: 0);
        });
    }();

    private var currentBuffer : FTMetalBuffer<float2>?;
    private var m_VertexBuffer : MTLBuffer?

    private let textureSize: CGSize

    private var _bounds: CGRect = CGRect.zero;
    var bounds: CGRect {
        set{
            if(newValue != _bounds) {
                _bounds = newValue
                let pTexCords: [float2] = [
                    float2(Float(_bounds.origin.x / textureSize.width),  Float(_bounds.maxY / textureSize.height)),
                    float2(Float(_bounds.maxX / textureSize.width), Float(_bounds.maxY / textureSize.height)),
                    float2(Float(_bounds.minX / textureSize.width), Float(_bounds.minY / textureSize.height)),
                    float2(Float(_bounds.maxX / textureSize.width),  Float(_bounds.maxY / textureSize.height)),
                    float2(Float(_bounds.minX / textureSize.width), Float(_bounds.minY / textureSize.height)),
                    float2(Float(_bounds.maxX / textureSize.width), Float(_bounds.minY / textureSize.height))]
                self.currentBuffer = self.vertexBufferPool.dequeueItem();
                self.currentBuffer?.set(pTexCords);
            }
        }
        get{
            return _bounds
        }
    }

    init(with inTextureSize: CGSize, scale: CGFloat) {
        self.textureSize = CGSize.scale(inTextureSize, scale);
        m_VertexBuffer = mtlDevice.makeBuffer(bytes: kQuadVertices, length: MemoryLayout<float4>.stride * 6, options: [.cpuCacheModeWriteCombined])        
    }

    func encode(renderEncoder:MTLRenderCommandEncoder, commandBuffer: MTLCommandBuffer)
    {
        renderEncoder.setVertexBuffer(m_VertexBuffer, offset: 0, index: 0)
        if let buffer = self.currentBuffer {
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: 1)
            commandBuffer.addCompletedHandler { _ in
                self.vertexBufferPool.enqueueItem(buffer);
            }
        }
    }
}
