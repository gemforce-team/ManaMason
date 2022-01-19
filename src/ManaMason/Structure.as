package ManaMason 
{
	import adobe.utils.CustomActions;
	import flash.display.Bitmap;
	import flash.utils.*;
	
	import com.giab.games.gcfw.GV;
	/**
	 * ...
	 * @author Hellrage
	 */
	
	public class Structure 
	{
		public var type:String;
		
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
		
		public function Structure(type:String, bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			this.type = type;
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			this.gemTemplate = gem;
		}
		
		public function fitsOnScene(): Boolean
		{
			return (this.buildingX <= 50 + 1680 - 28*this.size + this.xOffset) && (this.buildingX >= 50 + this.xOffset) && (this.buildingY <= 8 + 1064 - 28*this.size + this.yOffset) && (this.buildingY >= 8 + this.yOffset);
		}
		
		public function setBuildingCoords(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			this.buildingGridX = Math.max(0,Math.floor((mouseX - 50) / 28)) + this.blueprintIndexX;
			this.buildingGridY = Math.max(0, Math.floor((mouseY - 8) / 28)) + this.blueprintIndexY;
			
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
		
		public function castBuild(buidOnPath:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			this.insertGem(BuildHelper.CreateGemFromTemplate(this.gemTemplate));
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
	}

}