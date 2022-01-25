package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.entity.Trap;
	import flash.display.Bitmap;
	
	public class TrapStruct extends Structure
	{
		public function TrapStruct(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("r", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
				
			this.buildingType = BuildingType.TRAP;
			this.spellButtonIndex = 15;
			this.xOffset = 4;
			this.yOffset = 4;
		}
		
		public override function castBuild(bpo: BlueprintOptions): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is Trap)
			{
				if (existingBuilding.insertedGem == null && bpo.read(BlueprintOption.CONJURE_GEMS))
					super.castBuild(bpo);
				return;
			}
			
			if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(bpo, true))
			{
				GV.ingameCore.creator.buildTrap(buildingGridX, buildingGridY);
			}
			else return;
			
			if (bpo.read(BlueprintOption.SPEND_MANA))
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				if (bpo.read(BlueprintOption.TRACK_STATS))
				{
					GV.ingameCore.stats.spentManaOnTraps += Math.max(0, this.getCurrentManaCost());
				}
				this.incrementManaCost();
			}
			super.castBuild(bpo);
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentTrapBuildingManaCost.s(GV.ingameCore.currentTrapBuildingManaCost.g() + Math.round(GV.TRAP_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return Math.max(0, GV.ingameCore.currentTrapBuildingManaCost.g());
		}

		public override function fitGemGhostImage(): void
		{
			if (this.gem == null)
				return;
				
			//this.gem.showInTower();
			this.gemGhost =  new Bitmap(this.gem.bmpInTower.bitmapData);
			this.gemGhost.scaleX = this.gemGhost.scaleY = 1/3;
			this.gemGhost.x = 6;
			this.gemGhost.y = 5;
			super.fitGemGhostImage();
		}

		public override function isOnPath():Boolean
		{
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.groundMatrix[buildingGridY][buildingGridX] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY+1][buildingGridX] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY][buildingGridX+1] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY+1][buildingGridX+1] == "#";
		}

		public override function placeable(bpo: BlueprintOptions, isFinalCalculation:Boolean = false):Boolean
		{
			if (!GV.ingameCore.arrIsSpellBtnVisible[this.spellButtonIndex])
				return false;
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& bpo.read(BlueprintOption.PLACE_TRAPS) && bpo.read(BlueprintOption.BUILD_ON_PATH) && GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX] == null
				&& GV.ingameCore.groundMatrix[buildingGridY][buildingGridX] == "#"
				&& GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX + 1] == null
				&& GV.ingameCore.groundMatrix[buildingGridY][buildingGridX + 1] == "#"
				&& GV.ingameCore.buildingAreaMatrix[buildingGridY + 1][buildingGridX] == null
				&& GV.ingameCore.groundMatrix[buildingGridY + 1][buildingGridX] == "#"
				&& GV.ingameCore.buildingAreaMatrix[buildingGridY + 1][buildingGridX + 1] == null
				&& GV.ingameCore.groundMatrix[buildingGridY + 1][buildingGridX + 1] == "#";
		}
	}

}
