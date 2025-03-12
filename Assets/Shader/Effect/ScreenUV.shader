Shader "Effect/ScreenUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 1.0
        _ScreenTex ("屏幕纹理", 2D) = "white" {}
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
            uniform half _Opacity;
            uniform sampler2D _ScreenTex;
            uniform float4 _ScreenTex_ST;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 ScreenUV : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                //原点位置转到观察空间
                float originDist = UnityObjectToViewPos(float3(0.0 , 0.0 , 0.0)).z;
                //观察空间畸变转化
                o.ScreenUV = posVS.xy / posVS.z * originDist;
                o.ScreenUV = o.ScreenUV * _ScreenTex_ST.xy - frac(_ScreenTex_ST.zw * _Time.x);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);
                half var_ScreenTex = tex2D(_ScreenTex, i.ScreenUV).r;

                half3 finalRGB = var_MainTex.rgb;
                half opacity = var_MainTex.a * _Opacity * var_ScreenTex;
                
                return half4(finalRGB * opacity, opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
