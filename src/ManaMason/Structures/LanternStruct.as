package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Lantern;
	
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class LanternStruct extends Structure
	{
		public function LanternStruct(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("l", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
			
			this.buildingType = BuildingType.LANTERN;
			this.spellButtonIndex = 16;
		}
		
		public override function castBuild(bpo: BlueprintOptions): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is Lantern)
			{
				if (existingBuilding.insertedGem == null && bpo.read(BlueprintOption.CONJURE_GEMS))
					super.castBuild(bpo);
				return;
			}
			
			if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(bpo, true))
			{
				GV.ingameCore.creator.buildLantern(buildingGridX, buildingGridY);
				if (bpo.read(BlueprintOption.TRACK_STATS))
				{
					GV.ingameCore.stats.spentManaOnLanterns += Math.max(0, this.getCurrentManaCost());
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
			GV.ingameCore.currentLanternBuildingManaCost.s(GV.ingameCore.currentLanternBuildingManaCost.g() + Math.round(GV.LANTERN_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return GV.ingameCore.currentLanternBuildingManaCost.g();
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
			if (!bpo.read(BlueprintOption.BUILD_ON_PATH) && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return bpo.read(BlueprintOption.PLACE_LANTERNS) && GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!finalCalculation || !GV.ingameCore.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY));
		}
	}

}
