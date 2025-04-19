Shader "NRP/Nahida_Face"
{
    Properties
    {
        [Header(Texture)]
        _BaseTex ("Texture", 2D) = "white" {}
        _BaseTexFra ("BaseTexFra" , Range(0 , 1)) = 1
        _ToonTex("ToonTex", 2D) = "white" {}
        _ToonTexFra("ToonTexFra", Range(0, 1)) = 1
        
        [Header(Diffuse)]
        _AmbientCol("AmbientColor", Color) = (1,1,1,1)
        _DiffuseCol("DiffuseColor", Color) = (1,1,1,1)
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
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float3 posWS : TEXCOORD2;
            };

            sampler2D _BaseTex;
            float4 _BaseTex_ST;
            float _BaseTexFra;
            sampler2D _NormalMap;
            sampler2D _ToonTex;
            float _ToonTexFra;

            half4 _AmbientCol;
            half4 _DiffuseCol;

            v2f vert(appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                o.posWS = vertexInput.positionWS;
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half3 nDirWS = normalize(i.nDirWS);
                half3 nDirVS = normalize(mul(UNITY_MATRIX_V , nDirWS));
                half3 lDirWS = normalize(mainLight.direction);
                half3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS.xyz);

                half ndotv = dot(nDirWS, vDirWS);

                half2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                
                float4 baseTex = tex2D(_BaseTex, i.uv);
                float4 toonTex = tex2D(_ToonTex, matcapUV);
                
                half3 baseCol = _AmbientCol.rgb;
                baseCol = saturate(lerp(baseCol , baseCol + _DiffuseCol , 0.6));
                baseCol = lerp(baseCol , baseCol * baseTex.rgb , _BaseTexFra);
                baseCol = lerp(baseCol , baseCol * toonTex.rgb , _ToonTexFra);
                
                return half4(baseCol , 1.0);
            }
            ENDHLSL
        }

    }
}