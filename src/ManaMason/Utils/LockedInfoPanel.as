package ManaMason.Utils 
{
	import ManaMason.BlueprintOptions;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.mcDyn.McInfoPanel;
	import com.giab.games.gcfw.mcDyn.McOptPanel;
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
			this.hasOptions = false;
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
			for each(var option:Object in options.options)
			{
				var newMC: McOptPanel = new McOptPanel(option.name, 0, 0, false);

				var onBooleanMouseover:Function = function(e:MouseEvent):void
				{
					e.target.parent.plate.gotoAndStop(2);
				};
				var onBooleanMouseout:Function = function(e:MouseEvent):void
				{
					e.target.parent.plate.gotoAndStop(1);
				};
				var onBooleanClicked:Function = function(opt: Object): Function
				{
					return function(e: MouseEvent): void
					{
						var current:Boolean = opt.value;
						opt.value = !current;
						e.target.parent.btn.gotoAndStop(!current ? 2 : 1);
					};
				}(option);
				
				newMC.y = basePanel.nextTfPos;
				newMC.x = 4;
				basePanel.addExtraHeight(32);
				newMC.plate.width = basePanel.w - 32;
				newMC.plate.height = 30;
				newMC.btn.scaleX = 0.7;
				newMC.btn.scaleY = 0.7;
				newMC.btn.x = newMC.plate.width - newMC.btn.width - 8;
				newMC.tf.scaleY = 0.65;
				newMC.tf.scaleX = 0.65;
				newMC.tf.width = basePanel.w - newMC.btn.width * newMC.btn.scaleX - 8;
				newMC.btn.gotoAndStop(option.value ? 2 : 1);
				newMC.addEventListener(MouseEvent.MOUSE_OVER, onBooleanMouseover);
				newMC.addEventListener(MouseEvent.MOUSE_OUT, onBooleanMouseout);
				newMC.addEventListener(MouseEvent.MOUSE_DOWN, onBooleanClicked, false);
				basePanel.addChild(newMC);
			}
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
