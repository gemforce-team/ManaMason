package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.GV;
	
	import ManaMason.GCFWManaMason;
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class Trap extends Structure
	{
		public function Trap(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("r", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
				
			this.buildingType = BuildingType.TRAP;
			this.spellButtonIndex = 15;
			this.xOffset = 4;
			this.yOffset = 4;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, insertGems:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is ManaMason.GCFWManaMason.structureClasses['r'])
			{
				if (existingBuilding.insertedGem == null)
					super.castBuild(buildOnPath, insertGems, spendMana, trackStats);
				return;
			}
			
			if (spendMana && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(buildOnPath, true))
			{
				GV.ingameCore.creator.buildTrap(buildingGridX, buildingGridY);
				if (trackStats)
				{
					GV.ingameCore.stats.spentManaOnTraps += Math.max(0, this.getCurrentManaCost());
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
			GV.ingameCore.currentTrapBuildingManaCost.s(GV.ingameCore.currentTrapBuildingManaCost.g() + Math.round(GV.TRAP_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return GV.ingameCore.currentTrapBuildingManaCost.g();
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

		public override function placeable(pathAllowed:Boolean, isFinalCalculation:Boolean = false):Boolean
		{
			if (!fitsOnScene())
				return false;
			return GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& pathAllowed && GV.ingameCore.buildingAreaMatrix[buildingGridY][buildingGridX] == null
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
