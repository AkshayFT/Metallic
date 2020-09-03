//
//  ImageShaders.metal
//  Metallic
//
//  Created by Akshay on 19/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} Vertex;

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
} RasterizerData;

// Vertex Function
vertex RasterizerData vertexShaderImage(uint vertexID [[ vertex_id ]],
             constant Vertex *vertexArray [[ buffer(0) ]],
             constant float4x4& mvp_matrix [[buffer(1)]])
{
    RasterizerData out;
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    out.position = float4(pixelSpacePosition,0,1.0)*mvp_matrix;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4 fragmentShaderImage(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   filter::linear);

    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}

