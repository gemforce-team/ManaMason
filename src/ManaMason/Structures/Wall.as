package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Structure;
	import flash.utils.getDefinitionByName;
	
	public class Wall extends Structure
	{
		public function Wall(bpIX:int, bpIY:int) 
		{
			var BUILDING_TYPE:Object = ManaMason.ManaMason.bezel.gameObjects.constants.buildingType;
			super("w", bpIX, bpIY);
			this.rendered = false;
			this.size = 1;
			this.buildingType = BUILDING_TYPE.WALL;
			this.spellButtonIndex = 12;
			this.xOffset = 0;
			this.yOffset = 0;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			
			if (spendMana && core.getMana() < this.getCurrentManaCost())
				return;
				
			if (!buildOnPath && core.groundMatrix[buildingGridY][buildingGridX] == "#")
				return;
				
			if (core.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (this.type == "w")
				{
					if (core.calculator.isNewWallBlocking(buildingGridX, buildingGridX, buildingGridY, buildingGridY))// (this.buildingX, this.buildingX, this.buildingY, this.buildingY))
						return;
					if(!(core.buildingAreaMatrix[buildingGridY][buildingGridX] is (getDefinitionByName('com.giab.games.gcfw.entity.Wall') as Class)))
					{
						core.creator.buildWall(buildingGridX, buildingGridY);
						core.stats.spentManaOnWalls += Math.max(0, this.getCurrentManaCost());
					}
					else return;
				}
			}
			else return;
			
			if (spendMana)
			{
				core.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
		}
	
		public override function incrementManaCost(): void
		{
			var GV:Object = ManaMason.ManaMason.bezel.gameObjects.GV;
			var core:Object = GV.ingameCore;
			
			core.currentWallBuildingManaCost.s(core.currentWallBuildingManaCost.g() + Math.round(GV.WALL_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			return core.currentWallBuildingManaCost.g();
		}
		
		public override function insertGem(gem:Object): void
		{
			
		}
	}

}