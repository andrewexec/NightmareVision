package funkin.options;

class Options
{
	public static var gpuOnlyBitmaps:Bool = #if (mac || web) false #else true #end; // causes issues on mac and web
}
