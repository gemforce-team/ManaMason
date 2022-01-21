package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.Structure;
	
	public class Air extends Structure
	{
		public function Air(bpIX:int, bpIY:int) 
		{
			super("-", bpIX, bpIY);
			this.rendered = true;
			this.size = 1;
			xOffset = 0;
			yOffset = 0;
			
			this.buildingType = "AIR";
			this.spellButtonIndex = -1;
		}
		
		public override function castBuild(options: BlueprintOptions):void 
		{
			return;
		}
	}
}