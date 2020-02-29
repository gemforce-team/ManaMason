package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class Tower extends Structure
	{
		public function Tower(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			var BUILDING_TYPE:Object = ManaMason.ManaMason.bezel.gameObjects.constants.buildingType;
			super("t", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
				
			this.buildingType = BUILDING_TYPE.TOWER;
			this.spellButtonIndex = 13;
		}
		
		public override function castBuild(spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			
			if (spendMana && core.getMana() < this.getCurrentManaCost())
				return;
				
			if (core.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (!core.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY))
				{
					core.creator.buildTower(buildingGridX, buildingGridY);
					if (trackStats)
					{
						core.stats.spentManaOnTowers += Math.max(0, this.getCurrentManaCost());
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
			core.currentTowerBuildingManaCost.s(core.currentTowerBuildingManaCost.g() + Math.round(GV.TOWER_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			return core.currentTowerBuildingManaCost.g();
		}
	}

}