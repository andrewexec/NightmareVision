package funkin.graphics;

import openfl.display.BitmapData;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

import funkin.objects.FunkinSprite;

import openfl.filters.BitmapFilter;

import animate.internal.FilterRenderer;

@:access(animate.FlxAnimate)
@:access(funkin.objects.FunkinSprite)
@:access(openfl.filters.BitmapFilter)
@:access(animate.internal.FilterRenderer)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.BitmapData)
@:nullSafety
class FunkinFilterRenderer implements IFlxDestroyable
{
	public var graphic(default, null):Null<FlxGraphic>;
	
	var bitmapPool:Map<String, Array<BitmapData>> = [];
	var parent:FunkinSprite;
	
	public function new(parent:FunkinSprite)
	{
		this.parent = parent;
	}
	
	public function applyFilters():Void
	{
		parent.filtered = false;
		if (parent.filters == null || parent.filters.length < 1) return;
		if (parent._renderTexture == null) return;
		
		final textureBitmap:BitmapData = parent._renderTexture.graphic.bitmap;
		
		final bounds:FlxRect = FlxRect.get().copyFromFlash(textureBitmap.rect);
		FilterRenderer.expandFilterBounds(bounds, parent.filters);
		parent.filterOffsets[0] = bounds.x * parent.scale.x;
		parent.filterOffsets[1] = bounds.y * parent.scale.x;
		
		final ceilWidth:Int = Math.ceil(bounds.width);
		final ceilHeight:Int = Math.ceil(bounds.height);
		
		if (graphic != null) putBitmap(graphic.bitmap);
		final bitmap:BitmapData = getBitmap(ceilWidth, ceilHeight);
		
		if (graphic == null)
		{
			graphic = FlxGraphic.fromBitmapData(bitmap, false, null, false);
		}
		else
		{
			graphic.bitmap = bitmap;
			graphic.imageFrame.frame.frame.set(0, 0, bitmap.width, bitmap.height);
		}
		
		var filterBmp1:Null<BitmapData> = null;
		var filterBmp2:Null<BitmapData> = null;
		
		var needsSecondBitmap:Bool = false;
		var needsPreserveObject:Bool = false;
		for (filter in parent.filters)
		{
			if (filter != null)
			{
				if (filter.__needSecondBitmapData) needsSecondBitmap = true;
				if (filter.__preserveObject) needsPreserveObject = true;
			}
		}
		
		if (needsSecondBitmap) filterBmp1 = getBitmap(graphic.width, graphic.height);
		if (needsPreserveObject) filterBmp2 = getBitmap(filterBmp1?.width ?? 1, filterBmp1?.height ?? 1);
		
		_applyFilters(graphic.bitmap, textureBitmap, parent.filters, filterBmp1, filterBmp2, bounds);
		
		if (filterBmp1 != null) putBitmap(filterBmp1);
		if (filterBmp2 != null) putBitmap(filterBmp2);
		
		bounds.put();
		parent.filtered = true;
	}
	
	function _applyFilters(target:BitmapData, bmp:BitmapData, filters:Array<BitmapFilter>, target1:Null<BitmapData>, target2:Null<BitmapData>, bounds:FlxRect):Void
	{
		final renderer = FilterRenderer.renderer;
		
		var bitmap:BitmapData = target;
		final bitmap2:BitmapData = target1 ?? bmp;
		final bitmap3:BitmapData = target2 ?? bmp;
		
		renderer.__setBlendMode(NORMAL);
		renderer.__worldAlpha = 1;
		if (renderer.__worldTransform == null)
		{
			renderer.__worldTransform = new openfl.geom.Matrix();
			renderer.__worldColorTransform = new openfl.geom.ColorTransform();
		}
		renderer.__worldTransform.identity();
		renderer.__worldColorTransform.__identity();
		bmp.__renderTransform.identity();
		bmp.__renderTransform.translate(-bounds.x, -bounds.y);
		renderer.setShader(renderer.__defaultShader);
		renderer.__setRenderTarget(bitmap);
		renderer.__scissorRect(null);
		renderer.__renderFilterPass(bmp, renderer.__defaultDisplayShader, true);
		
		for (filter in filters)
		{
			if (filter == null) continue;
			bitmap = FilterRenderer.__renderGpuFilter(filter, bitmap, bitmap2, bitmap3);
		}
	}
	
	function getBitmap(width:Int, height:Int):BitmapData
	{
		final id:String = Std.string(width) + 'x' + Std.string(height);
		final bitmaps:Array<BitmapData> = bitmapPool.get(id) ?? [];
		if (bitmaps.length < 1)
		{
			final bitmap:BitmapData = FixedBitmapData.create(width, height);
			bitmaps.push(bitmap);
		}
		final bitmap:Null<BitmapData> = bitmaps.shift();
		if (bitmap == null) throw 'FunkinFilterRenderer.getBitmap: pooled bitmap was null';
		bitmap.__fillRect(bitmap.rect, 0, true);
		bitmapPool.set(id, bitmaps);
		return bitmap;
	}
	
	function putBitmap(bitmap:BitmapData):Void
	{
		final id:String = Std.string(bitmap.width) + 'x' + Std.string(bitmap.height);
		final bitmaps:Array<BitmapData> = bitmapPool.get(id) ?? [];
		if (!bitmaps.contains(bitmap)) bitmaps.push(bitmap);
		bitmapPool.set(id, bitmaps);
	}
	
	public function destroy():Void
	{
		for (bitmaps in bitmapPool.iterator())
		{
			for (bitmap in bitmaps)
			{
				if (bitmap.__texture != null) bitmap.__texture.dispose();
				bitmap.dispose();
			}
		}
	}
}
