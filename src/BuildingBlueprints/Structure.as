package BuildingBlueprints 
{
	import adobe.utils.CustomActions;
	import flash.display.Bitmap;
	/**
	 * ...
	 * @author Hellrage
	 */
	
	
	
	public class Structure 
	{
		public var type:String;
		private var blueprintIndexX:int;
		private var blueprintIndexY:int;
		public var processed:Boolean;
		public var buildingX:Number;
		public var buildingY:Number;
		public var size:Object;
		
		public function Structure(type:String, bpIX:int, bpIY:int) 
		{
			this.type = type;
			if (this.type == "w")
			{
				this.size = {"width":1, "height": 1};
			}
			else
			{
				this.size = {"width":2, "height": 2};
			}
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			this.processed = (type == "air");
		}
		
		public function fitsOnScene(mouseX:Number, mouseY:Number): Boolean
		{
			
			return true;
		}
		
		public function setBuildingCoords(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			var vXBuildingPlacement: Number = Math.max(0,Math.floor((mouseX - 50 - 8) / 28));
			var vYBuildingPlacement: Number = Math.max(0, Math.floor((mouseY - 8 - 8) / 28));
			this.buildingX = 50 + 28 * (vXBuildingPlacement + this.blueprintIndexX) - ((this.type == "w") ? 0 : 4);
			this.buildingY = 8 + 28 * (vYBuildingPlacement + this.blueprintIndexY) - ((this.type == "w") ? 0 : 5);
		}
		
		public function toString(): String
		{
			return this.type + "(" + this.blueprintIndexX+";"+this.blueprintIndexY+ ") at " + this.buildingX + ";" + this.buildingY;
		}
	}

}