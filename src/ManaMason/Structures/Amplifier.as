package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	
	public class Amplifier extends Structure
	{
		public function Amplifier(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			var BUILDING_TYPE:Object = ManaMason.ManaMason.bezel.gameObjects.constants.buildingType;
			super("a", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
			
			this.buildingType = BUILDING_TYPE.AMPLIFIER;
			this.spellButtonIndex = 14;
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
				if (!core.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY))
				{
					core.creator.buildAmplifier(buildingGridX, buildingGridY);
					if (trackStats)
					{
						core.stats.spentManaOnAmplifiers += Math.max(0, this.getCurrentManaCost());
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
			core.currentAmplifierBuildingManaCost.s(core.currentAmplifierBuildingManaCost.g() + Math.round(GV.AMPLIFIER_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			return core.currentAmplifierBuildingManaCost.g();
		}
	}

}