matrix World;
matrix LightSpaceMat;
matrix LightSpaceMatFar;
struct VertexShaderInput
{
    float4 Position : POSITION0;
    
    
};
struct VertexShaderOutput
{
   
    float4 Position : SV_POSITION;
     
 
    float2 Depth : TEXCOORD0;

 
};

struct PixelShaderOutput
{
    float4 Color : COLOR0;
 
};


VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput) 0;

    float4 worldPosition = mul(input.Position, World);
    
    float4 projectionPositionNear = mul(worldPosition, LightSpaceMat);
    output.Position = projectionPositionNear;
    output.Depth.xy = projectionPositionNear.z / projectionPositionNear.w;
//    output.PositionFar = projectionPositionFar;
 
    return output;
}

PixelShaderOutput PixelShaderFunction(VertexShaderOutput input)
{
    PixelShaderOutput output = (PixelShaderOutput) 0;
   
    
    output.Color = float4(input.Depth.x, input.Depth.x, input.Depth.x, 1);
 
//    output.ShadowFar = float4(input.PositionFar.z / input.PositionFar.w, input.PositionFar.z / input.PositionFar.w, input.PositionFar.z / input.PositionFar.w, 1);
    return output;
}
technique ShadowMap
{
    pass Pass0
    {
        VertexShader = compile vs_4_0_level_9_1 VertexShaderFunction();
        PixelShader = compile ps_4_0_level_9_1 PixelShaderFunction();
    }
}