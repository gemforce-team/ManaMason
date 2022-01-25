package ManaMason.Utils 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import com.giab.games.gccs.steam.mcDyn.McInfoPanel;
	import com.giab.games.gccs.steam.mcDyn.McOptPanel;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class LockedInfoPanel extends MovieClip
	{
		private var hasOptions:Boolean;
		private var _resizeHandler: Function;
		private static var bg: Bitmap;
		private var baseWidth: Number;
		public var titleText: TextField;
		
		public function LockedInfoPanel() 
		{
			super();
		}
		
		public function setup(width: Number, height: Number, x: Number, y: Number, plateColor: uint): void
		{
			this.removeChildren();
			
			if (bg)
			{
				bg.bitmapData.dispose();
			}
			
			var dummyInfoPanel: McInfoPanel = new McInfoPanel();
			dummyInfoPanel.reset(width, plateColor);
			dummyInfoPanel.h = height;
			dummyInfoPanel.doEnterFrame();
			var bmp: Bitmap = dummyInfoPanel.bmp;
			bmp.width = width;
			bmp.height = height;
			this.addChild(bmp);
			
			this.width = width;
			this.baseWidth = width;
			this.height = height;
			this.x = x;
			this.y = y;
			
			this.titleText = new TextField();
			
			this.hasOptions = false;
			this.mouseEnabled = this.mouseChildren = true;
		}
		
		public function addTitle(field: TextField): void
		{
			this.titleText = field;
			this.addChild(this.titleText);
		}
		
		public function addOptions(options: BlueprintOptions): void
		{
			var currY: Number = this.titleText.height + 15;
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
						e.stopImmediatePropagation();
					};
				}(option);
				
				setPanelPositionAndSize(newMC, this.baseWidth, currY);
				currY += newMC.plate.height + 2;
				
				newMC.btn.gotoAndStop(option.value ? 2 : 1);
				newMC.plate.addEventListener(MouseEvent.MOUSE_OVER, onBooleanMouseover);
				newMC.plate.addEventListener(MouseEvent.MOUSE_OUT, onBooleanMouseout);
				newMC.addEventListener(MouseEvent.MOUSE_DOWN, onBooleanClicked);
				this.addChild(newMC);
			}
		}
		
		private function setPanelPositionAndSize(oMC: McOptPanel, baseWidth: Number, startingY: Number): void
		{
			oMC.y = startingY;
			oMC.x = 4;
			oMC.plate.width = baseWidth  - 8;
			oMC.plate.height = 20;
			oMC.btn.scaleX = 0.5;
			oMC.btn.scaleY = 0.5;
			oMC.btn.x = baseWidth - 16 - oMC.btn.width;
			oMC.tf.scaleX = oMC.tf.scaleY = oMC.plate.scaleX * 2;
		}
	}
}
