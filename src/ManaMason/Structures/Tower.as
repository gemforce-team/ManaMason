package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.GV;
	
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class Tower extends Structure
	{
		public function Tower(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("t", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
				
			this.buildingType = BuildingType.TOWER;
			this.spellButtonIndex = 13;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, insertGems:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is ManaMason.GCFWManaMason.structureClasses['t'])
			{
				if (existingBuilding.insertedGem == null)
					super.castBuild(buildOnPath, insertGems, spendMana, trackStats);
				return;
			}
			
			if (spendMana && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(buildOnPath, true))
			{
				GV.ingameCore.creator.buildTower(buildingGridX, buildingGridY);
				if (trackStats)
				{
					GV.ingameCore.stats.spentManaOnTowers += Math.max(0, this.getCurrentManaCost());
				}
			}
			else return;
			
			if (spendMana)
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
			super.castBuild(buildOnPath, insertGems, spendMana, trackStats);
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentTowerBuildingManaCost.s(GV.ingameCore.currentTowerBuildingManaCost.g() + Math.round(GV.TOWER_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return GV.ingameCore.currentTowerBuildingManaCost.g();
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

		public override function placeable(pathAllowed:Boolean, finalCalculation:Boolean = false):Boolean
		{
			if (!pathAllowed && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!finalCalculation || !GV.ingameCore.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY));
		}
	}

}
