package ManaMason.Utils 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	public class BlueprintOption 
	{
		public static const PLACE_WALLS: String = "Place Walls";
		public static const CONJURE_GEMS: String = "Conjure Gems";
		public static const BUILD_ON_PATH: String = "Build on Path";
		public static const PLACE_AMPLIFIERS: String = "Place Amplifiers";
		public static const PLACE_TOWERS: String = "Place Towers";
		public static const PLACE_LANTERNS: String = "Place Lanterns";
		public static const PLACE_TRAPS: String = "Place Traps";
		public static const PLACE_PYLONS: String = "Place Pylons";
		public static const SPEND_MANA: String = "Spend Mana";
		public static const TRACK_STATS: String = "Track Stats";
		public static const SHOW_UNPLACED: String = "Show Unplaced";
		
		public var name:String;
		public var visible:Boolean;
		public var value:Boolean;
		
		public function BlueprintOption(name: String, value: Boolean, visible: Boolean) 
		{
			this.name = name;
			this.value = value;
			this.visible = visible;
		}
	}

}