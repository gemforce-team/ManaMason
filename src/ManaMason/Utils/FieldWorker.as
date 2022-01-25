package ManaMason.Utils 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Blueprint;
	import ManaMason.BuildHelper;
	import ManaMason.ManaMasonMod;
	import com.giab.common.abstract.SpriteExt;
	import com.giab.games.gccs.steam.GV;
	import flash.display.Shape;
	import flash.events.Event;
	
	public class FieldWorker
	{
		public var mode:int;
		public function get busy():Boolean { return mode > 0 ; }
		private var selectedCorners: Object;
		public var crosshair:Shape;
		private var onDone:Function;
		
		public function FieldWorker()
		{
			this.mode = FieldWorkerMode.NONE;
			this.selectedCorners = new Object();
			this.crosshair = new Shape();
			selectedCorners[0] = null;
			selectedCorners[1] = null;
			this.onDone = null;
		}
		
		public function fieldClicked(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - BuildHelper.WAVESTONE_WIDTH) / BuildHelper.TILE_SIZE);
			var vY:Number = Math.floor((mouseY - BuildHelper.TOP_UI_HEIGHT) / BuildHelper.TILE_SIZE);
			
			if (this.selectedCorners[0] == null)
			{
				this.selectedCorners[0] = [vX, vY];
				drawSelectionOverlay();
			}
			else if (this.selectedCorners[1] == null)
			{
				var cx: Number = this.selectedCorners[0][0];
				var cy: Number = this.selectedCorners[0][1];
				if (vX -cx <= 0 && vY - cy <= 0)
				{
					this.selectedCorners[0] = [vX, vY];
					this.selectedCorners[1] = [cx, cy];
				}
				else if(vX -cx >= 0 && vY - cy >= 0)
				{
					this.selectedCorners[1] = [vX, vY];
					this.selectedCorners[0] = [cx, cy];
				}
				else
				{
					cx = vX;
					vX = this.selectedCorners[0][0];
					if (vX -cx <= 0 && vY - cy <= 0)
					{
						this.selectedCorners[0] = [vX, vY];
						this.selectedCorners[1] = [cx, cy];
					}
					else if(vX -cx >= 0 && vY - cy >= 0)
					{
						this.selectedCorners[1] = [vX, vY];
						this.selectedCorners[0] = [cx, cy];
					}
					else
					{
						abort();
						return;
					}
				}
				doWork();
			}
		}
		
		public function setMode(mode:int, callback:Function): void
		{
			if (this.mode != FieldWorkerMode.NONE)
				abort();
				
			this.mode = mode;
			this.onDone = callback;
			this.crosshair.graphics.lineStyle(2, FieldWorkerMode.colors[this.mode]);
		}
		
		private function drawSelectionOverlay(): void
		{
			var mX: Number = GV.main.mouseX;
			var mY: Number = GV.main.mouseY;
			
			if (mX > BuildHelper.WAVESTONE_WIDTH &&
				mX < BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH &&
				mY > BuildHelper.TOP_UI_HEIGHT &&
				mY < BuildHelper.TOP_UI_HEIGHT + BuildHelper.TILE_SIZE*BuildHelper.FIELD_HEIGHT)
			{
				var rHUD: SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
				/*if(rHUD.getChildIndex(crosshair) >=0 )
					rHUD.removeChild(crosshair);*/
				crosshair.graphics.lineStyle(2, FieldWorkerMode.colors[this.mode]);
				if (this.selectedCorners[0] == null) {
					crosshair.graphics.moveTo(BuildHelper.WAVESTONE_WIDTH, mY);
					crosshair.graphics.lineTo(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH+BuildHelper.WAVESTONE_WIDTH, mY);
					crosshair.graphics.moveTo(mX, BuildHelper.TOP_UI_HEIGHT);
					crosshair.graphics.lineTo(mX, BuildHelper.TILE_SIZE * BuildHelper.FIELD_HEIGHT+BuildHelper.TOP_UI_HEIGHT);
				}
				else if (this.selectedCorners[1] == null)
				{
					crosshair.graphics.moveTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][0]), BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][1]));
					crosshair.graphics.lineTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][0]), mY);
					crosshair.graphics.lineTo(mX, mY);
					crosshair.graphics.lineTo(mX, BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][1]));
					crosshair.graphics.lineTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][0]), BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.selectedCorners[0][1]));
				}
			}
		}
		
		public function frameUpdate(e: Event): void
		{
			crosshair.graphics.clear();
			if (this.mode != FieldWorkerMode.NONE)
			{
				drawSelectionOverlay();
			}
		}
		
		private function getSocketedStructuresInArea(captureCorners: Object): Array
		{
			var res: Array = new Array();
			
			var grid:Object = GV.ingameCore.buildingAreaMatrix;
			var regGrid:Object = GV.ingameCore.buildingRegPtMatrix;
			for (var i:int = captureCorners[0][1]; i <= captureCorners[1][1]; i++) 
			{
				for (var j:int = captureCorners[0][0]; j <= captureCorners[1][0]; j++) 
				{
					for (var type:String in ManaMasonMod.structureClasses)
					{
						if (grid[i][j] is ManaMasonMod.structureClasses[type] && regGrid[i][j] == grid[i][j])
						{
							if (grid[i][j].hasOwnProperty("insertedGem") && grid[i][j].insertedGem != null)
							{
								res.push(grid[i][j]);
							}
						}
					}
				}
			}
			
			return res;
		}
		
		private function doWork(): void
		{
			if (this.mode == FieldWorkerMode.CAPTURE)
			{
				onDone(Blueprint.tryCaptureFromField(this.selectedCorners));
			}
			else if (this.mode == FieldWorkerMode.REFUND)
			{
				refundGemsInStructures(getSocketedStructuresInArea(this.selectedCorners));
				onDone();
			}
			else if (this.mode == FieldWorkerMode.UPGRADE)
			{
				upgradeGemsInStructures(getSocketedStructuresInArea(this.selectedCorners));
				onDone();
			}
			
			abort();
		}
		
		private function refundGemsInStructures(structures: Array): void
		{
			for each (var struct: Object in structures) 
			{
				GV.ingameCore.spellCaster.castRefundGem(struct.insertedGem);
			}
		}
		
		private function upgradeGemsInStructures(structures: Array): void
		{
			for each (var struct: Object in structures) 
			{
				if (GV.ingameCore.getMana() >= (struct.insertedGem.cost.g() + GV.ingameCore.gemCombiningManaCost.g()))
				{
					GV.ingameCore.changeMana( -struct.insertedGem.cost.g(), false, true);
					GV.ingameCore.spellCaster.castCombineGemsFromBuildingToBuilding(struct, struct);
				}
			}
		}
		
		public function abort():void 
		{
			this.selectedCorners[0] = null;
			this.selectedCorners[1] = null;
			this.mode = FieldWorkerMode.NONE;
			this.onDone = null;
			crosshair.graphics.clear();
		}
	}

}