package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.Structure;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gccs.steam.GV;
	import com.giab.games.gccs.steam.constants.BuildingType;
	import com.giab.games.gccs.steam.entity.Wall;
	
	public class WallStruct extends Structure
	{
		public function WallStruct(bpIX:int, bpIY:int) 
		{
			super("w", bpIX, bpIY);
			this.rendered = false;
			this.size = 1;
			this.buildingType = BuildingType.WALL;
			this.spellButtonIndex = 9;
			this.xOffset = 0;
			this.yOffset = 0;
		}
		
		public override function castBuild(bpo: BlueprintOptions): void
		{
			if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(bpo, true))
			{
				if(!(GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX] is Wall))
				{
					GV.ingameCore.creator.buildWall(buildingGridX, buildingGridY);
				}
				else return;
			}
			else return;
			
			if (bpo.read(BlueprintOption.SPEND_MANA))
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				if (bpo.read(BlueprintOption.TRACK_STATS))
				{
					GV.ingameCore.stats.spentManaOnWalls += Math.max(0, this.getCurrentManaCost());
				}
				this.incrementManaCost();
			}
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentWallBuildingManaCost.s(GV.ingameCore.currentWallBuildingManaCost.g() + Math.round(GV.WALL_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return Math.max(0, GV.ingameCore.currentWallBuildingManaCost.g());
		}
		
		public override function insertGem(bpo:BlueprintOptions): void
		{
			
		}

		public override function isOnPath():Boolean
		{
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.groundMatrix[buildingGridY][buildingGridX] == "#";
		}

		public override function placeable(bpo: BlueprintOptions, isFinalCalculation:Boolean = false):Boolean
		{
			if (!GV.ingameCore.arrIsSpellBtnVisible[this.spellButtonIndex])
				return false;
			if (!bpo.read(BlueprintOption.BUILD_ON_PATH) && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return bpo.read(BlueprintOption.PLACE_WALLS) && GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!isFinalCalculation || !GV.ingameCore.calculator.isNewWallBlocking(buildingGridX, buildingGridX, buildingGridY, buildingGridY));
		}
	}

}
