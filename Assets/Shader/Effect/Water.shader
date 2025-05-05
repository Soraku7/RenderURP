Shader "URP/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FlowMap ("Flor(RG) , Noise(A)", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,0,0,1)
        
        _Ujempt ("Ujemp", Range(-0.25 , 0.25)) = 0.5
        _Vjempt ("Vjemp", Range(-0.25 , 0.25)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Name "URPUnlit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _FlowMap;
            float4 _MainTex_ST;
            half4 _BaseColor;

            float _Ujempt;
            float _Vjempt;

            float3 FlowUV(float2 uv , float2 flowVec , float time , bool flowB)
            {
                float3 uvw;
                float phaseOffset = flowB ? 0.5 : 0;
                float progress = frac(time + phaseOffset);
                uvw.xy = uv - flowVec * progress + phaseOffset;
                uvw.z = 1 - abs(1 - 2 * progress);
                
                return uvw;
            }

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {

                float2 flowVector = tex2D(_FlowMap, i.uv).rg;
                float noise = tex2D(_FlowMap , i.uv).a;

                float jump = float2(_)
                
                float3 uvwA = FlowUV(i.uv , flowVector , _Time.y + noise , true);
                float3 uvwB = FlowUV(i.uv , flowVector , _Time.y + noise , false);
                
                half4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
                half4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;
                
                half3 color = (texA.rgb + texB.rgb) * _BaseColor.rgb;
                return half4(color, texA.a);
            }
            ENDHLSL
        }

    }
}