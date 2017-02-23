package lime.utils;


import haxe.CallStack;
import haxe.Unserializer;
import lime.app.Event;
import lime.app.Promise;
import lime.app.Future;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;
import lime.utils.Log;

#if !macro
import haxe.Json;
#end


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the Lime command-line tools, based on the
 * contents of the *.xml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime.utils.AssetLibrary)


class Assets {
	
	
	public static var cache:AssetCache = new AssetCache ();
	public static var libraries (default, null) = new Map<String, AssetLibrary> ();
	public static var onChange = new Event<Void->Void> ();
	
	
	public static function exists (id:String, type:AssetType = null):Bool {
		
		#if (tools && !display)
		
		if (type == null) {
			
			type = BINARY;
			
		}
		
		var symbol = new LibrarySymbol (id);
		
		if (symbol.library != null) {
			
			return symbol.exists (type);
			
		}
		
		#end
		
		return false;
		
	}
	
	
	/**
	 * Gets an instance of a cached or embedded asset
	 * @usage		var sound = Assets.getAsset("sound.wav", SOUND);
	 * @param	id		The ID or asset path for the asset
	 * @return		An Asset object, or null.
	 */
	public static function getAsset (id:String, type:AssetType, useCache:Bool):Dynamic {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			switch (type) {
				
				case BINARY, TEXT: // Not cached
					
					useCache = false;
				
				case FONT:
					
					var font = cache.font.get (id);
					
					if (font != null) {
						
						return font;
						
					}
				
				case IMAGE:
					
					var image = cache.image.get (id);
					
					if (isValidImage (image)) {
						
						return image;
						
					}
				
				case MUSIC, SOUND:
					
					var audio = cache.audio.get (id);
					
					if (isValidAudio (audio)) {
						
						return audio;
						
					}
				
				case TEMPLATE:
					
					throw "Not sure how to get template: " + id;
				
			}
			
		}
		
		var symbol = new LibrarySymbol (id);
		
		if (symbol.library != null) {
			
			if (symbol.exists (type)) {
				
				if (symbol.isLocal (type)) {
					
					var asset = symbol.library.getAsset (symbol.symbolName, type);
					
					if (useCache && cache.enabled) {
						
						cache.set (id, type, asset);
						
					}
					
					return asset;
					
				} else {
					
					Log.error (type + " asset \"" + id + "\" exists, but only asynchronously");
					
				}
				
			} else {
				
				Log.error ("There is no " + type + " asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.error ("There is no asset library named \"" + symbol.libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded sound
	 * @usage		var sound = Assets.getSound("sound.wav");
	 * @param	id		The ID or asset path for the sound
	 * @return		A new Sound object
	 */
	public static function getAudioBuffer (id:String, useCache:Bool = true):AudioBuffer {
		
		return cast getAsset (id, SOUND, useCache);
		
	}
	
	
	/**
	 * Gets an instance of an embedded binary asset
	 * @usage		var bytes = Assets.getBytes("file.zip");
	 * @param	id		The ID or asset path for the file
	 * @return		A new Bytes object
	 */
	public static function getBytes (id:String):Bytes {
		
		return cast getAsset (id, BINARY, false);
		
	}
	
	
	/**
	 * Gets an instance of an embedded font
	 * @usage		var fontName = Assets.getFont("font.ttf").fontName;
	 * @param	id		The ID or asset path for the font
	 * @return		A new Font object
	 */
	public static function getFont (id:String, useCache:Bool = true):Font {
		
		return getAsset (id, FONT, useCache);
		
	}
	
	
	/**
	 * Gets an instance of an embedded bitmap
	 * @usage		var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
	 * @param	id		The ID or asset path for the bitmap
	 * @param	useCache		(Optional) Whether to use BitmapData from the cache(Default: true)
	 * @return		A new BitmapData object
	 */
	public static function getImage (id:String, useCache:Bool = true):Image {
		
		return getAsset (id, IMAGE, useCache);
		
	}
	
	
	public static function getLibrary (name:String):AssetLibrary {
		
		if (name == null || name == "") {
			
			name = "default";
			
		}
		
		return libraries.get (name);
		
	}
	
	
	/**
	 * Gets the file path (if available) for an asset
	 * @usage		var path = Assets.getPath("image.jpg");
	 * @param	id		The ID or asset path for the asset
	 * @return		The path to the asset (or null)
	 */
	public static function getPath (id:String):String {
		
		#if (tools && !display)
		
		var symbol = new LibrarySymbol (id);
		
		if (symbol.library != null) {
			
			if (symbol.exists ()) {
				
				return symbol.library.getPath (symbol.symbolName);
				
			} else {
				
				Log.error ("There is no asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			Log.error ("There is no asset library named \"" + symbol.libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded text asset
	 * @usage		var text = Assets.getText("text.txt");
	 * @param	id		The ID or asset path for the file
	 * @return		A new String object
	 */
	public static function getText (id:String):String {
		
		return getAsset (id, TEXT, false);
		
	}
	
	
	public static function isLocal (id:String, type:AssetType = null, useCache:Bool = true):Bool {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			if (cache.exists(id, type)) return true;
			
		}
		
		var symbol = new LibrarySymbol (id);
		return symbol.library != null && symbol.isLocal (type);
		
		#else
		
		return false;
		
		#end
		
	}
	
	
	private static function isValidAudio (buffer:AudioBuffer):Bool {
		
		// TODO: Check disposed
		
		return buffer != null;
		
	}
	
	
	private static function isValidImage (image:Image):Bool {
		
		// TODO: Check disposed
		
		return (image != null && image.buffer != null);
		
	}
	
	
	public static function list (type:AssetType = null):Array<String> {
		
		var items = [];
		
		for (library in libraries) {
			
			var libraryItems = library.list (type);
			
			if (libraryItems != null) {
				
				items = items.concat (libraryItems);
				
			}
			
		}
		
		return items;
		
	}
	
	
	public static function loadAsset (id:String, type:AssetType, useCache:Bool):Future<Dynamic> {
		
		#if (tools && !display)
		
		if (useCache && cache.enabled) {
			
			switch (type) {
				
				case BINARY, TEXT: // Not cached
					
					useCache = false;
				
				case FONT:
					
					var font = cache.font.get (id);
					
					if (font != null) {
						
						return Future.withValue (font);
						
					}
				
				case IMAGE:
					
					var image = cache.image.get (id);
					
					if (isValidImage (image)) {
						
						return Future.withValue (image);
						
					}
				
				case MUSIC, SOUND:
					
					var audio = cache.audio.get (id);
					
					if (isValidAudio (audio)) {
						
						return Future.withValue (audio);
						
					}
				
				case TEMPLATE:
					
					throw "Not sure how to get template: " + id;
				
			}
			
		}
		
		var symbol = new LibrarySymbol (id);
		
		if (symbol.library != null) {
			
			if (symbol.exists (type)) {
				
				var future = symbol.library.loadAsset (symbol.symbolName, type);
				
				if (useCache && cache.enabled) {
					
					future.onComplete (function (asset) cache.set (id, type, asset));
					
				}
				
				return future;
				
			} else {
				
				return Future.withError ("There is no " + type + " asset with an ID of \"" + id + "\"");
				
			}
			
		} else {
			
			return Future.withError ("There is no asset library named \"" + symbol.libraryName + "\"");
			
		}
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	public static function loadAudioBuffer (id:String, useCache:Bool = true):Future<AudioBuffer> {
		
		return cast loadAsset (id, SOUND, useCache);
		
	}
	
	
	public static function loadBytes (id:String):Future<Bytes> {
		
		return cast loadAsset (id, BINARY, false);
		
	}
	
	
	public static function loadFont (id:String, useCache:Bool = true):Future<Font> {
		
		return cast loadAsset (id, FONT, useCache);
		
	}
	
	
	public static function loadImage (id:String, useCache:Bool = true):Future<Image> {
		
		return cast loadAsset (id, IMAGE, useCache);
		
	}
	
	
	public static function loadLibrary (name:String):Future<AssetLibrary> {
		
		var promise = new Promise<AssetLibrary> ();
		
		#if (tools && !display && !macro)
		
		loadText ("libraries/" + name + ".json").onComplete (function (data) {
			
			// TODO: Smarter base path logic
			var manifest = AssetManifest.parse (data);
			
			if (manifest == null) {
				
				promise.error ("Cannot parse asset manifest for library \"" + name + "\"");
				return;
				
			}
			
			#if (ios || tvos)
			if (manifest.rootPath == null || manifest.rootPath == "") {
				
				manifest.rootPath = "assets/";
				
			}
			#end
			
			var library = AssetLibrary.fromManifest (manifest);
			
			if (library == null) {
				
				promise.error ("Cannot open library \"" + name + "\"");
				
			} else {
				
				libraries.set (name, library);
				library.onChange.add (onChange.dispatch);
				promise.completeWith (library.load ());
				
			}
			
		}).onError (function (_) {
			
			promise.error ("There is no asset library named \"" + name + "\"");
			
		});
		
		#end
		
		return promise.future;
		
	}
	
	
	public static function loadText (id:String):Future<String> {
		
		return cast loadAsset (id, TEXT, false);
		
	}
	
	
	public static function registerLibrary (name:String, library:AssetLibrary):Void {
		
		if (libraries.exists (name)) {
			
			if (libraries.get (name) == library) {
				
				return;
				
			} else {
				
				unloadLibrary (name);
				
			}
			
		}
		
		if (library != null) {
			
			library.onChange.add (library_onChange);
			
		}
		
		libraries.set (name, library);
		
	}
	
	
	public static function unloadLibrary (name:String):Void {
		
		#if (tools && !display)
		
		var library = libraries.get (name);
		
		if (library != null) {
			
			cache.clear (name + ":");
			library.onChange.remove (library_onChange);
			library.unload ();
			
		}
		
		libraries.remove (name);
		
		#end
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function library_onChange ():Void {
		
		cache.clear ();
		onChange.dispatch ();
		
	}
	
	
}


private class LibrarySymbol {
	
	
	public var library (default, null):AssetLibrary;
	public var libraryName (default, null):String;
	public var symbolName (default, null):String;
	
	
	public inline function new (id:String) {
		
		var colonIndex = id.indexOf (":");
		libraryName = id.substring (0, colonIndex);
		symbolName = id.substring (colonIndex + 1);
		library = Assets.getLibrary (libraryName);
		
	}
	
	
	public inline function isLocal (?type) return library.isLocal (symbolName, type);
	public inline function exists  (?type) return library.exists  (symbolName, type);
	
}