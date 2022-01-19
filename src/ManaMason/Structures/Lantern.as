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
	
	public class Lantern extends Structure
	{
		public function Lantern(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("l", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -4;
			this.yOffset = -5;
			
			this.buildingType = BuildingType.LANTERN;
			this.spellButtonIndex = 16;
		}
		
		public override function castBuild(buildOnPath:Boolean = true, spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is ManaMason.GCFWManaMason.structureClasses['l'])
			{
				if (existingBuilding.insertedGem == null)
					super.castBuild(spendMana, trackStats);
				return;
			}
			
			if (spendMana && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (!buildOnPath && (
				GV.ingameCore.groundMatrix[buildingGridY][buildingGridX] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY+1][buildingGridX] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY][buildingGridX+1] == "#" ||
				GV.ingameCore.groundMatrix[buildingGridY+1][buildingGridX+1] == "#"))
				return;
				
			if (GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (!GV.ingameCore.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY))
				{
					GV.ingameCore.creator.buildLantern(buildingGridX, buildingGridY);
					if (trackStats)
					{
						GV.ingameCore.stats.spentManaOnLanterns += Math.max(0, this.getCurrentManaCost());
					}	
				}
				else return;
			}
			else return;
			
			if (spendMana)
			{
				GV.ingameCore.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
			super.castBuild(spendMana, trackStats);
		}
	
		public override function incrementManaCost(): void
		{
			GV.ingameCore.currentLanternBuildingManaCost.s(GV.ingameCore.currentLanternBuildingManaCost.g() + Math.round(GV.LANTERN_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return GV.ingameCore.currentLanternBuildingManaCost.g();
		}
	}

}