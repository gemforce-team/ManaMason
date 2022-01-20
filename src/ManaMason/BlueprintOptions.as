package ManaMason 
{
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Hellrage
	 */
	public class BlueprintOptions 
	{
		private static var DEFAULT_OPTIONS: Object = {
			"Conjure Gems":false,
			"Place Walls":true,
			"Place Amplifiers":true,
			"Place Towers":true,
			"Place Lanterns":true,
			"Place Traps":true,
			"Place Pylons":true
		};
		
		public var options: Vector.<Object>;
		
		public function BlueprintOptions() 
		{
			this.options = new Vector.<Object>();
			for (var key: String in DEFAULT_OPTIONS)
				this.options.push({"name": key, "value": DEFAULT_OPTIONS[key]});
		}
	}

}