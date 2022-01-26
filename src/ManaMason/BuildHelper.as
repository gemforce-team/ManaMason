package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.GV;
	import com.giab.common.data.ENumber;
	import com.giab.games.gcfw.constants.GemComponentType;
	import com.giab.games.gcfw.constants.GemEnhancementId;
	import com.giab.games.gcfw.entity.Gem;
	import flash.display.Bitmap;
	import flash.errors.IllegalOperationError;
	
	public class BuildHelper 
	{
		public static var bitmaps: Object;
		
		public static const FIELD_WIDTH: Number = 60;
		public static const FIELD_HEIGHT: Number = 38;
		public static const WAVESTONE_WIDTH: Number = 50;
		public static const TOP_UI_HEIGHT: Number = 8;
		public static const TILE_SIZE: Number = 28;
		
		private static var knownGemTemplates:Object = new Object();
		public static var knownGemBitmapData:Object = new Object();
		private static var pureGemManaValues:Array = [
			[new ENumber(100), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0)],
			[new ENumber(0), new ENumber(100), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0)],
			[new ENumber(0), new ENumber(0), new ENumber(100), new ENumber(0), new ENumber(0), new ENumber(0)],
			[new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(100), new ENumber(0), new ENumber(0)],
			[new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(100), new ENumber(0)],
			[new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(0), new ENumber(100)]
		];
		
		public function BuildHelper() 
		{
			throw new IllegalOperationError("Illegal instantiation!");
		}
		
		public static function CreateGemFromTemplate(template:FakeGem): Gem
		{
			if (template == null)
				return null;
			var spec: String = template.specification;
			if (knownGemTemplates[spec])
				return knownGemTemplates[spec];
				
			var gem: Gem = null;
			gem = GV.ingameCore.creator.createGem(template.gemGrade, template.gemType, false, false);
			
			gem.targetPriority = template.targetPriority;
			
			var oldRatio:Number = gem.rangeRatio.g();
			var range4:Number = gem.sd4_IntensityMod.range.g();
			var range5:Number = gem.sd5_EnhancedOrTrapOrLantern.range.g();
			gem.rangeRatio.s(template.rangeMultiplier);
			gem.sd4_IntensityMod.range.s(range4 / oldRatio * gem.rangeRatio.g());
			gem.sd5_EnhancedOrTrapOrLantern.range.s(range5 / oldRatio * gem.rangeRatio.g());
			if(gem.enhancementType == GemEnhancementId.BEAM)
			{
				gem.sd5_EnhancedOrTrapOrLantern.range.s(Math.min(gem.sd5_EnhancedOrTrapOrLantern.range.g(),170));
			}
			
			knownGemTemplates[spec] = gem;
			GV.gemBitmapCreator.giveGemBitmaps(gem, false); //randomize actual gems the way the game does it normally
			GV.ingameCore.cnt.cntGemsInInventory.removeChild(gem.mc);
			return gem;
		}
		
		public static function CreateFakeGemFromTemplate(template:FakeGem): Gem
		{
			if (template == null)
				return null;
			var spec:String = template.specification;
			if (knownGemBitmapData[spec])
				return knownGemBitmapData[spec];
				
			var gem:Gem = new Gem();
			gem.manaValuesByComponent = pureGemManaValues[template.gemType];
			gem.grade.s(template.gemGrade);
			GV.gemBitmapCreator.giveGemBitmaps(gem, false);
			GV.ingameCore.cnt.cntGemsInInventory.removeChild(gem.mc);
			return gem;
		}
		
		public static function dupeGem(bpo: BlueprintOptions, gem: Gem): Gem
		{
			if (gem == null)
				return null;
				
			if (bpo.read(BlueprintOption.SPEND_MANA))
			{
				if (GV.ingameCore.getMana() < gem.cost.g())
					return null;
				else
				{
					GV.ingameCore.changeMana( -gem.cost.g(), false, false);
					if (bpo.read(BlueprintOption.TRACK_STATS))
						updateManaExpenditureStats(gem);
				}
			}
			var newGem: Gem =  GV.ingameSpellCaster.cloneGem(gem);
			newGem.recalculateSds();
			GV.gemBitmapCreator.giveGemBitmaps(newGem);
			GV.ingameCore.gems.push(newGem);
			
			return newGem;
		}
		
		private static function updateManaExpenditureStats(gem: Gem): void
		{
		   GV.ingameCore.stats.spentManaOnCombinationCost += gem.combinationManaValue.g();
		   GV.ingameCore.stats.spentManaOnBleedingGem += gem.manaValuesByComponent[GemComponentType.BLEEDING].g();
		   GV.ingameCore.stats.spentManaOnCritHitGem += gem.manaValuesByComponent[GemComponentType.CRITHIT].g();
		   GV.ingameCore.stats.spentManaOnPoisonGem += gem.manaValuesByComponent[GemComponentType.POISON].g();
		   GV.ingameCore.stats.spentManaOnSlowingGem += gem.manaValuesByComponent[GemComponentType.SLOWING].g();
		   GV.ingameCore.stats.spentManaOnManaLeechingGem += gem.manaValuesByComponent[GemComponentType.MANA_LEECHING].g();
		   GV.ingameCore.stats.spentManaOnArmorTearingGem += gem.manaValuesByComponent[GemComponentType.ARMOR_TEARING].g();
		}
		
		public static function cleanupOnUnload(): void
		{
			for each(var gem: Gem in knownGemTemplates)
			{
				(Bitmap)(gem.mc.getChildAt(0)).bitmapData.dispose();
			}
		}
	}

}
