Shader "Effect/GhostFlow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 0.5
        _NoiseTex ("噪声贴图", 2D) = "white" {}
        _NoiseInt ("噪声强度", Range(0,2)) = 0.5
        _FlowSpeed ("流动速度", Range(-1,1)) = 0.5   
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
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform half _Opacity;
            uniform sampler2D _NoiseTex;
            uniform float4 _NoiseTex_ST;
            uniform half _NoiseInt;
            uniform half _FlowSpeed;
            
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
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv;
                //UV1支持偏移
                o.uv1 = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.uv1.y = o.uv1.y + frac(-_Time.y * _FlowSpeed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv0);
                half var_Noise = tex2D(_NoiseTex, i.uv1).r;

                half3 finalRGB = var_MainTex.rgb;
                //Remap Noise
                half noise = lerp(1.0, var_Noise * 2.0, _NoiseInt);
                noise = max(0.0 , noise);
                half opacity = var_MainTex.a * _Opacity * noise;
                
                return half4(finalRGB, opacity);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
