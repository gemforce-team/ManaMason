package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import GemCraftFrostbornWrath_fla.MMbtnFacebookPlate_148;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.constants.GemComponentType;
	import com.giab.games.gcfw.constants.GemEnhancementId;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.GV;
	
	import flash.errors.IllegalOperationError;
	
	public class BuildHelper 
	{
		public static var bitmaps: Object;
		
		public function BuildHelper() 
		{
			throw new IllegalOperationError("Illegal instantiation!");
		}
		
		public static function CreateGemFromTemplate(template:FakeGem, bpo: BlueprintOptions): Gem
		{
			if (template == null)
				return null;
			
			var gem: Gem = null;
			if (template.usesGemsmith)
			{
				var gs:Object = ManaMasonMod.bezel.getModByName("Gemsmith");
				if (gs == null)
					return null;
				if (!GV.ingameCore.arrIsSpellBtnVisible[template.gemType+6])
					return null;
				try{
					gem = gs.conjureGem(gs.getRecipeByName(template.gemsmithRecipeName), template.gemType, template.gemGrade);
				}
				catch (e:Error)
				{
					ManaMasonMod.logger.log("CreateGemFromTemplate", "Caught error when conjuring gem! Your gemsmith is probably the wrong version, skipping gem.");
					ManaMasonMod.logger.log("CreateGemFromTemplate", e.message);
					gem = null;
				}
				if (gem == null)
					return null;
			}
			else if (template.fromInventory)
			{
				gem = GV.ingameCore.inventorySlots[template.inventorySlot];
				GV.ingameCore.inventorySlots[template.inventorySlot] = null;
				if (gem == null)
					return null;
				var index:int = GV.ingameCore.gems.indexOf(gem);
				if (index != -1)
					GV.ingameCore.gems.splice(index,1)
			}
			else
			{
				if (!GV.ingameCore.arrIsSpellBtnVisible[template.gemType+6])
					return null;
				if (bpo.read(BlueprintOption.SPEND_MANA) && GV.ingameCore.getMana() < GV.ingameCore.gemCreatingBaseManaCosts[template.gemGrade])
					return null;
					
				gem = GV.ingameCore.creator.createGem(template.gemGrade, template.gemType, true, true);
				
				if (bpo.read(BlueprintOption.SPEND_MANA))
					GV.ingameCore.changeMana( -GV.ingameCore.gemCreatingBaseManaCosts[template.gemGrade], false, true);
			}
			
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
			
			GV.ingameCore.gems.push(gem);
			return gem;
		}
		
		public static function dupeGem(bpo: BlueprintOptions, gem: Gem): Gem
		{
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
	}

}
