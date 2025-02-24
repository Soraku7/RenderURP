Shader "Effect/Rotation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("透明度", Range(0,1)) = 1
        _RotationRange ("旋转范围", Range(0,90)) = 1
        _RotationSpeed ("旋转速度", Range(0,3)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType"="TransparentCutout"
            "ForceNoShadowCasting"="True" // 不产生阴影
            "IgnoreProject"="True" // 忽略投影
        }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags
            {
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
            uniform half _RotationRange;
            uniform half _RotationSpeed;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            #define PI2 6.283185307179586476925286766559f // 2 * PI

            void Rotation(inout float3 vertex) //inout是CG语言的一种"引用传递"方式,形参既用于输入时初始化，也用于输出数据 
            {
                //【顶点坐标y值变化】
                //
                float angleY = _RotationRange * sin(frac(_Time.x * _RotationSpeed) * PI2); //旋转角度(角度制)
                float radianY = radians(angleY); //角度->弧度
                //【定义三角函数】  sincos函数也用了inout “引用传递”，因此在函数前要给变量赋初值
                float sin_radianY, cos_radianY = 0.0; //变量赋初值
                sincos(radianY, sin_radianY, cos_radianY); //变量重新计算值
                //上边的代码相当于：
                // sin_radianY = sin(radianY);
                // cos_radianY = cos(radianY);
                //【构造旋转矩阵】
                float2x2 Rotate_Matrix_Y = float2x2(cos_radianY, sin_radianY, -sin_radianY, cos_radianY);
                vertex.xz = mul(Rotate_Matrix_Y, float2(vertex.x, vertex.z));
                //上边代码相当于：
                /*vertex.xz = float2(vertex.x * cos_radianY + vertex.z * sin_radianY ,
                                    -vertex.x * sin_radianY + vertex.z * cos_radianY);
                */
            }

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                Rotation(v.vertex.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);
                return var_MainTex * var_MainTex.a;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}