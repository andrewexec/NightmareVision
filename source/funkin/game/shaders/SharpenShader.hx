package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;

class SharpenShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float amount;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec2 texel = 1.0 / openfl_TextureSize;

			vec4 center = texture2D(bitmap, uv);
			vec4 neighborSum = texture2D(bitmap, uv + vec2(-texel.x, 0.0))
				+ texture2D(bitmap, uv + vec2(texel.x, 0.0))
				+ texture2D(bitmap, uv + vec2(0.0, -texel.y))
				+ texture2D(bitmap, uv + vec2(0.0, texel.y));

			gl_FragColor = clamp(center + (center * 4.0 - neighborSum) * amount, 0.0, 1.0);
		}
	')
	public function new(amount:Float = 0.15)
	{
		super();
		
		this.amount.value = [amount];
	}
}
