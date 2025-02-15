Shader "Effect/Fire"
{
    Properties
    {
        _MainTex ("R 外焰 G 內焰 B 底部暗压 A 火焰轮廓", 2D) = "white" {}
        _NoiseTex ("R 噪声1 G噪声2", 2D) = "white" {}
        _Noise1Params ("X 大小 Y 流速 Z强度", Vector) = (1.0  , 0.2 , 0.2 , 0.0)
        _Noise2Params ("X 大小 Y 流速 Z强度", Vector) = (1.0  , 0.2 , 0.2 , 0.0)
        [HDR]_InColor ("内焰颜色", Color) = (1.0 , 1.0 , 1.0 , 1.0)
        [HDR]_OutColor ("外焰颜色", Color) = (1.0 , 1.0 , 1.0 , 1.0)
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType"="TransparentCutout"
            "ForceNoShadowCasting"="True"  // 不产生阴影
            "IgnoreProject"="True"  // 忽略投影
        }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags {
                "LightMode" = "ForwardBase"
            }
            Blend One OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform sampler2D _NoiseTex;
            uniform half3 _Noise1Params;
            uniform half3 _Noise2Params;

            uniform half4 _InColor;
            uniform half4 _OutColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv;
                o.uv1 = v.uv * _Noise1Params.x - float2(0.0 , frac(_Time.x * _Noise1Params.y));
                o.uv2 = v.uv * _Noise2Params.x - float2(0.0 , frac(_Time.x * _Noise1Params.y));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                half var_Noise1 = tex2D(_NoiseTex, i.uv1).r;
                half var_Noise2 = tex2D(_NoiseTex, i.uv2).g;
                half warpMask = tex2D(_MainTex, i.uv0).b;
                
                half noise = var_Noise1 * _Noise1Params.z + var_Noise2 * _Noise2Params.z;
                //扰动UV
                float2 warpUV = i.uv0 - float2(0.0 , noise) * warpMask;

                half3 var_Mask = tex2D(_MainTex, warpUV);

                half3 finalCol = var_Mask.r * _InColor + var_Mask.g * _OutColor;
                half opacity = var_Mask.r + var_Mask.g;
                return half4(finalCol , opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
