Shader "Effect/Water"
{
    Properties
    {
        _MainTex ("R 外焰 G 內焰 B 底部暗压 A 火焰轮廓", 2D) = "white" {}
        _WarpTex ("R 噪声1 G噪声2", 2D) = "white" {}
        _Warp1Params ("X 大小 Y 流速X Z流速Y W强度", Vector) = (1.0  , 0.2 , 0.2 , 0.0)
        _Warp2Params ("X 大小 Y 流速X Z流速Y W强度", Vector) = (1.0  , 0.2 , 0.2 , 0.0)
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
                "LightMode" = "UniversalForward"
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
            uniform sampler2D _WarpTex;
            uniform half4 _Warp1Params;
            uniform half4 _Warp2Params;
            
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
                o.uv0 = v.uv - frac(_Time.x);
                o.uv1 = v.uv * _Warp1Params.x - frac(_Time.x * _Warp1Params.yz);
                o.uv2 = v.uv * _Warp2Params.x - frac(_Time.x * _Warp1Params.yz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                half3 var_Warp1 = tex2D(_WarpTex, i.uv1).rgb;
                half3 var_Warp2 = tex2D(_WarpTex, i.uv2).rgb;
                
                half2 warp = (var_Warp1 - 0.5) * _Warp1Params.w + (var_Warp2 - 0.5) * _Warp2Params.w;
                //扰动UV
                float2 warpUV = i.uv0 + warp;
                
                half3 var_Mask = tex2D(_MainTex, warpUV);
                
                return half4(var_Mask , 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
