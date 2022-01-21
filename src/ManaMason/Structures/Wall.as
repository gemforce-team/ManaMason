package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.GV;
	 
	import ManaMason.GCFWManaMason;
	import ManaMason.Structure;
	
	public class Wall extends Structure
	{
		public function Wall(bpIX:int, bpIY:int) 
		{
			super("w", bpIX, bpIY);
			this.rendered = false;
			this.size = 1;
			this.buildingType = BuildingType.WALL;
			this.spellButtonIndex = 12;
			this.xOffset = 0;
			this.yOffset = 0;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, insertGems:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			if (spendMana && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(buildOnPath, true))
			{
				if (this.type == "w")
				{
					if(!(GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX] is ManaMason.GCFWManaMason.structureClasses['w']))
					{
						GV.ingameCore.creator.buildWall(buildingGridX, buildingGridY);
						GV.ingameCore.stats.spentManaOnWalls += Math.max(0, this.getCurrentManaCost());
					}
					else return;
				}
			}
			else return;
			
			if (spendMana)
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentWallBuildingManaCost.s(GV.ingameCore.currentWallBuildingManaCost.g() + Math.round(GV.WALL_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return GV.ingameCore.currentWallBuildingManaCost.g();
		}
		
		public override function insertGem(gem:Object): void
		{
			
		}

		public override function isOnPath():Boolean
		{
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.groundMatrix[buildingGridY][buildingGridX] == "#";
		}

		public override function placeable(pathAllowed:Boolean, isFinalCalculation:Boolean = false):Boolean
		{
			if (!pathAllowed && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!isFinalCalculation || !GV.ingameCore.calculator.isNewWallBlocking(buildingGridX, buildingGridX, buildingGridY, buildingGridY));
		}
	}

}
