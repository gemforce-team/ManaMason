package ManaMason.Utils 
{
	import ManaMason.BlueprintOptions;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.mcDyn.McInfoPanel;
	import com.giab.games.gcfw.mcDyn.McOptPanel;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	/**
	 * ...
	 * @author Hellrage
	 */
	public class LockedInfoPanel
	{
		public var lockedWidth: Number;
		public var lockedHeight: Number;
		public var lockedPlateColor: uint;
		private var hasOptions:Boolean;
		private var _resizeHandler: Function;
		public function get resizeHandler(): Function {return _resizeHandler};
		
		public var basePanel: McInfoPanel;
		
		public function LockedInfoPanel(panel: McInfoPanel) 
		{
			super();
			this.basePanel = panel;
			this._resizeHandler = resizeOptionPanelsHandler();
		}
		
		public function setup(width: Number, height: Number, lockedX: Number, lockedY: Number, plateColor: uint): void
		{
			this.lockedWidth = width;
			this.lockedHeight = height;
			this.basePanel.lockedX = lockedX;
			this.basePanel.lockedY = lockedY;
			this.lockedPlateColor = plateColor;
			this.basePanel.reset(lockedWidth, lockedPlateColor);
			this.basePanel.isLocationLocked = true;
			this.hasOptions = false;
			this.basePanel.w = lockedWidth;
		}
		
		public function lockedDoEnterFrame(... args): void
		{
			if(lockedHeight > 0)
				this.basePanel.h = lockedHeight;
			this.basePanel.plateColor = uint(lockedPlateColor);
			this.basePanel.doEnterFrame();
			this.basePanel.x = this.basePanel.lockedX;
			this.basePanel.y = this.basePanel.lockedY;
		}
		
		public function addOptions(options: BlueprintOptions): void
		{
			if (options.options.length != 0)
			{
				this.hasOptions = true;
			}
			for each(var option:BlueprintOption in options.options)
			{
				if (!option.visible)
					continue;
				var newMC: McOptPanel = new McOptPanel(option.name, 0, 0, false);

				var onBooleanMouseover:Function = function(e:MouseEvent):void
				{
					e.target.gotoAndStop(2);
				};
				var onBooleanMouseout:Function = function(e:MouseEvent):void
				{
					e.target.gotoAndStop(1);
				};
				var onBooleanClicked:Function = function(opt: Object): Function
				{
					return function(e: MouseEvent): void
					{
						var current:Boolean = opt.value;
						opt.value = !current;
						e.target.parent.btn.gotoAndStop(opt.value ? 2 : 1);
					};
				}(option);
				
				setPanelPositionAndSize(newMC, lockedWidth, basePanel.nextTfPos, scaleFactor());
				basePanel.addExtraHeight(newMC.plate.height + 2);
				
				newMC.btn.gotoAndStop(option.value ? 2 : 1);
				newMC.plate.addEventListener(MouseEvent.MOUSE_OVER, onBooleanMouseover);
				newMC.plate.addEventListener(MouseEvent.MOUSE_OUT, onBooleanMouseout);
				newMC.addEventListener(MouseEvent.MOUSE_DOWN, onBooleanClicked);
				basePanel.addChild(newMC);
			}
		}
		
		private function resizeOptionPanelsHandler(): Function
		{
			var self: LockedInfoPanel = this;
			return function(e:Event): void {
				if (hasOptions)
				{
					var stageHeight: Number = GV.main.stage.stageHeight;
					var stageWidth: Number = GV.main.stage.stageWidth;
					for (var i:uint = 0; i < self.basePanel.numChildren; i++)
					{
						var option: McOptPanel = self.basePanel.getChildAt(i) as McOptPanel;
						if(option != null)
							setPanelPositionAndSize(option, self.lockedWidth, i * 30 + 10, scaleFactor());
					}
				}
			}
		}
		
		private function scaleFactor(): Number
		{
			var stageH: Number = GV.main.stage.stageHeight;
			var stageW: Number = GV.main.stage.stageWidth;
			
			var scaleH: Number = stageH / 1080;
			var scaleW: Number = stageW / 1920;
			return Math.min(scaleH, scaleW);
		}
		
		private function setPanelPositionAndSize(oMC: McOptPanel, baseWidth: Number, startingY: Number, scaleFactor: Number): void
		{
			oMC.y = startingY;
			oMC.x = 4;
			oMC.plate.width = baseWidth * scaleFactor  - 8;
			oMC.plate.height = 30 * scaleFactor;
			oMC.btn.scaleX = 0.7 * scaleFactor;
			oMC.btn.scaleY = 0.7 * scaleFactor;
			oMC.btn.x = baseWidth * scaleFactor - 16 - oMC.btn.width;
			oMC.tf.scaleX = oMC.tf.scaleY = oMC.plate.scaleX * 1.3;
			
		}
		
		public function show(): void
		{
			this.basePanel.visible = true;
			var children:Vector.<DisplayObject> = new <DisplayObject>[];
			if (this.hasOptions)
			{
				for (var i:uint = 0; i < this.basePanel.numChildren; i++)
				{
					children.push(this.basePanel.getChildAt(i));
				}
				this.basePanel.removeChildren();
			}
			lockedDoEnterFrame();
			if (this.hasOptions)
			{
				for (i = 0; i < children.length; i++)
				{
					this.basePanel.addChild(children[i]);
				}
			}
			GV.ingameCore.cnt.addChild(this.basePanel);
		}
		
		public function hide(): void
		{
			this.basePanel.visible = false;
			GV.ingameCore.cnt.removeChild(this.basePanel);
		}
	}

}
