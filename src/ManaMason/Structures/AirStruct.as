package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.Structure;
	import flash.display.MovieClip;
	
	public class AirStruct extends Structure
	{
		private static var airGhost:MovieClip = new MovieClip();
		
		public function AirStruct(bpIX:int, bpIY:int) 
		{
			super("-", bpIX, bpIY);
			this.rendered = true;
			this.size = 1;
			xOffset = 0;
			yOffset = 0;
			
			this.buildingType = "AIR";
			this.spellButtonIndex = -1;
			
			this.ghost = airGhost;
		}
		
		public override function castBuild(options: BlueprintOptions):void 
		{
			return;
		}
	}
}