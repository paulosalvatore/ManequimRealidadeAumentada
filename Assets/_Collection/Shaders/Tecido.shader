// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Tecido"
{
	Properties
	{
		_AlbedoColor("Albedo Color", Color) = (0,0,0,0)
		_AlbedoColorAlpha("Albedo Color Alpha", Range( 0 , 1)) = 1
		_AlbedoTexture("Albedo Texture", 2D) = "white" {}
		_AlbedoTextureAlpha("Albedo Texture Alpha", Range( 0 , 1)) = 1
		_Specular("Specular", Range( 0 , 1)) = 0
		_SpecularColor("Specular Color", Color) = (0,0,0,0)
		_SpecularColorAlpha("Specular Color Alpha", Range( 0 , 1)) = 1
		_SpecularTexture("Specular Texture", 2D) = "white" {}
		_SpecularTextureAlpha("Specular Texture Alpha", Range( 0 , 1)) = 1
		_Opacity("Opacity", Range( 0 , 1)) = 0
		[Header(Refraction)]
		_ChromaticAberration("Chromatic Aberration", Range( 0 , 0.3)) = 0.1
		_IndexofRefraction("Index of Refraction", Range( -3 , 4)) = 1
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.8
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Transparent+0" }
		Cull Off
		GrabPass{ }
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile _ALPHAPREMULTIPLY_ON
		struct Input
		{
			float2 uv_texcoord;
			float4 screenPos;
			float3 worldPos;
		};

		uniform float4 _AlbedoColor;
		uniform float _AlbedoColorAlpha;
		uniform sampler2D _AlbedoTexture;
		uniform float4 _AlbedoTexture_ST;
		uniform float _AlbedoTextureAlpha;
		uniform float4 _SpecularColor;
		uniform float _SpecularColorAlpha;
		uniform sampler2D _SpecularTexture;
		uniform float4 _SpecularTexture_ST;
		uniform float _SpecularTextureAlpha;
		uniform float _Specular;
		uniform float _Smoothness;
		uniform float _Opacity;
		uniform sampler2D _GrabTexture;
		uniform float _ChromaticAberration;
		uniform float _IndexofRefraction;

		inline float4 Refraction( Input i, SurfaceOutputStandardSpecular o, float indexOfRefraction, float chomaticAberration ) {
			float3 worldNormal = o.Normal;
			float4 screenPos = i.screenPos;
			#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
			#else
				float scale = 1.0;
			#endif
			float halfPosW = screenPos.w * 0.5;
			screenPos.y = ( screenPos.y - halfPosW ) * _ProjectionParams.x * scale + halfPosW;
			#if SHADER_API_D3D9 || SHADER_API_D3D11
				screenPos.w += 0.00000000001;
			#endif
			float2 projScreenPos = ( screenPos / screenPos.w ).xy;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 refractionOffset = ( ( ( ( indexOfRefraction - 1.0 ) * mul( UNITY_MATRIX_V, float4( worldNormal, 0.0 ) ) ) * ( 1.0 / ( screenPos.z + 1.0 ) ) ) * ( 1.0 - dot( worldNormal, worldViewDir ) ) );
			float2 cameraRefraction = float2( refractionOffset.x, -( refractionOffset.y * _ProjectionParams.x ) );
			float4 redAlpha = tex2D( _GrabTexture, ( projScreenPos + cameraRefraction ) );
			float green = tex2D( _GrabTexture, ( projScreenPos + ( cameraRefraction * ( 1.0 - chomaticAberration ) ) ) ).g;
			float blue = tex2D( _GrabTexture, ( projScreenPos + ( cameraRefraction * ( 1.0 + chomaticAberration ) ) ) ).b;
			return float4( redAlpha.r, green, blue, redAlpha.a );
		}

		void RefractionF( Input i, SurfaceOutputStandardSpecular o, inout fixed4 color )
		{
			#ifdef UNITY_PASS_FORWARDBASE
				color.rgb = color.rgb + Refraction( i, o, _IndexofRefraction, _ChromaticAberration ) * ( 1 - color.a );
				color.a = 1;
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			o.Normal = float3(0,0,1);
			float4 temp_cast_0 = (1.0).xxxx;
			float4 lerpResult197 = lerp( temp_cast_0 , _AlbedoColor , _AlbedoColorAlpha);
			float4 temp_cast_1 = (1.0).xxxx;
			float2 uv_AlbedoTexture = i.uv_texcoord * _AlbedoTexture_ST.xy + _AlbedoTexture_ST.zw;
			float4 lerpResult191 = lerp( temp_cast_1 , tex2D( _AlbedoTexture, uv_AlbedoTexture ) , _AlbedoTextureAlpha);
			o.Albedo = ( lerpResult197 * lerpResult191 ).rgb;
			float4 temp_cast_3 = (1.0).xxxx;
			float4 lerpResult206 = lerp( temp_cast_3 , _SpecularColor , _SpecularColorAlpha);
			float4 temp_cast_4 = (1.0).xxxx;
			float2 uv_SpecularTexture = i.uv_texcoord * _SpecularTexture_ST.xy + _SpecularTexture_ST.zw;
			float4 lerpResult205 = lerp( temp_cast_4 , tex2D( _SpecularTexture, uv_SpecularTexture ) , _SpecularTextureAlpha);
			o.Specular = ( lerpResult206 * lerpResult205 * _Specular ).rgb;
			o.Smoothness = _Smoothness;
			o.Alpha = _Opacity;
			o.Normal = o.Normal + 0.00001 * i.screenPos * i.worldPos;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardSpecular keepalpha finalcolor:RefractionF fullforwardshadows exclude_path:deferred 

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
			# include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD6;
				float4 screenPos : TEXCOORD7;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.texcoords01 = float4( v.texcoord.xy, v.texcoord1.xy );
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord.xy = IN.texcoords01.xy;
				float3 worldPos = IN.worldPos;
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputStandardSpecular o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardSpecular, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=13701
7;29;1346;692;39.08684;-226.1163;2.110002;True;True
Node;AmplifyShaderEditor.CommentaryNode;208;641.8873,-148.3797;Float;False;899.8199;909.4552;;10;199;200;201;202;203;204;205;206;207;214;Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;194;598.8492,-1232.714;Float;False;943.0535;950.1736;;9;196;192;197;191;195;189;187;193;190;Albedo;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;199;705.1006,202.8066;Float;False;Property;_SpecularColorAlpha;Specular Color Alpha;6;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;195;651.8945,-932.4415;Float;False;Constant;_FloatAC;Float AC;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.SamplerNode;203;691.8873,340.56;Float;True;Property;_SpecularTexture;Specular Texture;7;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;200;707.7673,646.0749;Float;False;Property;_SpecularTextureAlpha;Specular Texture Alpha;8;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;204;703.6249,109.1062;Float;False;Constant;_FloatSAC;Float SAC;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.ColorNode;202;771.7975,-98.3798;Float;False;Property;_SpecularColor;Specular Color;5;0;0,0,0,0;0;5;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;190;656.0369,-395.4714;Float;False;Property;_AlbedoTextureAlpha;Albedo Texture Alpha;3;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;196;653.3701,-838.7404;Float;False;Property;_AlbedoColorAlpha;Albedo Color Alpha;1;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.SamplerNode;189;640.1568,-700.9868;Float;True;Property;_AlbedoTexture;Albedo Texture;2;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.ColorNode;187;720.0673,-1139.927;Float;False;Property;_AlbedoColor;Albedo Color;0;0;0,0,0,0;0;5;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;193;654.5614,-489.1727;Float;False;Constant;_FloatAT;Float AT;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;201;706.2917,552.3735;Float;False;Constant;_FloatSAT;Float SAT;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.LerpOp;197;1031.985,-966.1517;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.LerpOp;191;1034.65,-522.8831;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.LerpOp;206;1083.715,75.39621;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.LerpOp;205;1086.38,518.6632;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.RangedFloatNode;214;1250.871,665.3906;Float;False;Property;_Specular;Specular;4;0;0;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.CommentaryNode;213;650.6058,812.4227;Float;False;879.5928;567.7147;;4;210;212;211;209;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;115;1281.665,1417.022;Float;False;Property;_Smoothness;Smoothness;14;0;0.8;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;42;1279.905,1605.502;Float;False;Property;_Opacity;Opacity;11;0;0;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;41;1279.905,1509.502;Float;False;Property;_IndexofRefraction;Index of Refraction;13;0;1;-3;4;0;1;FLOAT
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;192;1320.976,-817.9133;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;1372.706,223.6337;Float;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.RangedFloatNode;210;715.0101,1074.236;Float;False;Constant;_FloatNAT;Float NAT;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.RangedFloatNode;211;716.4857,1167.938;Float;False;Property;_NormalMapAlpha;Normal Map Alpha;10;0;1;0;1;0;1;FLOAT
Node;AmplifyShaderEditor.SamplerNode;212;700.6058,862.4227;Float;True;Property;_NormalMap;Normal Map;9;0;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0.0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.0;False;5;COLOR;FLOAT;FLOAT;FLOAT;FLOAT
Node;AmplifyShaderEditor.LerpOp;209;1082.948,989.9004;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0;False;2;FLOAT;0,0,0,0;False;1;COLOR
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1856,832;Float;False;True;2;Float;ASEMaterialInspector;0;0;StandardSpecular;Tecido;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;3;False;0;0;Translucent;0.5;True;True;0;False;Opaque;Transparent;ForwardOnly;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;False;0;255;255;0;0;0;0;0;0;0;0;False;0;4;10;25;False;0.5;True;0;Zero;Zero;0;Zero;Zero;Add;Add;0;False;0;0,0,0,0;VertexOffset;False;Cylindrical;False;Relative;0;;-1;-1;12;-1;0;0;0;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0.0;False;5;FLOAT;0.0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0.0;False;9;FLOAT;0.0;False;10;FLOAT;0.0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;197;0;195;0
WireConnection;197;1;187;0
WireConnection;197;2;196;0
WireConnection;191;0;193;0
WireConnection;191;1;189;0
WireConnection;191;2;190;0
WireConnection;206;0;204;0
WireConnection;206;1;202;0
WireConnection;206;2;199;0
WireConnection;205;0;201;0
WireConnection;205;1;203;0
WireConnection;205;2;200;0
WireConnection;192;0;197;0
WireConnection;192;1;191;0
WireConnection;207;0;206;0
WireConnection;207;1;205;0
WireConnection;207;2;214;0
WireConnection;209;0;210;0
WireConnection;209;1;212;0
WireConnection;209;2;211;0
WireConnection;0;0;192;0
WireConnection;0;3;207;0
WireConnection;0;4;115;0
WireConnection;0;8;41;0
WireConnection;0;9;42;0
ASEEND*/
//CHKSM=E0BB1DD7F26A1126C931F60336056F996C548DCF