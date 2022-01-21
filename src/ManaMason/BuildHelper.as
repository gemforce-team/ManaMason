package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Utils.BlueprintOption;
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
		
		public static function CreateGemFromTemplate(template:FakeGem, bpo: BlueprintOptions): Object
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
	}

}
