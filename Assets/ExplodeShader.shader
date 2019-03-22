Shader "Custom/Explode"
{
    Properties
    {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}

		_NoiseScale ("NoiseScale", Float) = 100.0
		_Speed("Speed", Float) = 10
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
			#pragma geometry geom
            #pragma fragment frag
												
			struct vertexInput
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float2 texcoord : TEXCOORD0; 
			};
						
			
			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform float _NoiseScale;
			uniform float _Speed;
			uniform float _StartTime;
			

			// Ref : https://github.com/Unity-Technologies/ShaderGraph/wiki/Simple-Noise-Node

			inline float unity_noise_randomValue (float2 uv)
			{
				return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
			}

			inline float unity_noise_interpolate (float a, float b, float t)
			{
				return (1.0-t)*a + (t*b);
			}

			inline float unity_valueNoise (float2 uv)
			{
				float2 i = floor(uv);
				float2 f = frac(uv);
				f = f * f * (3.0 - 2.0 * f);

				uv = abs(frac(uv) - 0.5);
				float2 c0 = i + float2(0.0, 0.0);
				float2 c1 = i + float2(1.0, 0.0);
				float2 c2 = i + float2(0.0, 1.0);
				float2 c3 = i + float2(1.0, 1.0);
				float r0 = unity_noise_randomValue(c0);
				float r1 = unity_noise_randomValue(c1);
				float r2 = unity_noise_randomValue(c2);
				float r3 = unity_noise_randomValue(c3);

				float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
				float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
				float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
				return t;
			}
			

			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;
				UNITY_INITIALIZE_OUTPUT(vertexOutput, o); // d3d11 requires initialization
				o.pos = v.vertex;
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				
				return o;
			}

			[maxvertexcount(3)]
			void geom (triangle vertexOutput input[3], inout TriangleStream<vertexOutput> tristream)
			{
				static bool first = true;
				static float3 u = float3(0,0,0);

				if(first == true)
				{
					first = false;

					// Ref : https://github.com/Unity-Technologies/ShaderGraph/wiki/Simple-Noise-Node
					float t = 0.0;
					for(int i = 0; i < 3; i++)
					{
						float freq = pow(2.0, float(i));
						float amp = pow(0.5, float(3-i));
						t += unity_valueNoise(input[i].texcoord * _NoiseScale/freq)*amp;
					}

					t += 0.1;
										
					float4 v1 = input[1].pos - input[0].pos;
					float4 v2 = input[2].pos - input[0].pos;

					float3 norm = normalize(cross(v1.xyz, v2.xyz));

					u = norm * float3(t * _Speed, t * _Speed, t * _Speed);
				}
								
				vertexOutput o;
				
				for(int i = 0; i < 3; i++)
                {
					float4 tempPos = input[i].pos;
					
					float realTime = _Time.y - _StartTime;
					
					float3 factor;
					factor = u * realTime;

					tempPos += float4(factor.x, factor.y, factor.z, 1);

                    o.pos = UnityObjectToClipPos(tempPos);
                    o.texcoord  = input[i].texcoord;
                    
					tristream.Append(o);
				}

				tristream.RestartStrip();
			}

			half4 frag(vertexOutput i) : SV_Target
			{
				return tex2D(_MainTex, i.texcoord) * _Color;
			}

            ENDCG
        }
    }
}