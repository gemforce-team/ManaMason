package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Utils.BlueprintOption;
	
	public class BlueprintOptions 
	{
		private static var DEFAULT_OPTIONS:Vector.<BlueprintOption> = new <BlueprintOption>[
			new BlueprintOption(BlueprintOption.PLACE_WALLS, true, true),
			new BlueprintOption(BlueprintOption.BUILD_ON_PATH, true, true),
			new BlueprintOption(BlueprintOption.CONJURE_GEMS, true, true),
			new BlueprintOption(BlueprintOption.PLACE_AMPLIFIERS, true, true),
			//new BlueprintOption(BlueprintOption.PLACE_LANTERNS, true, true),
			//new BlueprintOption(BlueprintOption.PLACE_PYLONS, true, true),
			new BlueprintOption(BlueprintOption.PLACE_TOWERS, true, true),
			new BlueprintOption(BlueprintOption.PLACE_TRAPS, true, true),
			new BlueprintOption(BlueprintOption.SHOW_UNPLACED, true, true),
			new BlueprintOption(BlueprintOption.SPEND_MANA, true, CONFIG::debug),
			new BlueprintOption(BlueprintOption.TRACK_STATS, true, CONFIG::debug)
		];
		
		public var options: Object;
		
		public function BlueprintOptions() 
		{
			this.options = new Object();
			for each(var option:BlueprintOption in DEFAULT_OPTIONS)
			{
				options[option.name] = new BlueprintOption(option.name, option.value, option.visible);
			}
		}
		
		public function read(optionName: String): Boolean
		{
			if (!options.hasOwnProperty(optionName))
				throw new Error("Tried to access an unknown BlueprintOption: " + optionName);
				
			return options[optionName].value;
		}
	}
}
