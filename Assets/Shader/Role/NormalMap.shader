Shader "Unlit/NormalMap"
{
    Properties
    {
        _NormalMap ("NormalMap" , 2D) = "white" {}
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

            uniform sampler2D _NormalMap;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float3 tDirWS : TEXCOORD2;
                float3 bDirWS : TEXCOORD3;
                
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld , float4(v.tangent.xyz , 0.0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS , o.tDirWS) * v.tangent.w);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDirTS = UnpackNormal(tex2D(_NormalMap , i.uv0));

                float3x3 TBN = float3x3(i.tDirWS , i.bDirWS , i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS , TBN));

                float3 lDir = _WorldSpaceLightPos0.xyz;

                float ndotl = dot(nDirWS , lDir);
                float lambort = max(0.0 , ndotl);

                return float4(lambort , lambort , lambort , 1.0);
            }
            ENDCG
        }
    }
}
