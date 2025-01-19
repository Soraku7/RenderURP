Shader "Unlit/CubeMap"
{
    Properties
    {
        _NormalMap ("NormalMap" , 2D) = "bump" {}
        _CubeMap ("_CubeMap" , Cube) = "_Skybox" {}
        _CubeMapMip ("环境球mip" , Range(0 , 7)) = 0
        _FresnelPow ("FresnelPow" , Range(0 , 10)) = 1
        _EnvSpecInt ("环境镜面反射强度" , Range(0 , 5)) = 1
        _Occlusion ("Occlusion" , 2D) = "white" {}
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
            uniform samplerCUBE _CubeMap;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;
            uniform float _CubeMapMip;
            uniform sampler2D _Occlusion;


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
                float3 vDirWS = normalize(_WorldSpaceCameraPos - i.posWS.xyz);
                float3 vrDirWS = reflect(-vDirWS , nDirWS);

                float vdotn = dot(vDirWS , nDirWS);

                float occlusion = tex2D(_Occlusion , i.uv0).r;
                float3 CubeMap = texCUBElod(_CubeMap , float4(vrDirWS , _CubeMapMip));
                float fressnal = pow(1 - vdotn , _FresnelPow);
                
                float3 final = CubeMap * fressnal * _EnvSpecInt * occlusion;
             
                return float4(final , 1.0);
            }
            ENDCG
        }
    }
}
