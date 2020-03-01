package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import flash.display.Bitmap;
	import flash.errors.IllegalOperationError;
	
	public class BuildHelper 
	{
		public static var bitmaps: Object;
		
		public function BuildHelper() 
		{
			throw new IllegalOperationError("Illegal instantiation!");
		}
		
		public static function CreateGemFromTemplate(template:FakeGem): Object
		{
			if (template == null)
				return template;
			
			var gem:Object = null;
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			if (template.usesGemsmith)
			{
				var gs:Object = ManaMason.ManaMason.bezel.getModByName("Gemsmith");
				if (gs == null)
					return null;
				if (!core.arrIsSpellBtnVisible[template.gemType+6])
					return null;
				try{
					gem = gs.conjureGem(gs.getRecipeByName(template.gemsmithRecipeName), template.gemType, template.gemGrade);
				}
				catch (e:Error)
				{
					ManaMason.ManaMason.logger.log("CreateGemFromTemplate", "Caught error when conjuring gem! Your gemsmith is probably the wrong version, skipping gem.");
					ManaMason.ManaMason.logger.log("CreateGemFromTemplate", e.message);
					gem = null;
				}
				if (gem == null)
					return null;
			}
			else if (template.fromInventory)
			{
				gem = core.inventorySlots[template.inventorySlot];
				core.inventorySlots[template.inventorySlot] = null;
				if (gem == null)
					return null;
			}
			else
			{
				if (!core.arrIsSpellBtnVisible[template.gemType+6])
					return null;
				if (core.getMana() < core.gemCreatingBaseManaCosts[template.gemGrade])
					return null;
				
				gem = core.creator.createGem(template.gemGrade, template.gemType, true, true);
				core.changeMana( -core.gemCreatingBaseManaCosts[template.gemGrade], false, true);
			}
			
			gem.targetPriority = template.targetPriority;
			
			var oldRatio:Number = gem.rangeRatio.g();
			var range4:Number = gem.sd4_IntensityMod.range.g();
			var range5:Number = gem.sd5_EnhancedOrTrapOrLantern.range.g();
			gem.rangeRatio.s(template.rangeMultiplier);
			gem.sd4_IntensityMod.range.s(range4 / oldRatio * gem.rangeRatio.g());
			gem.sd5_EnhancedOrTrapOrLantern.range.s(range5 / oldRatio * gem.rangeRatio.g());
			if(gem.enhancementType == ManaMason.ManaMason.bezel.gameObjects.constants.gemEnhancementId.BEAM)
			{
				gem.sd5_EnhancedOrTrapOrLantern.range.s(Math.min(gem.sd5_EnhancedOrTrapOrLantern.range.g(),170));
			}
			return gem;
		}
	}

}