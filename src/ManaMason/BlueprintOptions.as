package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	public class BlueprintOptions 
	{
		private static var DEFAULT_OPTIONS:Vector.<Object> = new <Object>[
			{"name":"Build on Path", "value":false},
			{"name":"Conjure Gems", "value":false},
			{"name":"Place Walls", "value":true},
			{"name":"Place Amplifiers", "value":true},
			{"name":"Place Towers", "value":true},
			{"name":"Place Lanterns", "value":true},
			{"name":"Place Traps", "value":true},
			{"name":"Place Pylons", "value":true},
			{"name":"Show Unplaced", "value":true}
		];
		
		public var options: Vector.<Object>;

		public function get optionsObject():Object
		{
			var ret:Object = new Object();
			for each (var option:Object in options)
			{
				ret[option.name] = option.value;
			}
			return ret;
		}
		
		public function BlueprintOptions() 
		{
			this.options = DEFAULT_OPTIONS.concat();
		}
	}

}
