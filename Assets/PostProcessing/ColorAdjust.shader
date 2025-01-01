Shader "PostProcessing/ColorAdjust"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness ("Brightness" , float) = 1
        _Saturation ("Saturation" , float) = 1
        _Conturast ("Conturast" , float) = 1
        _VignetteIntensity ("VignetteIntensity" , Range(0.05 , 3)) = 1.5
        _VignetteRoundness ("VignetteRoundness" , Range(1.0 , 5.0)) = 5.0
        _VignetteSmothness ("VignetteSmothness" , Range(0.05 , 5)) = 5.0
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
            //Unity内置vert_img
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float _Brightness;
            float _Saturation;
            float _Conturast;
            float _VignetteIntensity;
            float _VignetteRoundness;
            float _VignetteSmothness;

            half4 frag (v2f_img i) : SV_Target
            {
                half4 col = tex2D(_MainTex , i.uv);
                //亮度
                half3 finalCol = col.rgb * _Brightness;
                //饱和度
                half lumin = dot(finalCol , float3(0.22 , 0.707 , 0.701));
                finalCol = lerp(lumin , finalCol , _Saturation);
                //对比度
                float3 midpoint = float3(0.5 , 0.5 , 0.5);
                finalCol = lerp(midpoint , finalCol , _Conturast);
                //暗角 晕影
                float2 d = abs(i.uv.xy - half2(0.5 , 0.5)) * _VignetteIntensity;
                d = pow(saturate(d) , _VignetteRoundness);
                float dist = length(d);
                float vfactor = pow(saturate(1.0 - dist - dist) , +_VignetteSmothness);

                finalCol = finalCol * vfactor;
                return half4(finalCol , col.a);
            }
            ENDCG
        }
    }
}
