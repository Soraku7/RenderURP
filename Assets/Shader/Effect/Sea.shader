Shader "URP/Sea"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal", 2D) = "white" {}
        _FlowMap ("FlowMap", 2D) = "white" {}

        [HDR]_BaseColor ("BaseColor", Color) = (1,0,0,1)

        _SpecularPow ("Specular", Range(1, 100)) = 30
        _NormalStrength ("NormalStrength" , Range(0.1 , 2)) = 1
        
        _FlowMapSpeed ("FlowMapSpeed" , Float) = 2
        _UJump("UJump" , Range(-0.25 , 0.25)) = 0
        _VJump ("VJump" , Range(-0.25 , 0.25)) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"

        }
        Pass
        {
            Name "URPUnlit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusDstAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float3 tDirWS : TEXCOORD2;
                float3 bDirWS : TEXCOORD3;
                float3 posWS : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            sampler2D _FlowMap;
            float4 _FlowMap_ST;
            sampler2D _ReflectTex;

            half4 _BaseColor;

            float _SpecularPow;
            float _NormalStrength;
            
            float _FlowMapSpeed;
            float _UJump;
            float _VJump;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS, o.tDirWS) * v.tangent.w;
                o.posWS = vertexInput.positionWS;
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();

                //将flowmap映射到(0 , 1)
                float2 FlowMapUV = i.uv*_FlowMap_ST.xy+_FlowMap_ST.zw;
                half4 flowMap = tex2D(_FlowMap, FlowMapUV) * 2.0 - 1.0;
                
                float noise = flowMap.a * 3;
                float phase0 = frac(_Time.y * 0.1 * _FlowMapSpeed + noise);
                float phase1 = frac(_Time.y * 0.1 * _FlowMapSpeed + 0.5 + noise);

                float2 tiling_uv = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 flowUV = tiling_uv - flowMap.xy * phase0 + _UJump + _VJump;
                float2 flowUV1 = tiling_uv - flowMap.xy * phase1;
                half3 tex0 = tex2D(_MainTex, flowUV);
                half3 tex1 = tex2D(_MainTex, flowUV1);

                float flowLerp = abs((0.5 - phase0) / 0.5);
                half3 flowColor = lerp(tex0, tex1, flowLerp);

                half3x3 TBN = half3x3(i.tDirWS, i.bDirWS, i.nDirWS);

                half3 normalA =  UnpackNormal(tex2D(_NormalMap,flowUV));
                half3 normalB =  UnpackNormal(tex2D(_NormalMap,flowUV1));
                normalA.z = pow(saturate(1 - pow(normalA.x , 2) - pow(normalA.y , 2)) , 0.5);
                normalB.z = pow(saturate(1 - pow(normalB.x , 2) - pow(normalB.y , 2)) , 0.5);
                float3 normal = BlendNormal(normalA, normalB);
                normal = lerp(i.nDirWS , normalize(mul(TBN , normal)) , _NormalStrength);
                normal = normalize(normal);

                half3 nDirWS = normalize(mul(normal, TBN));
                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS);
                half3 lDirWS = normalize(mainLight.direction);
                half3 hDirWS = normalize(vDirWS + lDirWS);


                half ndoth = dot(nDirWS, hDirWS);
                half ndotl = dot(nDirWS, lDirWS);

                half lambort = max(0, ndotl);
                half blinnPhong = mainLight.color * pow(max(ndoth, 0), _SpecularPow);

                half3 reflect = tex2D(_ReflectTex, i.screenPos.xy / i.screenPos.w).rgb;
                half3 diffuse = flowColor * lambort * _BaseColor;
                half3 specular = blinnPhong;
                
                half3 finalColor = diffuse + specular + reflect;
                
                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }


    }
}