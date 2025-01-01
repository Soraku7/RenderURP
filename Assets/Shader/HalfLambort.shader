Shader "Unlit/HalfLambort"
{
    Properties
    {
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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 nDirWS : TEXCOORD0;
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.nDirWS = UnityObjectToWorldDir(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = i.nDirWS;
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float nDotl = dot(nDir , lDir);
                float halfLambort = nDotl * 0.5 + 0.5;
                return float4(halfLambort , halfLambort , halfLambort , 1.0);
            }
            ENDCG
        }
    }
}
