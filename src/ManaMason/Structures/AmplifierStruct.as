package ManaMason.Structures 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.FakeGem;
	import ManaMason.Structure;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gccs.steam.GV;
	import com.giab.games.gccs.steam.constants.BuildingType;
	import com.giab.games.gccs.steam.entity.Amplifier;
	import flash.display.Bitmap;
	
	public class AmplifierStruct extends Structure
	{
		public function AmplifierStruct(bpIX:int, bpIY:int, gem:FakeGem = null) 
		{
			super("a", bpIX, bpIY, gem);
			this.rendered = false;
			this.size = 2;
			this.xOffset = -3;
			this.yOffset = -3;
			
			this.buildingType = BuildingType.AMPLIFIER;
			this.spellButtonIndex = 11;
		}
		
		public override function castBuild(bpo: BlueprintOptions): void
		{
			var existingBuilding: Object = GV.ingameCore.buildingRegPtMatrix[buildingGridY][buildingGridX];
			
			if (existingBuilding is Amplifier)
			{
				if (existingBuilding.insertedGem == null && bpo.read(BlueprintOption.CONJURE_GEMS))
					super.castBuild(bpo);
				return;
			}
			
			if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < this.getCurrentManaCost())
				return;
				
			if (placeable(bpo, true))
			{
				GV.ingameCore.creator.buildAmplifier(buildingGridX, buildingGridY);
				if (bpo.read(BlueprintOption.TRACK_STATS))
				{
					GV.ingameCore.stats.spentManaOnAmplifiers += Math.max(0, this.getCurrentManaCost());
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
			GV.ingameCore.currentAmplifierBuildingManaCost.s(GV.ingameCore.currentAmplifierBuildingManaCost.g() + Math.round(GV.AMPLIFIER_COST_INCREMENT.g()));
		}
		
		public override function getCurrentManaCost(): Number
		{
			return Math.max(0, GV.ingameCore.currentAmplifierBuildingManaCost.g());
		}

		public override function fitGemGhostImage(): void
		{
			if (this.gem == null)
				return;
				
			//this.gem.showInAmp();
			this.gemGhost =  new Bitmap(this.gem.bmpNormal.bitmapData);
			this.gemGhost.scaleX = this.gemGhost.scaleY = 1/2.3;
			this.gemGhost.x = 7;
			this.gemGhost.y = 8;
			super.fitGemGhostImage();
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
			if (!GV.ingameCore.arrIsSpellBtnVisible[this.spellButtonIndex])
				return false;
			if (!bpo.read(BlueprintOption.BUILD_ON_PATH) && isOnPath())
				return false;
			if (!fitsOnScene())
				return false;
			return bpo.read(BlueprintOption.PLACE_AMPLIFIERS) && GV.ingameCore.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType)
				&& (!finalCalculation || !GV.ingameCore.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY));
		}
	}

}