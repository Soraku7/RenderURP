// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SplitScreen" {
	Properties {
		_MainTex ("MainTex", 2D) = "white" {}
		_OtherTex1 ("left down Tex1", 2D) = "white" {}		
		_OtherTex2 ("mid down Tex2", 2D) = "white" {}
		_OtherTex3 ("right down Tex3", 2D) = "white" {}
		_OtherTex4 ("left up Tex4", 2D) = "white" {}
		_OtherTex5 ("mid up Tex5", 2D) = "white" {}
		_OtherTex6 ("right up Tex6", 2D) = "white" {}

	}
 
 
	SubShader {
	Tags {"Queue"="Transparent" 
		"IgnoreProjector"="True" 
		"RenderType"="Transparent"
	}
	LOD 100
	
	Cull Off
	Blend Off//关闭混合
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
 
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
 
			struct v2f {
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
			};
 
			sampler2D _MainTex;
			uniform sampler2D _OtherTex1;
			uniform sampler2D _OtherTex2;
			uniform sampler2D _OtherTex3;
			uniform sampler2D _OtherTex4;
			uniform sampler2D _OtherTex5;
			uniform sampler2D _OtherTex6;
			float4 _MainTex_ST;
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				half2 otherTexcoord1 = half2(i.texcoord.x, 1 - i.texcoord.y);
				half2 otherTexcoord2 = half2(i.texcoord.x, 1 - i.texcoord.y);
				half2 otherTexcoord3 = half2(i.texcoord.x, 1 - i.texcoord.y);
				half2 otherTexcoord4 = half2(i.texcoord.x, 1 - i.texcoord.y);
				half2 otherTexcoord5 = half2(i.texcoord.x, 1 - i.texcoord.y);
				half2 otherTexcoord6 = half2(i.texcoord.x, 1 - i.texcoord.y);
				
				float4 col = tex2D( _OtherTex1, otherTexcoord1) * floor(i.texcoord.x - 0.33) * floor(i.texcoord.y - 0.5)
				  + tex2D(_OtherTex2 , otherTexcoord2) * ceil(i.texcoord.x - 0.33) * floor(i.texcoord.x - 0.66)* floor(i.texcoord.y * _ProjectionParams.x- 0.5)
				  + tex2D(_OtherTex3 , otherTexcoord3) * ceil(i.texcoord.x - 0.66) * floor(i.texcoord.x - 1)* floor(i.texcoord.y * _ProjectionParams.x- 0.5)
				 + tex2D(_OtherTex4 , otherTexcoord4) * floor(i.texcoord.x - 0.33)* ceil(i.texcoord.y - 0.5) * floor(i.texcoord.y - 1)
				 + tex2D(_OtherTex5 , otherTexcoord5) * ceil(i.texcoord.x - 0.33) * floor(i.texcoord.x - 0.66)* ceil(i.texcoord.y - 0.5) * floor(i.texcoord.y - 1)
				 + tex2D(_OtherTex6 , otherTexcoord6) * ceil(i.texcoord.x - 0.66) * floor(i.texcoord.x - 1)* ceil(i.texcoord.y - 0.5) * floor(i.texcoord.y - 1);
				
				return col;
			}
		ENDCG
	}
}
	FallBack "Diffuse"
}