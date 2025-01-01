Shader "Unlit/3ColAmbient"
{
    Properties
    {
        _Occlusion ("Occlusion", 2D) = "white" {}
        _EnvUpCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvSideCol ("EnvUpCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _EnvDownCol ("EnvDownCol" , color) = (1.0 , 1.0 , 1.0 , 1.0) 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv0 : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
            };

            uniform sampler2D _Occlusion;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv0;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = i.nDirWS;
                float upMask = max(0.0 , nDir.g);
                float downMask = max(0.0 , -nDir.g);
                float sideMask = 1 - upMask - downMask;

                float3 envCol= _EnvUpCol * upMask + _EnvSideCol * sideMask + _EnvDownCol * downMask;

                return float4(envCol , 1.0);
                
            }
            ENDCG
        }
    }
}
