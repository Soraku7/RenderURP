Shader "Unlit/BrokenGlass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlassMask ("GlassMask" , 2D) = "black" {}
        _GlassCrack ("GlassCrack" , Float) = 1
        _GlassNormal ("GlassNormal" , 2D) = "bump" {}
        _Distort ("Distort" , Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {   
            Cull off
            ZWrite off
            ZTest Always
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog workAA
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _GlassMask;
            sampler2D _GlassNormal;
            float4 _GlassMask_ST;

            float _GlassCrack;
            float _Distort;
            half4 frag (v2f_img i) : SV_Target
            {
                //计算宽高比 _ScreenParams为当前屏幕参数
                float aspect = _ScreenParams.x / _ScreenParams.y; // x = width y = height z = 1 + 1.0/width w = 1 + 1.0/height
                float2 glass_uv = float2(i.uv.x * aspect, i.uv.y) * _GlassMask_ST.xy + _GlassMask_ST.zw;

                //采样法线和玻璃贴图
                half glass_opacity = tex2D(_GlassMask, glass_uv).r;
                half3 glass_normal = UnpackNormal(tex2D(_GlassNormal, glass_uv));

                //获取屏幕上下左右两边  防止扭曲
                half2 d = 1.0 - smoothstep(0.95,1,abs(i.uv * 2.0 - 1.0));
                half vfactor = d.x * d.y;

                float2 d_mask = step(0.005, abs(glass_normal.xy));
                float mask = d_mask.x * d_mask.y;

                half2 uv_distort = i.uv + glass_normal.xy * _Distort * vfactor * mask;
                half4 col = tex2D(_MainTex, uv_distort);
                half3 finalcolor = col.rgb;
                finalcolor = lerp(finalcolor, _GlassCrack.xxx, glass_opacity);
                return float4(finalcolor,col.a);
            }
            ENDCG
        }
    }
}
