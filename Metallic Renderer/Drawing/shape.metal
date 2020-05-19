//
//  shape.metal
//  Metallic
//
//  Created by Akshay on 20/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//


#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct VertexOut {
    vector_float4 position [[position]];
    vector_float4 color;
};

vertex VertexOut vertexShapes(const constant vector_float2 *vertexArray [[buffer(0)]],
                              unsigned int vid [[vertex_id]],
                              constant float4x4 &mvp_matrix [[ buffer(1) ]]) {
    vector_float2 currentVertex = vertexArray[vid];
    VertexOut output;
    float2 pixelSpacePosition = currentVertex.xy;
//    output.position = float4(pixelSpacePosition,0,1)*mvp_matrix;

    output.position = vector_float4(currentVertex.x, currentVertex.y, 0, 1);
    output.color = vector_float4(1,1,1,1);

    return output;
}

fragment vector_float4 fragmentShapes(VertexOut interpolated [[stage_in]]){
    return interpolated.color;
}
