// 溶解效果(带泛光)
// 实现思路：采样无序图，然后通过其中的某个通道(此处为r)的值，与当前的溶解系数对比，
// 如果主纹理当前的通道值小于溶解系数，则说明当前片元需要被剔除。
// 如果不被剔除，则判断当前值距离消融的比例来设置消融的边缘颜色混合
Shader "Custom/DissolveOneColor"
{
    Properties
    {
        _MainTexture ("Main Texture(RGB)", 2D) = "white" { }
        _DissolveTexture ("Dissolve Texture(R)", 2D) = "white" { }// 噪声图
        _EdgeColor ("EdgeColor", Color) = (1, 1, 1, 1) // 边缘颜色
        _DissolveAmount ("DissolveAmount", Range(0, 1)) = 1 // 溶解系数
        _EdgeWidth ("EdgeWidth", Range(0, 0.3)) = 0.05 // 边缘宽度
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull off

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert // 声明顶点着色程序函数名
            #pragma fragment frag // 声明片元着色程序函数

            #include "UnityCG.cginc"

            sampler2D _MainTexture;
            sampler2D _DissolveTexture;
            float _DissolveAmount;
            float _ExtrudeAmount;
            float _EdgeWidth;
            fixed4 _EdgeColor;

            // 应用传给顶点着色程序的数据
            struct appdata
            {
                float4 vertex: POSITION; // 模型的顶点坐标
                float2 uv: TEXCOORD; // 模型的纹理坐标
            };

            // 顶点着色程序传递给片元程序的数据
            struct v2f
            {
                float4 pos: SV_POSITION; // 裁剪空间中的顶点坐标
                float2 uv: TEXCOORD; // 模型的纹理坐标
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 模型空间顶点坐标转换为裁剪空间下坐标
                o.uv = v.uv; // 纹理uv坐标
                return o;
            }
            
            fixed4 frag(v2f i): SV_TARGET
            {
                //对噪声贴图进行采样
                fixed4 dissolveColor = tex2D(_DissolveTexture, i.uv);
                // 溶解贴图上的R通道值和目前的溶解基准值相差多少
                float offsetValue = dissolveColor.r - _DissolveAmount;
                // offsetValue < 0 则放弃此片元不绘制
                clip(offsetValue);

                //主贴图进行采样
                fixed4 textureColor = tex2D(_MainTexture, i.uv);
                offsetValue += (1 - sign(_DissolveAmount)) * _EdgeWidth;
                float edgeFactor = 1 - saturate(offsetValue / _EdgeWidth);
                return lerp(textureColor, _EdgeColor, edgeFactor);
            }
            ENDCG
            
        }
    }
}