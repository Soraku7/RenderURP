Shader "Unlit/OldSchool1"
{
    Properties
    {
        _SpecularPow("高光次幂" , Range(1 , 90)) = 30
        _MainCol("环境颜色" , color) = (1.0 , 1.0 , 1.0 , 1.0)
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

            uniform float3 _MainCol;
            uniform float _SpecularPow;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float4 posWS : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = i.nDirWS;
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);

                float3 reflectDir = reflect(-lDir , nDir);
                float3 refdotv = dot(reflectDir , vDir);
                
                float phong = pow(max(refdotv , 0.0) , _SpecularPow);
                float lambort = max(dot(nDir , lDir) , 0.0);

                float3 final = _MainCol * lambort + phong;
                
                return float4(final.x , final.y , final.z , 1.0);
            }
            ENDCG
        }
    }
}
