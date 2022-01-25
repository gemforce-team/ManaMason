package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gccs.steam.GV;
	import com.giab.games.gccs.steam.entity.Gem;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	
	public class Structure 
	{
		public var type:String;
		public var ghost:MovieClip;
		
		protected var blueprintIndexX:int;
		protected var blueprintIndexY:int;
		public function get blueprintX():Number {return this.blueprintIndexX};
		public function get blueprintY():Number {return this.blueprintIndexY};
		
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
		public var gemGhost:Bitmap;
		
		public function Structure(type:String, bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			this.type = type;
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			setBuildingCoords(50, 8);
			this.gemTemplate = gem;
			this.gem = null;
			this.ghost = new MovieClip();
		}
		
		public function fitsOnScene(): Boolean
		{
			var bX: Number = this.buildingGridX + (this.size - 1);
			var bY: Number = this.buildingGridY + (this.size - 1);
			return this.buildingGridX >= 0 && bX < BuildHelper.FIELD_WIDTH && this.buildingGridY >= 0 && bY < BuildHelper.FIELD_HEIGHT;
		}
		
		public function setBuildingCoords(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - BuildHelper.WAVESTONE_WIDTH) / BuildHelper.TILE_SIZE);
			var vY:Number = Math.floor((mouseY - BuildHelper.TOP_UI_HEIGHT) / BuildHelper.TILE_SIZE);
			
			this.buildingGridX = vX + this.blueprintIndexX;
			this.buildingGridY = vY + this.blueprintIndexY;
			
			this.buildingX = BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * this.buildingGridX + xOffset;
			this.buildingY = BuildHelper.TOP_UI_HEIGHT + BuildHelper.TILE_SIZE * this.buildingGridY + yOffset;
		}
		
		public function flipHorizontal(rowLength:int): void
		{
			this.blueprintIndexX = rowLength - 1 - this.blueprintIndexX - (this.size - 1);
		}
		
		public function flipVertical(rowCount:int): void
		{
			this.blueprintIndexY = rowCount - 1 - this.blueprintIndexY - (this.size - 1);
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
				var newGem: Gem;
				if (this.gem != null)
					newGem = BuildHelper.dupeGem(bpo, this.gem);
				else
					newGem = BuildHelper.CreateGemFromTemplate(this.gemTemplate);
				this.insertGem(newGem);
			}
		}
		
		public function toString(): String
		{
			return this.type + "(" + this.blueprintIndexX + ";" + this.blueprintIndexY + ") at " + this.buildingX + ";" + this.buildingY;
		}
		
		public function exportGemSpecToString(): String
		{
			if (this.gem == null)
				return null;
				
			var res:String = "";
			var maxComponent:Object = {"type": -1, "value": -1};
			for (var i:String in this.gem.manaValuesByComponent)
			{
				var component:Number = this.gem.manaValuesByComponent[i].g();
				if (component != 0 && component > maxComponent.value)
				{
					maxComponent.type = (Number)(i);
					maxComponent.value = component;
				}
			}
			res += [ManaMasonMod.gemTypeToName[maxComponent.type], gem.grade.g().toString(), gem.targetPriority.toString(), gem.rangeRatio.g().toString()].join(",");
			
			return res;
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

		public function fitGemGhostImage(): void
		{
			this.gemGhost.alpha = 0.6;
			this.ghost.addChildAt(this.gemGhost,0);
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
