Shader "Effect/AB"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("不透明度", Range(0,1)) = 1
        _WarpMidValue ("扰动中间值", Range(0,1)) = 1
        _WarpInt ("扰动强度", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType"="TransparentCutout"
            "ForceNoShadowCasting"="True"  // 不产生阴影
            "IgnoreProject"="True"  // 忽略投影
        }
        
        //获取背景纹理
        GrabPass
        {
            "_BackgroundTexture"
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
            uniform half _WarpMidVal;
            uniform half _WarpInt;
            uniform sampler2D _BackgroundTexture;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);

                //扰动背景UV
                i.grabPos.xy += (var_MainTex.b - _WarpMidVal) * _WarpInt * _Opacity;

                half3 var_BGTex = tex2Dproj(_BackgroundTexture , i.grabPos).rgb;

                half3 finalRGB = lerp(1.0, var_MainTex.rgb, _Opacity) * var_BGTex;
                return half4(finalRGB * var_MainTex.a, var_MainTex.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"	
}
