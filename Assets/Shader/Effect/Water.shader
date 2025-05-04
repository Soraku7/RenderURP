Shader "URP/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor", Color) = (1,0,0,1)  
    }
    
    SubShader
    {
        Tags
        {
                 "Queue"="Geometry" 
                 "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Name "URPUnlit"
           
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    
                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };
    
                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };
    
                sampler2D _MainTex;
                float4 _MainTex_ST;
                half4 _BaseColor;  

                v2f vert (appdata v)
                {
                    v2f o;
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                    o.vertex = vertexInput.positionCS;
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }
    
                half4 frag (v2f i) : SV_Target
                {
                    half4 texColor = tex2D(_MainTex, i.uv);
                    half3 color = texColor.rgb * _BaseColor.rgb;
                    return half4(color, texColor.a);
                }
                ENDHLSL
        }
        
    }
}