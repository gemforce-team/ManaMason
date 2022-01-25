package ManaMason 
{
	import Bezel.Bezel;
	import Bezel.BezelMod;
	import Bezel.GCCS.GCCSBezel;
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

		public static const GCCS_VERSION:String = "1.0.6";
		
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
			if (bezel.mainLoader is GCCSBezel)
			{
				manaMason = new GCCSManaMason();
				gemTypeToName = new Array();
				gemTypeToName[0] = "orange";
				gemTypeToName[1] = "yellow";
				gemTypeToName[2] = "white";
				gemTypeToName[3] = "red";
				gemTypeToName[4] = "green";
				gemTypeToName[5] = "cyan";
				gemTypeToName[6] = "black";
				gemTypeToName[7] = "blue";
				gemTypeToName[8] = "purple";
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
			return 'v' + VERSION + ' for ' + GCCS_VERSION;
		}
	}

}
