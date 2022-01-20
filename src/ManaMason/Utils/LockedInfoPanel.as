package ManaMason.Utils 
{
	import ManaMason.BlueprintOptions;
	import ManaMason.ManaMasonMod;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.mcDyn.McInfoPanel;
	import com.giab.games.gcfw.mcDyn.McOptPanel;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Hellrage
	 */
	public class LockedInfoPanel
	{
		public var lockedWidth: Number;
		public var lockedHeight: Number;
		public var lockedPlateColor: uint;
		private var options: Object;
		
		public var basePanel: McInfoPanel;
		
		public function LockedInfoPanel(panel: McInfoPanel) 
		{
			super();
			this.basePanel = panel;
		}
		
		public function lockedReset(): void
		{
			this.basePanel.reset(lockedWidth || 280, lockedPlateColor);
			this.basePanel.isLocationLocked = true;
			this.options = new Object();
			if(lockedWidth > 0)
				this.basePanel.w = lockedWidth;
		}
		
		public function setup(width: Number, height: Number, lockedX: Number, lockedY: Number, plateColor: uint): void
		{
			this.lockedWidth = width;
			this.lockedHeight = height;
			this.basePanel.lockedX = lockedX;
			this.basePanel.lockedY = lockedY;
			this.lockedPlateColor = plateColor;
			lockedReset();
		}
		
		public function lockedDoEnterFrame(): void
		{
			if(lockedHeight > 0)
				this.basePanel.h = lockedHeight;
			this.basePanel.plateColor = uint(lockedPlateColor);
			this.basePanel.doEnterFrame();
			this.basePanel.x = this.basePanel.lockedX;
			this.basePanel.y = this.basePanel.lockedY;
			this.basePanel.mouseEnabled = false;
		}
		
		public function addOptions(options: BlueprintOptions): void
		{
			for each(var option: Object in options.options)
			{
				var newMC: McOptPanel = new McOptPanel(option.name, 0, 0, false);
				
				var onBooleanClicked:Function = function(opt: Object): Function
				{
					return function(e: MouseEvent): void
					{
						GV.vfxEngine.createFloatingText4(400, 400, "OnBooleanClicked!", 16768392, 18, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 46, 0, 13);
						var current:Boolean = opt.value;
						opt.value = !current;
						e.target.parent.btn.gotoAndStop(!current ? 2 : 1);
					};
				}(option);
				
				newMC.y = basePanel.nextTfPos;
				newMC.x = 4;
				basePanel.addExtraHeight(32);
				newMC.plate.width = basePanel.w - 8;
				newMC.plate.height = 30;
				newMC.btn.x = basePanel.w - newMC.btn.width - 8;
				newMC.btn.scaleX = 0.7;
				newMC.btn.scaleY = 0.7;
				newMC.tf.scaleY = 0.65;
				newMC.tf.scaleX = 0.65;
				newMC.tf.width = basePanel.w - newMC.btn.width * newMC.btn.scaleX - 8;
				newMC.btn.gotoAndStop(option.value ? 2 : 1);
				newMC.plate.mouseEnabled = true;
				newMC.plate.addEventListener(MouseEvent.CLICK, onBooleanClicked, true);
				newMC.plate.addEventListener(MouseEvent.CLICK, function(mE:MouseEvent):void{GV.vfxEngine.createFloatingText4(400, 400, "OnBooleanClicked!", 16768392, 18, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 46, 0, 13);},true,99999 );
				basePanel.addChild(newMC);
			}
		}
		
		public function show(): void
		{
			this.basePanel.visible = true;
			GV.main.stage.addChild(this.basePanel);
			lockedDoEnterFrame();
		}
		
		public function hide(): void
		{
			this.basePanel.visible = false;
			GV.main.stage.removeChild(this.basePanel);
		}
	}

}