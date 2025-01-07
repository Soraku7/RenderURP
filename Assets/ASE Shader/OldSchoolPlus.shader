// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "OldSchoolPlus"
{
	Properties
	{
		_Specular("Specular", Range( 1 , 10)) = 1
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldNormal;
			float3 worldPos;
			float3 viewDir;
		};

		uniform float _Specular;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult3 = dot( ase_worldNormal , ase_worldlightDir );
			float4 color6 = IsGammaSpace() ? float4(0.899225,0.03137254,0.9254902,0) : float4(0.7858797,0.002428215,0.8387991,0);
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 ase_objectlightDir = normalize( ObjSpaceLightDir( ase_vertex4Pos ) );
			float dotResult22 = dot( reflect( ( ase_objectlightDir * -1.0 ) , ase_worldNormal ) , i.viewDir );
			float4 color25 = IsGammaSpace() ? float4(0,0.8980392,0.6733639,0) : float4(0,0.7835379,0.4109891,0);
			float temp_output_29_0 = max( ase_worldNormal.y , 0.0 );
			float4 color31 = IsGammaSpace() ? float4(0.4968057,0.7169812,0.3551086,0) : float4(0.2110964,0.4725527,0.1035503,0);
			float temp_output_35_0 = max( ( ase_worldNormal.y * -1.0 ) , 0.0 );
			float4 color42 = IsGammaSpace() ? float4(0.3127408,0.7924528,0.1233535,0) : float4(0.07970666,0.5911142,0.01403686,0);
			float4 color38 = IsGammaSpace() ? float4(0.1191118,0.5471698,0,0) : float4(0.01324896,0.2603273,0,0);
			o.Emission = ( ( ( ( max( dotResult3 , 0.0 ) * color6 ) + pow( max( dotResult22 , 0.0 ) , _Specular ) ) * color25 ) + ( ( ( temp_output_29_0 * color31 ) + ( ( ( 1.0 - temp_output_29_0 ) - temp_output_35_0 ) * color42 ) ) + ( temp_output_35_0 * color38 ) ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = worldViewDir;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
88;203;1280;713;118.7485;438.8342;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;21;-1800.009,-284.6499;Inherit;False;1506.475;383.0322;Phong;11;20;9;10;11;13;12;14;16;17;19;22;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;46;-2008.355,340.9815;Inherit;False;1807.882;1065.152;3Col;17;27;30;34;36;29;33;35;40;41;42;31;38;43;32;39;37;44;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1671.125,-59.64985;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ObjSpaceLightDirHlpNode;9;-1750.009,-234.2518;Inherit;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;30;-1638.441,558.2702;Inherit;False;Constant;_Float3;Float 3;1;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-1831.296,1171.282;Inherit;False;Constant;_Float4;Float 4;1;0;Create;True;0;0;False;0;False;-1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;27;-1958.355,491.8284;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;13;-1446.713,-97.61765;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-1459.125,-234.6499;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;8;-1540.274,-888.884;Inherit;False;1004.964;474.0526;Lambort;7;3;5;4;6;7;2;1;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-1546.637,1203.134;Inherit;False;Constant;_Float5;Float 5;1;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;2;-1505.274,-614.7446;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ReflectOpNode;12;-1245.713,-234.6176;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;29;-1473.934,391.279;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;1;-1498.953,-795.9985;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;14;-1158.713,-89.61765;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-1622.296,1068.282;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;35;-1355.637,1069.134;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-896.4462,-46.83558;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;22;-956.7854,-228.2512;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;40;-1351.524,739.2437;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;3;-1195.752,-791.1749;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;5;-1145.924,-618.3008;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;31;-1295.056,527.9814;Inherit;False;Constant;_EnvUpCol;EnvUpCol;1;0;Create;True;0;0;False;0;False;0.4968057,0.7169812,0.3551086,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;19;-722.5337,-47.50525;Inherit;False;Property;_Specular;Specular;0;0;Create;True;0;0;False;0;False;1;1;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;6;-935.3095,-626.8313;Inherit;False;Constant;_BaseCol;BaseCol;0;0;Create;True;0;0;False;0;False;0.899225,0.03137254,0.9254902,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;41;-1143.601,739.9014;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;16;-722.4462,-229.8356;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;4;-947.8811,-789.1972;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;42;-1143.596,856.1874;Inherit;False;Constant;_EnvSideCol;EnvSideCol;1;0;Create;True;0;0;False;0;False;0.3127408,0.7924528,0.1233535,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;38;-1304.637,1194.134;Inherit;False;Constant;_EnvDownCol;EnvDownCol;1;0;Create;True;0;0;False;0;False;0.1191118,0.5471698,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;20;-470.5337,-225.5052;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;32;-1026.056,390.9815;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-891.5962,739.1874;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-673.7165,-788.6947;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-708.6,581.3088;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;-194.5337,-325.5052;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;25;-216.5561,-148.5264;Inherit;False;Constant;_LightCol;LightCol;1;0;Create;True;0;0;False;0;False;0,0.8980392,0.6733639,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1077.637,1071.134;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;16.01153,-322.5264;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;-435.473,585.8522;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;45;277.6899,45.79346;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;575.1735,-93.43646;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;OldSchoolPlus;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;11;0;9;0
WireConnection;11;1;10;0
WireConnection;12;0;11;0
WireConnection;12;1;13;0
WireConnection;29;0;27;2
WireConnection;29;1;30;0
WireConnection;33;0;27;2
WireConnection;33;1;34;0
WireConnection;35;0;33;0
WireConnection;35;1;36;0
WireConnection;22;0;12;0
WireConnection;22;1;14;0
WireConnection;40;0;29;0
WireConnection;3;0;1;0
WireConnection;3;1;2;0
WireConnection;41;0;40;0
WireConnection;41;1;35;0
WireConnection;16;0;22;0
WireConnection;16;1;17;0
WireConnection;4;0;3;0
WireConnection;4;1;5;0
WireConnection;20;0;16;0
WireConnection;20;1;19;0
WireConnection;32;0;29;0
WireConnection;32;1;31;0
WireConnection;43;0;41;0
WireConnection;43;1;42;0
WireConnection;7;0;4;0
WireConnection;7;1;6;0
WireConnection;39;0;32;0
WireConnection;39;1;43;0
WireConnection;18;0;7;0
WireConnection;18;1;20;0
WireConnection;37;0;35;0
WireConnection;37;1;38;0
WireConnection;26;0;18;0
WireConnection;26;1;25;0
WireConnection;44;0;39;0
WireConnection;44;1;37;0
WireConnection;45;0;26;0
WireConnection;45;1;44;0
WireConnection;0;2;45;0
ASEEND*/
//CHKSM=A1A845621417E4F6A32C72C47A123184F07649B5