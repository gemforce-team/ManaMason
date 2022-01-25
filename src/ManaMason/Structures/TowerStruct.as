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
	import com.giab.games.gcfw.entity.Tower;
	import flash.display.Bitmap;
	
	public class TowerStruct extends Structure
	{
		public function TowerStruct(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("t", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
				
			this.buildingType = BuildingType.TOWER;
			this.spellButtonIndex = 13;
		}
		
		public override function castBuild(bpo: BlueprintOptions): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is Tower)
			{
				if (existingBuilding.insertedGem == null && bpo.read(BlueprintOption.CONJURE_GEMS))
					super.castBuild(bpo);
				return;
			}
			
			if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(bpo, true))
			{
				GV.ingameCore.creator.buildTower(buildingGridX, buildingGridY);
				if (bpo.read(BlueprintOption.TRACK_STATS))
				{
					GV.ingameCore.stats.spentManaOnTowers += Math.max(0, this.getCurrentManaCost());
				}
			}
			else return;
			
			if (bpo.read(BlueprintOption.SPEND_MANA))
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
			super.castBuild(bpo);
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentTowerBuildingManaCost.s(GV.ingameCore.currentTowerBuildingManaCost.g() + Math.round(GV.TOWER_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return Math.max(0, GV.ingameCore.currentTowerBuildingManaCost.g());
		}

		public override function fitGemGhostImage(): void
		{
			if (this.gem == null)
				return;
				
			//this.gem.showInTower();
			this.gemGhost =  new Bitmap(this.gem.bmpInTower.bitmapData);
			this.gemGhost.scaleX = this.gemGhost.scaleY = 1/3;
			this.gemGhost.x = 14;
			this.gemGhost.y = 14;
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

		public override function placeable(bpo: BlueprintOptions, finalCalculation:Boolean = false):Boolean
		{
			if (!GV.ingameCore.arrIsSpellBtnVisible[this.spellButtonIndex])
				return false;
			if (!bpo.read(BlueprintOption.BUILD_ON_PATH) && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return bpo.read(BlueprintOption.PLACE_TOWERS) && GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!finalCalculation || !GV.ingameCore.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY));
		}
	}

}
