Shader "URP/Jade1"
{
    Properties
    {
        _RampTex ("RampTex" , 2D) = "white" {}
        _ThicknessTex ("ThicknessTex" , 2D) = "white"{}
        _CubeMap ("CubeMap" , CUBE) = "white" {}
        
        _BackLightCol("BackLightCol" , Color) = (1 , 1 , 1, 1) 
        _Disort ("BackLight Disort", Range(0 , 1)) = 0.1
        _Power ("BackLight Power", Range(0 , 5)) = 1
        _Scale ("BackLight Scale", Range(0 , 5)) = 1
        _FresnelPow ("FresnelPow",float) = 1
        
        _EnvRotate ("CubeMap Rotate", Range(0 , 360)) = 0
        
        [Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _Diffuse;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma shader_feature _AdditionalLights
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct appdata
            {
                float4 pos: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos: SV_POSITION;
                float3 posWS: TEXCOORD0;
                float3 normal: TEXCOORD1;
                float2 uv: TEXCOORD2;
            };
            
            
            v2f vert(appdata v)
            {
                v2f o;
                // 获取不同空间下坐标信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.pos.xyz);
                o.pos = positionInputs.positionCS;
                o.posWS = positionInputs.positionWS;
                
                o.normal = TransformObjectToWorldNormal(v.normal);
                
                o.uv = v.uv;
                
                return o;
            }

            uniform sampler2D _RampTex;
            uniform float4 _RampTex_ST;
            uniform sampler2D _ThicknessTex;
            uniform samplerCUBE _CubeMap;
            
            uniform float4 _BackLightCol;
            uniform float _Disort;
            uniform float _Power;
            uniform float _Scale;
            uniform float _FresnelPow;

            uniform float _EnvRotate;

            half SSS(half3 lDirWS , half3 nDirWS , half3 vDirWS)
            {
                half3 bDirWS = -normalize(lDirWS + nDirWS * _Disort);
                
                half vdotb = max(0 , dot(vDirWS, bDirWS));

                half sss = max(0 , pow(vdotb , _Power)) * _Scale;

                return sss;
            }

            half Lambort(half3 nDirWS , half3 lDirWS , Light light)
            {
                return max(0 , dot(nDirWS , lDirWS)) * light.distanceAttenuation * light.shadowAttenuation;
            }
            
            half4 frag(v2f i): SV_Target
            {
                
                // 使用HLSL的函数获取主光源数据
                Light mainLight = GetMainLight();
                
                //向量准备
                half3 nDirWS = i.normal;
                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS);
                half3 lDirWS = normalize(mainLight.direction);
                half3 vrDirWS = reflect(-vDirWS , nDirWS);

                float4 var_ThickNessTex = tex2D(_ThicknessTex , i.uv);
                
                half sss = SSS(lDirWS , nDirWS , vDirWS);
                half thickness = 1.0 - var_ThickNessTex.r;
                half fressnel = pow(1.0 - saturate(dot(vDirWS , nDirWS)) , _FresnelPow);
                half lambort = Lambort(nDirWS , lDirWS , mainLight);

                float4 var_RampTex = tex2D(_RampTex , TRANSFORM_TEX(float2(lambort, 0.5) , _RampTex));
                
                float theta = _EnvRotate * PI / 180.0;
                float2x2 rot = float2x2(cos(theta) , -sin(theta) , sin(theta) , cos(theta));

                //环境球旋转
                float2 rDirRotate = mul(rot , float2(vrDirWS.x , vrDirWS.z));
                vrDirWS = float3(rDirRotate.x , vrDirWS.y , rDirRotate.y);
                float3 var_CubeMap = texCUBE(_CubeMap , float4(vrDirWS , 1.0));

                float3 diffuseCol = lambort * var_RampTex.rgb + _BackLightCol.rgb * sss * thickness;
                //lambort + 背光 + 环境球 * fressnel
                half3 col = diffuseCol+ var_CubeMap * fressnel;
                
                // 计算其他光源
                #ifdef _AdditionalLights
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++ lightIndex)
                    {
                        // 获取其他光源
                        Light light = GetAdditionalLight(lightIndex, i.posWS);

                        half3 lDirWS = light.direction;
                        col += (SSS(lDirWS , nDirWS , vDirWS) + Lambort(nDirWS , lDirWS , light)) * light.color;
                    }
                #endif
                
                // 采用球谐光照计算环境光
                half3 ambient = SampleSH(nDirWS);
                return half4(col, 1.0);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
