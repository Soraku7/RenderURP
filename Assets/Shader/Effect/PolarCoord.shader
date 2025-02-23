Shader "Effect/PolarCoord"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 1
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _Speed ("速度", Range(1 , 10)) = 1
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
            uniform half _Opacity;
            uniform half3 _Color;
            uniform half _Speed;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv = i.uv - float2(0.5 , 0.5);
                float theta = atan2(i.uv.y, i.uv.x);
                theta = theta / 3.1415926 * 0.5 + 0.5;
                float r = length(i.uv) + frac(_Time.x * _Speed);
                i.uv = float2(theta, r);    
                
                half4 var_MainTex = tex2D(_MainTex, i.uv);
                half3 finalRGB = (1 - var_MainTex.rgb) * _Color;
                half opacity = (1 - var_MainTex.a) * _Opacity * i.color.a;
                
                return half4(finalRGB * _Opacity, opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
