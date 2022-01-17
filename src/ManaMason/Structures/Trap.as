package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BuildHelper;
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class Trap extends Structure
	{
		public function Trap(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			var BUILDING_TYPE:Object = ManaMason.ManaMason.bezel.gameObjects.constants.buildingType;
			super("r", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
				
			this.buildingType = BUILDING_TYPE.TRAP;
			this.spellButtonIndex = 15;
			this.xOffset = 4;
			this.yOffset = 4;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			
			if (spendMana && core.getMana() < this.getCurrentManaCost())
				return;
				
			if (!buildOnPath && (
				core.groundMatrix[buildingGridY][buildingGridX] == "#" ||
				core.groundMatrix[buildingGridY+1][buildingGridX] == "#" ||
				core.groundMatrix[buildingGridY][buildingGridX+1] == "#" ||
				core.groundMatrix[buildingGridY+1][buildingGridX+1] == "#"))
				return;
				
			if (core.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (core.buildingAreaMatrix[buildingGridY][buildingGridX] == null
						&& core.groundMatrix[buildingGridY][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY][buildingGridX + 1] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX + 1] == "#")
					{
						core.creator.buildTrap(buildingGridX, buildingGridY);
						if (trackStats)
						{
							core.stats.spentManaOnTraps += Math.max(0, this.getCurrentManaCost());
						}
				}
				else return;
			}
			else return;
			
			if (spendMana)
			{
				core.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
			super.castBuild(spendMana, trackStats);
		}
	
		public override function incrementManaCost(): void
		{
			var GV:Object = ManaMason.ManaMason.bezel.gameObjects.GV;
			var core:Object = GV.ingameCore;
			core.currentTrapBuildingManaCost.s(core.currentTrapBuildingManaCost.g() + Math.round(GV.TRAP_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			return core.currentTrapBuildingManaCost.g();
		}
	}

}