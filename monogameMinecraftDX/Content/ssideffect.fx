﻿#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0
	#define PS_SHADERMODEL ps_4_0
#endif

struct VertexShaderInput
{
    float4 Position : POSITION0;
    float2 TexCoords : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoords : TEXCOORD0;
};
matrix View;
matrix Projection;
matrix ViewProjection;
 
matrix ViewOrigin;
float2 PixelSize;
float metallic;
float roughness;
float GameTime;



sampler2D motionVectorTex = sampler_state
{
    Texture = <MotionVectorTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D prevSSIDTex = sampler_state
{
    Texture = <PrevSSIDTexture>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Border;
    AddressV = Border;
};

sampler2D gPositionWS = sampler_state
{
    Texture = <PositionWSTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler2D noiseTex = sampler_state
{
    Texture = <NoiseTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Wrap;
    AddressV = Wrap;
};


sampler2D gNormalWS = sampler_state
{
    Texture = <NormalTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D gAlbedo = sampler_state
{
    Texture = <AlbedoTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D gLum = sampler_state
{
    Texture = <LumTex>;
 
    MipFilter = Point;
    MagFilter = Point;
    MinFilter = Point;
    AddressU = Clamp;
    AddressV = Clamp;
};


float PI = 3.14159265359;

float DistributionGGX(float3 N, float3 H, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(float3 N, float3 V, float3 L, float roughness);
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness);



float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;

    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}


float3 CalculateLightP(float3 W, float3 LP, float3 N, float3 V, float3 albedo, float roughness, float3 F0, bool isDirectionalLight, float3 LightColor)
{
    
    
    float3 Lo = float3(0.0, 0.0, 0.0);
    
    
    
    
    float3 L = normalize(LP - W);
    float3 H = normalize(V + L);
   
    
    float distance = length(LP - W);
    float attenuation = 1.0 / (distance * distance);
    if (isDirectionalLight)
    {
        attenuation = 1;
    }
    float3 radiance = LightColor * attenuation;
    
    
    float D = DistributionGGX(N, H, roughness);
    float G = GeometrySmith(N, V, L, roughness);
    float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);
    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    
    float3 nominator = D * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
    float3 specular = nominator / denominator;
    
    float NdotL = max(dot(N, L), 0.0);
    Lo = (kD * albedo / PI + specular) * radiance * NdotL;
    return Lo;
}
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}
float3 CalculateLightDiffuseP(float3 W, float3 LP, float3 N, float3 V, float3 albedo, float roughness, float3 F0, bool isDirectionalLight, float3 LightColor)
{
    
    
    float3 Lo = float3(0.0, 0.0, 0.0);
    
    
    
    
    float3 L = normalize(LP - W);
    float3 H = normalize(V + L);
   
    
    float distance = length(LP - W);
    float attenuation = 1.0 / (distance * distance);
    if (isDirectionalLight)
    {
        attenuation = 1;
    }
    float3 radiance = LightColor * attenuation;
    
    
    
    float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);
    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    
    
    
    float NdotL = max(dot(N, L), 0.0);
    Lo = (kD * albedo / PI ) * radiance * NdotL;
    return Lo;
}


float2 GetScreenCoordFromWorldPos(float3 worldPos)
{
    float4 offset = float4(worldPos, 1.0);
    offset = mul(offset, ViewProjection);
    offset.xyz /= offset.w;
    offset.xy = offset.xy * 0.5 + 0.5;
    offset.y = 1 - offset.y;
    return offset.xy;
}
float GetViewDepthFromWorldPos(float3 worldPos)
{
    float4 marchDepthView = mul(float4(worldPos, 1), View);
       
    marchDepthView.z = marchDepthView.z;
    return -marchDepthView.z;
}


VertexShaderOutput MainVS(in VertexShaderInput input)
{
	VertexShaderOutput output = (VertexShaderOutput)0;

	output.Position = input.Position;
    output.TexCoords = input.TexCoords;

	return output;
}

sampler gProjectionDepth = sampler_state
{
    Texture = (ProjectionDepthTex);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};
sampler gProjectionDepthM0 = sampler_state
{
    Texture = (ProjectionDepthTexMip0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};

sampler gProjectionDepthM1 = sampler_state
{
    Texture = (ProjectionDepthTexMip1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};
sampler gProjectionDepthM2 = sampler_state
{
    Texture = (ProjectionDepthTexMip2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};
sampler gProjectionDepthM3 = sampler_state
{
    Texture = (ProjectionDepthTexMip3);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};
sampler gProjectionDepthM4 = sampler_state
{
    Texture = (ProjectionDepthTexMip4);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};
sampler gProjectionDepthM5 = sampler_state
{
    Texture = (ProjectionDepthTexMip5);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = Point;
};

sampler2D MERSampler = sampler_state
{
    Texture = <TextureMER>;
 
    MipFilter = Linear;
    MagFilter = Linear;
    MinFilter = Linear;
    AddressU = Border;
    AddressV = Border;
};


samplerCUBE irradianceSampler = sampler_state
{
    texture = <HDRIrradianceTex>;
    magfilter = LINEAR;
    minfilter = LINEAR;
    mipfilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
samplerCUBE irradianceSamplerNight = sampler_state
{
    texture = <HDRIrradianceTexNight>;
    magfilter = LINEAR;
    minfilter = LINEAR;
    mipfilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
float4 ProjectionParams2;
float4 CameraViewTopLeftCorner;
float4 CameraViewXExtent;
float4 CameraViewYExtent;

float3 CameraPos;
float mixValue;
float3 ReconstructViewPos(float2 uv, float linearEyeDepth)
{
  //  uv.y = 1.0 - uv.y;
    float zScale = linearEyeDepth * ProjectionParams2.x; // divide by near plane  
    float3 viewPos = CameraViewTopLeftCorner.xyz + CameraViewXExtent.xyz * uv.x + CameraViewYExtent.xyz * uv.y;
    viewPos *= zScale;
    return viewPos;
}
float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
{
    float a = roughness * roughness;
	
    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	
	// from spherical coordinates to cartesian coordinates - halfway vector
    float3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;
	
	// from tangent-space H vector to world-space sample vector
    float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
    float3 tangent = normalize(cross(up, N));
    float3 bitangent = cross(N, tangent);
	
    float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}
float4 MainPS(VertexShaderOutput input) : COLOR
{
    float linearDepth = 0;
    linearDepth = tex2D(gProjectionDepthM0, input.TexCoords).x;
    if (linearDepth >= 900 || linearDepth <= 0.1)
    {
        discard;
    }
    float3 worldPos = ReconstructViewPos(input.TexCoords, linearDepth) + CameraPos; //tex2D(gPositionWS, input.TexCoords).xyz;
    float3 normal = tex2D(gNormalWS, input.TexCoords).xyz * 2 - 1;
    worldPos = worldPos + normal * 0.1 * length(worldPos - CameraPos) / 150;
  //  float3 randomVec = float3(tex2D(noiseTex, input.TexCoords * 5).r * 2 - 1 + 0.0001 + GameTime, tex2D(noiseTex, input.TexCoords * 5).g * 2 - 1 + 0.0001 + GameTime, 0);
  //  float3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
   // float3 bitangent = cross(normal, tangent);
  //  float3x3 TBN = float3x3(tangent, bitangent, normal);
    float3 mer = tex2D(MERSampler, input.TexCoords).xyz;
    float3 rayOrigin = worldPos + normalize(normal) * 0.01;
    float3 finalColor = 0;
    float2 prevTexCoord = input.TexCoords+tex2D(motionVectorTex, input.TexCoords).xy;
    float4 prevColor = prevTexCoord.x > 0 && prevTexCoord.y > 0 && prevTexCoord.x < 1 && prevTexCoord.y < 1 ? tex2D(prevSSIDTex, prevTexCoord).xyzw : 0;
    float3 F0 = float3(0.04, 0.04, 0.04);
    float3 albedo = pow(tex2D(gAlbedo, input.TexCoords).xyz, 2.2);
    F0 = lerp(F0, albedo, mer.x);
    float3 N = normal;
    float3 W = worldPos;
    float3 V = normalize(CameraPos - W);
            
    float3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, mer.z);
    
    float3 kS = F;
    float3 kD = 1.0 - kS;
    kD *= 1.0 - mer.x;
    
    float finalMixVal = 0;
    
    int i = 0;
    //for (int i = 0; i <1; i++)
    //{
    float2 noiseValue2 = tex2D(noiseTex, input.TexCoords * 5.0 * (0 + 1 + 1) + GameTime * 8 * (0 + 1)).rg;
    float3 sampleDir = ImportanceSampleGGX(noiseValue2, normal, 0.98); //float3(tex2D(noiseTex, input.TexCoords * 5 + float2(i / 10.0, i / 10.0) + GameTime*2.0).r * 2 - 1, tex2D(noiseTex, input.TexCoords * 5 + float2(0.5, 0.5) - float2(i / 10.0, i / 10.0) - GameTime*4.0).g * 2 - 1, tex2D(noiseTex, input.TexCoords * 5 - float2(0.8, 0.8) - float2(i / 10.0, i / 10.0) + GameTime*5.0).b);
       // sampleDir.z = clamp(sampleDir.z, 0.03, 1);
        sampleDir = normalize(sampleDir);
    //    sampleDir = mul(sampleDir, TBN);
        bool isHit = false;
        float2 uv = 0;
        float3 marchPos = 0;
        int mipLevel = 0;
        float strideLen = 1.0;
        float strideNoiseVal = tex2D(noiseTex, input.TexCoords * 5*i + GameTime * 2.5).r - 0.5;
        marchPos = rayOrigin + sampleDir * 0.01;
        float3 preMarchPos = marchPos;
        
    
     
        [unroll(12)]
        for (int j = 0; j < 12; j++)
        {
       /*     if (dot(normal, sampleDir) < 0)
            {
             //   return float4(0, 1, 0, 1);
                isHit = false;
           
                break;
            }*/
            marchPos += sampleDir * 0.15 * (1+strideNoiseVal) * strideLen;
             uv = GetScreenCoordFromWorldPos(marchPos);
            
            
       //     float3 sampleWorldPos = tex2D(gPositionWS, uv).xyz;
      //      float sampleViewDepth = GetViewDepthFromWorldPos(sampleWorldPos);
            float testDepth = GetViewDepthFromWorldPos(marchPos);
            
            
            float sampleDepthM0 = tex2D(gProjectionDepthM0, uv.xy).x;

           float sampleDepthM1 = tex2D(gProjectionDepthM1, uv.xy).x;
           
            float sampleDepthM2 = tex2D(gProjectionDepthM2, uv.xy).x;

            float sampleDepthM3 = tex2D(gProjectionDepthM3, uv.xy).x;

            float sampleDepthM4 = tex2D(gProjectionDepthM4, uv.xy).x;

            float sampleDepthM5 = tex2D(gProjectionDepthM5, uv.xy).x;
          
            float sampleDepthArray[6] = { sampleDepthM0, sampleDepthM1, sampleDepthM2, sampleDepthM3, sampleDepthM4, sampleDepthM5};
            /*GetViewDepthFromWorldPos(worldPosSampled)*/ //tex2D(gProjectionDepth,uv.xy).x;
            float sampleDepth = sampleDepthArray[mipLevel];
            
            if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1)
            {
                isHit = false;
           
                break; // return float4(1, 1, 1, 1);
            }
           
           
                
            if (sampleDepth < testDepth)
            {
            
                if (sampleDepth < testDepth && abs(sampleDepth - testDepth) < 0.3 * (1 + strideNoiseVal) * strideLen && mipLevel <= 0)
                {
                    uv = GetScreenCoordFromWorldPos(marchPos);
                    isHit = true;
           
                    break; //   return float4(0, 0, 0, 1);
                }
                mipLevel=clamp(mipLevel-1,0,5);
                marchPos -= (sampleDir) * 0.15 * (1 + strideNoiseVal) * strideLen;
                strideLen /= 2.0;
            }
            else
            {
                if (mipLevel < 5)
                {
                    mipLevel++;
                    strideLen *= 2;
                     

                }
            }
          
            
           
          

        }
        if (isHit == true)
        {
        //    float3 lum = tex2D(gLum, uv).xyz;
          
            float3 lum1 = tex2D(gLum, uv).xyz;
      
            float3 Lo = lum1;
            finalColor += Lo;
            finalMixVal += 1;

        }
        else
        {
            float3 irradiance = lerp(texCUBE(irradianceSampler, normal).rgb, texCUBE(irradianceSamplerNight, normal).rgb, mixValue);
           
            finalColor += 0;
            finalMixVal += 0;
        }
  //  }      
    finalColor /= clamp(finalMixVal, 1,1);
    finalMixVal /= 1;
   // finalColor = finalColor*0.01+prevColor;
           
  //      finalColor = finalColor * 0.01 + prevColor;
            float3 irradiance1 = finalColor;
            float3 diffuse = irradiance1 * albedo;
    return lerp(float4(diffuse * kD, finalMixVal), prevColor, 0.9);
}








float linearDepthToProjectionDepth(float linearDepth, float near, float far)
{
    return (1.0 / linearDepth - 1.0 / near) / (1.0 / far - 1.0 / near);
}
float ProjectionDepthToLinearDepth(float depth, float near, float far)
{
    float z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));
}
float3 IntersectDepthPlane(float3 RayOrigin, float3 RayDir, float t)
{
    return RayOrigin + RayDir * t;
}

float2 GetCellCount(float2 Size, float Level)
{
    return floor(Size / (Level > 0.0 ? exp2(Level) : 1.0));
}

float2 GetCell(float2 pos, float2 CellCount)
{
    return floor(pos * CellCount);
}
float GetMinimumDepthPlane(float2 p, int mipLevel)
{
    
    float sampleDepthM0 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM0, p.xy).x, 0.1f, 1000.0f);

    float sampleDepthM1 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM1, p.xy).x, 0.1f, 1000.0f);

    float sampleDepthM2 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM2, p.xy).x, 0.1f, 1000.0f);

    float sampleDepthM3 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM3, p.xy).x, 0.1f, 1000.0f);

    float sampleDepthM4 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM4, p.xy).x, 0.1f, 1000.0f);

    float sampleDepthM5 = linearDepthToProjectionDepth(tex2D(gProjectionDepthM5, p.xy).x, 0.1f, 1000.0f);
   
      
        
        
    float sampleDepthArray[6] = { sampleDepthM0, sampleDepthM1, sampleDepthM2, sampleDepthM3, sampleDepthM4, sampleDepthM5 };
    
    return sampleDepthArray[clamp(mipLevel, 0, 5)];

}
float3 IntersectCellBoundary(float3 o, float3 d, float2 cell, float2 cell_count, float2 crossStep, float2 crossOffset)
{
    float3 intersection = 0;
	
    float2 index = cell + crossStep;
    float2 boundary = index / cell_count;
    boundary += crossOffset;
	
    float2 delta = boundary - o.xy;
    delta /= d.xy;
    float t = min(delta.x, delta.y);
	
    intersection = IntersectDepthPlane(o, d, t);
	
    return intersection;
}

bool CrossedCellBoundary(float2 CellIdxA, float2 CellIdxB)
{
    return CellIdxA.x != CellIdxB.x || CellIdxA.y != CellIdxB.y;
}

float4 TransformViewToHScreen(float3 vpos, float2 screenSize)
{
    float4 cpos = mul(float4(vpos, 1), Projection);
    cpos.xy = float2(cpos.x, -cpos.y) * 0.5 + 0.5 * cpos.w; //
    cpos.xy *= screenSize;
    return cpos;
}

float4 MainPSHiZ(VertexShaderOutput input) : COLOR
{
    float linearDepth = 0;
    linearDepth = tex2D(gProjectionDepthM0, input.TexCoords).x;
    if (linearDepth >= 50 || linearDepth <= 0.1)
    {
        discard;
    }
    float3 worldPos = ReconstructViewPos(input.TexCoords, linearDepth) + CameraPos; //tex2D(gPositionWS, input.TexCoords).xyz;
    float3 normal = tex2D(gNormalWS, input.TexCoords).xyz * 2 - 1;
    worldPos = worldPos + normal * 0.6 * linearDepth / 150;
 
    float3 mer = tex2D(MERSampler, input.TexCoords).xyz;
    [branch]
    if (mer.z < 0.4f)
    {
        return float4(0,0,0, 0);
    }
    float3 rayOrigin = worldPos + normalize(normal) * 0.01;
    float3 finalColor = 0;
    float2 prevTexCoord = input.TexCoords + tex2D(motionVectorTex, input.TexCoords).xy;
    float4 prevColor = prevTexCoord.x > 0 && prevTexCoord.y > 0 && prevTexCoord.x < 1 && prevTexCoord.y < 1 ? tex2D(prevSSIDTex, prevTexCoord).xyzw : 0;
    float3 F0 = float3(0.04, 0.04, 0.04);
    float3  albedo = pow(tex2D(gAlbedo, input.TexCoords).xyz, 2.2);
    F0 = lerp(F0, albedo, mer.x);
    float3 N = normal;
    float3 W = worldPos;
    float3 V = normalize(CameraPos - W);
            
    float3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, mer.z);
    
    float3 kS = F;
    float3 kD = 1.0 - kS;
    kD *= 1.0 - mer.x;
    
    float finalMixVal = 0;
    
    int i = 0;
    //for (int i = 0; i <1; i++)
    //{
    float2 noiseValue2 = tex2D(noiseTex, input.TexCoords * 5.0 * (0 + 1 + 1) + GameTime * 0.1 * (0 + 1)).rg;
    float3 sampleDir = ImportanceSampleGGX(noiseValue2, normal, 0.98); //float3(tex2D(noiseTex, input.TexCoords * 5 + float2(i / 10.0, i / 10.0) + GameTime*2.0).r * 2 - 1, tex2D(noiseTex, input.TexCoords * 5 + float2(0.5, 0.5) - float2(i / 10.0, i / 10.0) - GameTime*4.0).g * 2 - 1, tex2D(noiseTex, input.TexCoords * 5 - float2(0.8, 0.8) - float2(i / 10.0, i / 10.0) + GameTime*5.0).b);
       // sampleDir.z = clamp(sampleDir.z, 0.03, 1);
    sampleDir = normalize(sampleDir);
    //    sampleDir = mul(sampleDir, TBN);
   
  
    
    int mipLevel = 0;
   
    
    
    float2 textureSize = 1.0 / PixelSize;
    float maxDist = 100.0f;
    
    float3 rayOriginView = mul(float4(rayOrigin, 1), View).xyz;
    float3 viewRDir = normalize(mul(float4(sampleDir, 1), ViewOrigin).xyz);
    
    float end = rayOriginView.z + viewRDir.z * maxDist;
    if (end > -0.1)
    {
        maxDist = abs(-0.1 - rayOriginView.z) / viewRDir.z;
    }
     
    float3 rayEndView = rayOriginView + viewRDir * maxDist;
    
    float4 startHScreen = TransformViewToHScreen(rayOriginView, textureSize);
    float4 endHScreen = TransformViewToHScreen(rayEndView, textureSize);
    
    
    float startK = 1.0 / startHScreen.w;
    float endK = 1.0 / endHScreen.w;
    float3 startScreen = startHScreen.xyz * startK;
    
    float3 startScreenTextureSpace = float3(startScreen.xy * PixelSize, startScreen.z);
    
    float3 endScreen = endHScreen.xyz * endK;
    float3 endScreenTextureSpace = float3(endScreen.xy * PixelSize, endScreen.z);
    float3 reflectDirTextureSpace = normalize(endScreenTextureSpace - startScreenTextureSpace);
    
    
    
    float outMaxDistance = reflectDirTextureSpace.x >= 0 ? (1 - startScreenTextureSpace.x) / reflectDirTextureSpace.x : -startScreenTextureSpace.x / reflectDirTextureSpace.x;
    outMaxDistance = min(outMaxDistance, reflectDirTextureSpace.y < 0 ? (-startScreenTextureSpace.y / reflectDirTextureSpace.y) : ((1 - startScreenTextureSpace.y) / reflectDirTextureSpace.y));
    outMaxDistance = min(outMaxDistance, reflectDirTextureSpace.z < 0 ? (-startScreenTextureSpace.z / reflectDirTextureSpace.z) : ((1 - startScreenTextureSpace.z) / reflectDirTextureSpace.z));
 
    int maxLevel = 5;
    float2 crossStep = float2(reflectDirTextureSpace.x >= 0 ? 1 : -1, reflectDirTextureSpace.y >= 0 ? 1 : -1);
    float2 crossOffset = crossStep / (1.0 / (PixelSize.xy)) / 128;
    crossStep = saturate(crossStep);
    
    
    float3 ray = startScreenTextureSpace.xyz;
    float minZ = ray.z;
    float maxZ = ray.z + reflectDirTextureSpace.z * outMaxDistance;
    
    float deltaZ = (maxZ - minZ);

    float3 o = ray;
    float3 d = reflectDirTextureSpace * outMaxDistance;
    
    int startLevel = 2;
    int stopLevel = 0;
    
    
    float2 startCellCount = GetCellCount(textureSize, startLevel);
    
    float2 rayCell = GetCell(ray.xy, startCellCount);
    ray = IntersectCellBoundary(o, d, rayCell, startCellCount, crossStep, crossOffset);
    
    int level = startLevel;
    uint iter = 0;
    bool isBackwardRay = reflectDirTextureSpace.z < 0;
    float rayDir = isBackwardRay ? -1 : 1;
    bool isIntersecting = false;
    
    [loop]
    while (level >= stopLevel && ray.z * rayDir <= maxZ * rayDir && iter < 16)
    {
        
        float2 cellCount = GetCellCount(1.0 / (PixelSize.xy), level);
        float2 oldCellIdx = GetCell(ray.xy, cellCount);
        
        float cell_minZ = GetMinimumDepthPlane((oldCellIdx + 0.5f) / cellCount, level);
        
        float3 tmpRay = ((cell_minZ > ray.z) && !isBackwardRay) ? IntersectDepthPlane(o, d, (cell_minZ - minZ) / deltaZ) : ray;
        
        float2 newCellIdx = GetCell(tmpRay.xy, cellCount);
        
        float thickness = 0;
        float rayZLinear = ProjectionDepthToLinearDepth(ray.z, 0.1f, 1000.0f);
        float cellMinZLinear = ProjectionDepthToLinearDepth(cell_minZ, 0.1f, 1000.0f);
        if (level == 0)
        {
            thickness = abs(rayZLinear
             - cellMinZLinear);

        }
        else
        {
            thickness = 0;
         
        }
        
        bool crossed = false; //(isBackwardRay && (cell_minZ > ray.z)) || thickness>0.2|| CrossedCellBoundary(oldCellIdx, newCellIdx);
        bool crossedBehind = false;
        
        if (isBackwardRay)
        {
            if ((cellMinZLinear > rayZLinear))
            {
                crossed = true;
            }
          
        }
        else if ((cellMinZLinear - 0.02 < rayZLinear && thickness >= 0.3))
        {
            crossedBehind = true; //tracing ray behind downgrades into linear search
      
        }
        else if (CrossedCellBoundary(oldCellIdx, newCellIdx))
        {
            crossed = true;
        }
        else
        {
            crossed = false;
        }
        
        
        if (crossed == true)
        {
            ray = IntersectCellBoundary(o, d, oldCellIdx, cellCount, crossStep, crossOffset);
            level = min((float) maxLevel, level + 1.0f);
         

        }
        else if (crossedBehind == true)
        {
            ray = IntersectCellBoundary(o, d, oldCellIdx, cellCount, crossStep, crossOffset);
            level = min((float) maxLevel, level + 1.0f);
          
           
        }
        else
        {
            ray = tmpRay;
            level = level - 1;
          

        }
      [branch]
        if (ray.x < 0 || ray.y < 0 || ray.x > 1 || ray.y > 1)
        {
            isIntersecting = false;
            break;
        }
         
        
        if (level <= 0)
        {
             rayZLinear = ProjectionDepthToLinearDepth(ray.z, 0.1f, 1000.0f);
             cellMinZLinear = ProjectionDepthToLinearDepth(cell_minZ, 0.1f, 1000.0f);
            thickness = abs(rayZLinear
             - cellMinZLinear);
            if (thickness < 0.1 && rayZLinear > cellMinZLinear - 0.02 && rayZLinear < 900.0f && cellMinZLinear < 900.0f)
            {
                isIntersecting = true;
                break;
            }
            
          
        }
        ++iter;
    }
    
    float2 uv = ray.xy;
    if (isIntersecting == true)
    {
        //    float3 lum = tex2D(gLum, uv).xyz;
          
        float3 lum1 = tex2D(gLum, uv).xyz;
      
        float3 Lo = lum1;
        finalColor += Lo;
        finalMixVal += 1;

    }
    else
    {
        float3 irradiance = lerp(texCUBE(irradianceSampler, normal).rgb, texCUBE(irradianceSamplerNight, normal).rgb, mixValue);
           
        finalColor += 0;
        finalMixVal += 0;
    }
  //  }      
    finalColor /= clamp(finalMixVal, 1, 1);
    finalMixVal /= 1;
   // finalColor = finalColor*0.01+prevColor;
           
  //      finalColor = finalColor * 0.01 + prevColor;
    float3 irradiance1 = finalColor;
    float3 diffuse = irradiance1 * albedo;
    return lerp(float4(diffuse * kD, finalMixVal), prevColor, 0.9);
}
technique SSID
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPSHiZ();
	}
};