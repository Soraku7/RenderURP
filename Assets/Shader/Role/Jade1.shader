Shader "URP/Jade1"
{
    Properties
    {
        _BackLightCol("BackLightCol" , Color) = (1 , 1 , 1, 1) 
        _Disort ("BackLight Disort", Range(0 , 1)) = 0.1
        _Power ("BackLight Power", Range(0 , 5)) = 1
        _Scale ("BackLight Scale", Range(0 , 5)) = 1
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
            };
            
            struct v2f
            {
                float4 pos: SV_POSITION;
                float3 posWS: TEXCOORD0;
                float3 normal: TEXCOORD1;
            };
            
            
            v2f vert(appdata v)
            {
                v2f o;
                // 获取不同空间下坐标信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.pos.xyz);
                o.pos = positionInputs.positionCS;
                o.posWS = positionInputs.positionWS;
                
                o.normal = TransformObjectToWorldNormal(v.normal);
                
                
                return o;
            }

            uniform float4 _BackLightCol;
            uniform float _Disort;
            uniform float _Power;
            uniform float _Scale;

            half SSS(half3 lDirWS , half3 nDirWS , half3 vDirWS)
            {
                half3 bDirWS = -normalize(lDirWS + nDirWS * _Disort);
                
                half vdotb = max(0 , dot(vDirWS, bDirWS));

                half sss = max(0 , pow(vdotb , _Power)) * _Scale;

                return sss;
            }
            
            half4 frag(v2f i): SV_Target
            {
                
                // 使用HLSL的函数获取主光源数据
                Light mainLight = GetMainLight();
                
                //向量准备
                half3 nDirWS = i.normal;
                half3 vDirWS = _WorldSpaceCameraPos - i.posWS;
                half3 lDirWS = mainLight.direction;

                // half vdotb = max(0 , dot(vDirWS, bDirWS));

                half sss = SSS(lDirWS , nDirWS , vDirWS);

                half3 col = _BackLightCol.rgb * sss;
                
                // 计算其他光源
                #ifdef _AdditionalLights
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++ lightIndex)
                    {
                        // 获取其他光源
                        Light light = GetAdditionalLight(lightIndex, i.posWS);

                        half3 lDirWS = light.direction;
                        col += SSS(lDirWS , nDirWS , vDirWS);
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
