Shader "NRP/CelRender"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _ShadowColor("ShadowColor", Color) = (1,1,1,1)
        _ShadowRange("ShadowRange", Range(0.5,1)) = 0.5
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
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float3 posWS : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _BaseColor;
            half3 _ShadowColor;
            float _ShadowRange;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.posWS = vertexInput.positionWS;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half4 mainTex = tex2D(_MainTex, i.uv);
                
                half3 nDirWS = normalize(i.nDirWS);
                half3 lDirWS = normalize(mainLight.direction);

                half ndotl = max(0, dot(nDirWS, lDirWS));

                half halfLambort = ndotl * 0.5 + 0.5;
                //使用smoothstep来平滑过渡
                // half ramp = smoothstep(0, _ShadowSmooth, halfLambort - _ShadowRange);
                // half3 diffuse = lerp(_ShadowColor, _BaseColor, ramp);

                half3 diffuse = halfLambort > _ShadowRange ? _BaseColor : _ShadowColor;
                diffuse *= mainTex;
                half3 col = diffuse * mainLight.color;
                return half4(col, mainTex.a);
            }
            ENDHLSL
        }

    }
}