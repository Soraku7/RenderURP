Shader "Unlit/BoxBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurOffset ("BlurOffset" , Float) = 1
        //_BlurRadius ("BlurRadius" , Range(0 , 15)) = 5.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            //x = 1 / width y = 1 / height z = width w = height

            float4 _BlurOffset;
            //float _BlurRadius;
            half4 frag (v2f_img i) : SV_Target
            {
                half4 d = _MainTex_TexelSize.xyxy  * half4(-1 , -1 , 1 , 1);
                half4 s = 0;

                s = tex2D(_MainTex , i.uv);
                //获取卷积上下左右四角
                s += tex2D(_MainTex , i.uv + d.xy);
                s += tex2D(_MainTex , i.uv + d.zw);
                s += tex2D(_MainTex , i.uv + d.xw);
                s += tex2D(_MainTex , i.uv + d.zw);

                //获取卷积上下左右
                s += tex2D(_MainTex , i.uv + half2(0.0 , d.w));
                s += tex2D(_MainTex , i.uv + half2(0.0 , d.y));
                s += tex2D(_MainTex , i.uv + half2(d.w , 0.0));
                s += tex2D(_MainTex , i.uv + half2(d.y , 0.0));
                s /= 9.0;
                return s;
            }
            ENDCG
        }
    }
}
