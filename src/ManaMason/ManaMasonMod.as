package ManaMason 
{
	import Bezel.Bezel;
	import Bezel.BezelMod;
	import Bezel.GCFW.GCFWBezel;
	import Bezel.Logger;
	
	import flash.display.MovieClip;
	/**
	 * ...
	 * @author Hellrage
	 */
	public class ManaMasonMod extends MovieClip implements BezelMod
	{
		
		public function get VERSION():String { return "1.6"; }
		public function get BEZEL_VERSION():String { return "1.0.1"; }
		public function get MOD_NAME():String { return "ManaMason"; }
		
		private var manaMason:Object;
		
		internal static var bezel:Bezel;
		internal static var logger:Logger;
		internal static var instance:ManaMasonMod;
		
		public static var gemTypeToName: Array;

		public static const GCFW_VERSION:String = "1.2.1a";
		
		public function ManaMasonMod() 
		{
			super();
			instance = this;
		}
		
		// This method binds the class to the game's objects
		public function bind(modLoader:Bezel, gameObjects:Object):void
		{
			bezel = modLoader;
			logger = bezel.getLogger("ManaMason");
			if (bezel.mainLoader is GCFWBezel)
			{
				manaMason = new GCFWManaMason();
				gemTypeToName = new Array();
				gemTypeToName[0] = "yellow";
				gemTypeToName[1] = "orange";
				gemTypeToName[2] = "red";
				gemTypeToName[3] = "purple";
				gemTypeToName[4] = "green";
				gemTypeToName[5] = "slowing";
			}
		}
		
		public function unload():void
		{
			if (manaMason != null)
			{
				manaMason.unload();
				manaMason = null;
			}
		}
		
		public function prettyVersion(): String
		{
			return 'v' + VERSION + ' for ' + GCFW_VERSION;
		}
	}

}
