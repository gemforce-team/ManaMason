package ManaMason 
{
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Gem;
	import flash.display.MovieClip;
	/**
	 * ...
	 * @author Hellrage
	 */
	
	public class Structure 
	{
		public var type:String;
		public var ghost:Object;
		
		protected var blueprintIndexX:int;
		protected var blueprintIndexY:int;
		
		public var buildingGridX:int;
		public var buildingGridY:int;
		
		public var buildingX:Number;
		public var buildingY:Number;
		
		public var rendered:Boolean;
		public var size:int;
		
		protected var xOffset:int;
		protected var yOffset:int;
		
		public var buildingType:String;
		public var spellButtonIndex:int;
		
		public var gemTemplate:FakeGem;
		public var gem: Gem;
		
		public function Structure(type:String, bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			this.type = type;
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			setBuildingCoords(50, 8);
			this.gemTemplate = gem;
		}
		
		public function fitsOnScene(): Boolean
		{
			var bX: Number = this.buildingGridX + (this.size - 1);
			var bY: Number = this.buildingGridY + (this.size - 1);
			return this.buildingGridX >= 0 && bX < 60 && this.buildingGridY >= 0 && bY < 38;
		}
		
		public function setBuildingCoords(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			this.buildingGridX = vX + this.blueprintIndexX;
			this.buildingGridY = vY + this.blueprintIndexY;
			
			this.buildingX = 50 + 28 * this.buildingGridX + xOffset;
			this.buildingY = 8 + 28 * this.buildingGridY + yOffset;
		}
		
		public function flipHorizontal(rowLength:int): void
		{
			this.blueprintIndexX = rowLength - 1 - this.blueprintIndexX - (this.size - 1);
		}
		
		public function flipVertical(rowCount:int): void
		{
			this.blueprintIndexY = rowCount - 1 - this.blueprintIndexY - (this.size -1);
		}
		
		public function transpose(): void
		{
			var temp:int = this.blueprintIndexX;
			this.blueprintIndexX = this.blueprintIndexY;
			this.blueprintIndexY = temp;
		}
		
		public function castBuild(bpo: BlueprintOptions): void
		{
			if (bpo.read(BlueprintOption.CONJURE_GEMS))
			{
				this.insertGem(BuildHelper.CreateGemFromTemplate(this.gemTemplate, bpo));
			}
		}
		
		public function toString(): String
		{
			return this.type + "(" + this.blueprintIndexX + ";" + this.blueprintIndexY + ") at " + this.buildingX + ";" + this.buildingY;
		}
		
		public function incrementManaCost(): void
		{
			
		}
		
		public function getCurrentManaCost(): Number
		{
			return 0;
		}
		
		public function insertGem(gem:Object): void
		{
			if (gem == null)
				return;
			GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX].insertGem(gem);
		}

		public function isOnPath(): Boolean
		{
			return false;
		}

		public function placeable(bpo: BlueprintOptions, isFinalCalculation:Boolean = false):Boolean
		{
			return true;
		}
	}

}
