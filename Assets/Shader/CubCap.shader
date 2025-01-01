Shader "Unlit/CubCap"
{
    Properties
    {
        _NormalMap ("NormalMap" , 2D) = "bump" {}
        _Matcap ("MatCap" , 2D) = "gray" {}
        _FresnelPow ("FresnelPow" , Range(0 , 10)) = 1
        _EnvSpecInt ("EnvSpecInt" , Range(0 , 5)) = 1
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags{
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normal :NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;
            };

            uniform sampler2D _NormalMap;
            uniform sampler2D _Matcap;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld , float4(v.tangent.xyz , 0.0)).xyz);
                o.bDirWS = normalize(mul(o.nDirWS , o.tDirWS));
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float3 nDirTS = UnpackNormal(tex2D(_NormalMap , i.uv0)).rgb;
                float3x3 TBN = float3x3(i.tDirWS , i.nDirWS , i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS , TBN));
                float3 vDirWS = mul(UNITY_MATRIX_V , nDirWS);
                
                float vdotn = dot(vDirWS , nDirWS);
                float2 matcapUV = nDirWS.rg * 0.5 + 0.5;

                float3 matcap = tex2D(_Matcap , matcapUV);
                float fresnel = pow(max( 0.0 , 1.0 - vdotn) , _FresnelPow);
                float3 envSpecLighting = matcap * fresnel * _EnvSpecInt;

                return float4(envSpecLighting , 1.0);
            }
            ENDCG
        }
    }
}
