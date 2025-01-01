Shader "Unlit/BlinnPhong"
{
    Properties
    {
        _MainCol("MainCol" , color) = (1.0 , 1.0 , 1.0 , 1.0)
        _SpecularPos("SpecularPos" , range(1 , 99)) = 30
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
                float4 posCS : SV_POSITION;
                float4 posWS : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
            };

            uniform float3 _MainCol;
            uniform float _SpecularPos;

            v2f vert (appdata v)
            {
                v2f o;
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = i.nDirWS;
                float3 lDir = _WorldSpaceLightPos0.xyz;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                float3 hDir = normalize(lDir + vDir);

                float ndotl = dot(nDir , lDir);
                float ndoth = dot(nDir , hDir);

                float lambort = max(0.0 , ndotl);
                float blinnPhong = pow(max(0.0 , ndoth) , _SpecularPos);

                float3 finalRGB = _MainCol * lambort + blinnPhong;

                return float4(finalRGB , 1.0);
            }
            ENDCG
        }
    }
}
