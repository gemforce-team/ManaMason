package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import Bezel.GCFW.GCFWBezel;
	import Bezel.Utils.Keybind;
	import Bezel.Utils.SettingManager;
	import ManaMason.Utils.BlueprintOption;
	import ManaMason.Utils.LockedInfoPanel;
	import com.giab.common.abstract.SpriteExt;
	import com.giab.games.gcfw.constants.IngameStatus;
	import com.giab.games.gcfw.entity.Amplifier;
	import com.giab.games.gcfw.entity.Lantern;
	import com.giab.games.gcfw.entity.Pylon;
	import com.giab.games.gcfw.entity.Tower;
	import com.giab.games.gcfw.entity.Trap;
	import com.giab.games.gcfw.entity.Wall;
	import flash.display.Shape;
	import flash.ui.Keyboard;
	
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.SB;
	import com.giab.games.gcfw.mcDyn.McInfoPanel;
	
	import flash.display.MovieClip;
	import flash.filesystem.*;
	import flash.events.*;
	import com.giab.games.gcfw.mcDyn.McBuildWallHelper;
	import flash.geom.ColorTransform;
	import flash.events.MouseEvent;
	
	public class GCFWManaMason extends MovieClip
	{
		internal static var storage:File;
		public static var structureClasses: Object;
		
		private var blueprints:Array;
		private var selectedBlueprint:Blueprint;
		private var currentBlueprintIndex:int;
		private var mouseMoveBPUpdateHandler:Function;
		
		private var buildingMode:Boolean;
		private var captureMode:Boolean;
		private var captureCorners: Object;
		private var shiftKeyPressed:Boolean;
		
		private var _crosshair:Shape;
		private var _lockedInfoPanel: LockedInfoPanel;
		private var _baseInfoPanel: McInfoPanel;
		private function get crosshair():Shape {
			if (_crosshair == null)
			{
				initUI();
			}
			return _crosshair;
		}
		private function get infoPanel():LockedInfoPanel {
			if (_lockedInfoPanel == null)
			{
				initUI();
			}
			return _lockedInfoPanel;
		}
		
		private static var settings: SettingManager;
		private static var blueprintOptions: BlueprintOptions;
		
		public function GCFWManaMason() 
		{
			super();
			
			storage = File.applicationStorageDirectory.resolvePath("ManaMason");
			
			this.blueprints = new Array();
			this.shiftKeyPressed = false;
			this.captureMode = false;
			this.captureCorners = new Object();
			blueprintOptions = new BlueprintOptions();
			captureCorners[0] = null;
			captureCorners[1] = null;
			
			structureClasses = new Object();
			structureClasses['w'] = Wall;
			structureClasses['t'] = Tower;
			structureClasses['a'] = Amplifier;
			structureClasses['r'] = Trap;
			structureClasses['p'] = Pylon;
			structureClasses['l'] = Lantern;
			
			//settings = SettingManager.getManager("ManaMason");
			//registerDefaultSettings();
			
			initUI();
			
			registerKeybinds();
			
			prepareFolders();
			
			reloadBlueprintList();
			
			var self: GCFWManaMason = this;
			this.mouseMoveBPUpdateHandler = function(e: MouseEvent):void {
				if (self.buildingMode)
				{
					self.updateBPOrigin(e.stageX, e.stageY);
					self.redrawRetinaHud();
				}
				
			};
			
			addEventListeners();
			
			ManaMasonMod.logger.log("bind", "ManaMason initialized!");
		}
		
		private function initUI(): void
		{
			_baseInfoPanel = new McInfoPanel();
			_crosshair = new Shape();
			_lockedInfoPanel = new ManaMason.Utils.LockedInfoPanel(_baseInfoPanel);
			infoPanel.setup(1920 - 1728, 670, 1728, 230, 4278190080);
			//infoPanel.basePanel.addEventListener(MouseEvent.CLICK, function(me:MouseEvent):void {GV.vfxEngine.createFloatingText4(400, 400, "InfoPanelCLicked!", 16768392, 18, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 46, 0, 13); });
		}
		
		private function registerDefaultSettings(): void
		{
		}
		
		private function registerKeybinds(): void
		{
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Cycle selected blueprint left", new Keybind("page_up"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter building mode", new Keybind("ctrl+v"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter capture mode", new Keybind("ctrl+c"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Cycle selected blueprint right", new Keybind("page_down"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Reload recipes", new Keybind("ctrl+r"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Flip blueprint horizontally", new Keybind("f"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Flip blueprint vertically", new Keybind("v"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Rotate blueprint", new Keybind("r"));
			// GemsmithMod.bezel.keybindManager.registerHotkey("Gemsmith: Conjure gem", 89);
		}
		
		private function reloadBlueprintList(): void
		{
			if(this.buildingMode)
				exitBuildingMode();
			if (this.captureMode)
				exitCaptureMode();
			
			var newBlueprints: Array = new Array();
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			
			var fileList: Array = blueprintsFolder.getDirectoryListing();
			for(var f:int = 0; f < fileList.length; f++)
			{
				var fileName:String = fileList[f].name;
				if (fileName.substring(fileName.length - 4, fileName.length) == ".txt")
				{
					var blueprint:Blueprint = Blueprint.fromFile(blueprintsFolder.resolvePath(fileName).nativePath, fileName);
					if(blueprint != Blueprint.emptyBlueprint)
						newBlueprints.push(blueprint.setBlueprintOptions(blueprintOptions));
					else
					{
						SB.playSound("sndalert");
						GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Error opening" + fileName + "!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
					}
				}
			}
			
			ManaMasonMod.logger.log("reloadBlueprintList", "Found " + newBlueprints.length + " blueprint files.");
			
			if (newBlueprints.length == 0)
			{
				this.currentBlueprintIndex = -1;
			}
			else
			{
				this.currentBlueprintIndex = 0;
				this.selectedBlueprint = newBlueprints[this.currentBlueprintIndex];
			}
			newBlueprints.sortOn("name");
			this.blueprints = newBlueprints;
		}
		
		public function cycleSelectedBlueprint(increment:int): void
		{
			if(this.currentBlueprintIndex == -1)
				return;
			if (!this.buildingMode)
				return;
			
			this.currentBlueprintIndex += increment;
			if(this.currentBlueprintIndex < 0)
				this.currentBlueprintIndex = blueprints.length - 1;
			else if(this.currentBlueprintIndex > blueprints.length - 1)
				this.currentBlueprintIndex = 0;
				
			GV.main.stage.removeChild(this.selectedBlueprint);
			this.selectedBlueprint = this.blueprints[this.currentBlueprintIndex];
			this.selectedBlueprint.resetGhosts();
			this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
			GV.main.stage.addChild(this.selectedBlueprint);
			drawBuildingOverlay(null);
		}
		
		private function prepareFolders(): void
		{
			if (!storage.isDirectory)
			{
				storage.createDirectory();
			}
			
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			if (!blueprintsFolder.isDirectory)
			{
				blueprintsFolder.createDirectory();
				var exampleBlueprint:File = blueprintsFolder.resolvePath("exampleBlueprint.txt");
				var bpWriter:FileStream = new FileStream();
				try
				{
					bpWriter.open(exampleBlueprint, FileMode.WRITE);
					bpWriter.writeUTFBytes("aaaaaa\r\n");
					bpWriter.writeUTFBytes("aaaaaa\r\n");
					bpWriter.writeUTFBytes("aattaa\r\n");
					bpWriter.writeUTFBytes("aattaa\r\n");
					bpWriter.writeUTFBytes("aaaaaa\r\n");
					bpWriter.writeUTFBytes("aaaaaa");
					bpWriter.close();
				}
				catch (e:Error)
				{
					ManaMasonMod.logger.log("prepareFolders", "Caught an error while preparing folders!");
					ManaMasonMod.logger.log("prepareFolders", e.message);
				}
			}
		}
		
		private function addEventListeners(): void
		{
			ManaMasonMod.bezel.addEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true, 10);
			GV.main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true, 10);
			GV.main.stage.addEventListener(Event.ENTER_FRAME, drawCaptureOverlay);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true, 10);
			GV.main.stage.addEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.basePanel.addEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
		}
		
		private function eh_discardAllMouseInput(e:MouseEvent):void
		{
			e.stopImmediatePropagation();
		}
		
		public function unload(): void
		{
			removeEventListeners();
			/*for each (var type:Object in this.activeBitmaps)
			{
				for (var i:int = 0; i < type.occupied; i++)
				{
					type.bitmaps[i].bitmapData.dispose();
				}
			}*/
			
			if(this.buildingMode)
				exitBuildingMode();
				
			Blueprint.cleanup();
		}
		
		private function removeEventListeners(): void
		{
			ManaMasonMod.bezel.removeEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true);
			GV.main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true);
			GV.main.stage.removeEventListener(Event.ENTER_FRAME, drawCaptureOverlay);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true);
			GV.main.stage.removeEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.basePanel.removeEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			this.shiftKeyPressed = pE.shiftKey;
			
			if (pE.keyCode == Keyboard.ESCAPE)
			{
				if (this.buildingMode)
					exitBuildingMode();
				if (this.captureMode)
					exitCaptureMode();
			}
			
			if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter capture mode").matches(pE))
			{
				if (this.buildingMode)
					exitBuildingMode();
					
				if (this.captureMode)
				{
					exitCaptureMode();
				}
				else
				{
					enterCaptureMode();
				}
				e.eventArgs.continueDefault = false;
				return;
			}
			else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter building mode").matches(pE))
			{
				if (this.captureMode)
					exitCaptureMode();
					
				if (this.buildingMode)
				{
					exitBuildingMode();
				}
				else
				{
					enterBuildingMode();
					drawBuildingOverlay(null);
				}
				e.eventArgs.continueDefault = !this.buildingMode;
				return;
			}
			else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Reload recipes").matches(pE))
			{
				reloadBlueprintList();
				SB.playSound("sndalert");
				GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Reloading blueprints!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
				e.eventArgs.continueDefault = false;
				return;
			}
			
			if (this.buildingMode)
			{
				if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Cycle selected blueprint left").matches(pE))
				{
					cycleSelectedBlueprint(-1);
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Cycle selected blueprint right").matches(pE))
				{
					cycleSelectedBlueprint(1);
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Flip blueprint vertically").matches(pE))
				{
					this.selectedBlueprint.flipVertical();
					this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
					e.eventArgs.continueDefault = false;
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Flip blueprint horizontally").matches(pE))
				{
					this.selectedBlueprint.flipHorizontal();
					this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
					e.eventArgs.continueDefault = false;
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Rotate blueprint").matches(pE))
				{
					this.selectedBlueprint.rotate();
					this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
					e.eventArgs.continueDefault = false;
				}
			}
		}
		
		private function enterCaptureMode(): void
		{
			this.captureMode = true;
			GV.mcInfoPanel.visible = false;
			discardAllMouseInput();
			drawCaptureOverlay(null);
		}
		
		private function enterBuildingMode(): void
		{
			if (this.currentBlueprintIndex == -1)
			{
				SB.playSound("sndalert");
				GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"No blueprints in the blueprints folder!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
			}
			else
			{
				this.buildingMode = true;
				GV.mcInfoPanel.visible = false;
				this.selectedBlueprint.resetGhosts();
				this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
				GV.main.stage.addChild(this.selectedBlueprint);
				//discardAllMouseInput();
				GV.ingameCore.controller.deselectEverything(true, true);
			}
		}
		
		private function discardAllMouseInput(): void
		{
			GV.main.stage.addEventListener(MouseEvent.CLICK, eh_discardAllMouseInput, true, 5, false);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_DOWN, eh_discardAllMouseInput, true, 5, false);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_UP, eh_discardAllMouseInput, true, 5, false);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_OVER, eh_discardAllMouseInput, true, 5, false);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_OUT, eh_discardAllMouseInput, true, 5, false);
			GV.main.stage.addEventListener(MouseEvent.MOUSE_MOVE, eh_discardAllMouseInput, true, 5, false);
		}
		
		private function restoreAllMouseInput(): void
		{
			
			GV.main.stage.removeEventListener(MouseEvent.CLICK, eh_discardAllMouseInput, true);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, eh_discardAllMouseInput, true);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_UP, eh_discardAllMouseInput, true);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_OVER, eh_discardAllMouseInput, true);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_OUT, eh_discardAllMouseInput, true);
			GV.main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, eh_discardAllMouseInput, true);
		}
		
		public function eh_ingameWheelScrolled(e: MouseEvent): void
		{
			if (!buildingMode)
				return;
				
			if (e.delta > 0)
				cycleSelectedBlueprint( -1);
			else
				cycleSelectedBlueprint(1);
				
			e.stopImmediatePropagation();
		}
		
		public function clickOnScene(mE:MouseEvent): void
		{
			if (GV.ingameCore.ingameStatus != IngameStatus.PLAYING)
				return;
				
			var mouseX:Number = GV.ingameCore.cnt.root.mouseX;
			var mouseY:Number  = GV.ingameCore.cnt.root.mouseY;
			
			if (mouseX < 50 || mouseX > 50 + 1680 || mouseY < 8 || mouseY > 8 + 1064)
			{
				return;
			}
			
			if (this.buildingMode)
			{
				this.selectedBlueprint.castBuild(blueprintOptions);
			}
			else if (this.captureMode)
			{
					
				var vX:Number = Math.floor((mouseX - 50) / 28);
				var vY:Number = Math.floor((mouseY - 8) / 28);
				
				if (this.captureCorners[0] == null)
				{
					this.captureCorners[0] = [vX, vY];
					drawCaptureOverlay(mE);
				}
				else if (this.captureCorners[1] == null)
				{
					var cx: Number = this.captureCorners[0][0];
					var cy: Number = this.captureCorners[0][1];
					if (vX -cx <= 0 && vY - cy <= 0)
					{
						this.captureCorners[0] = [vX, vY];
						this.captureCorners[1] = [cx, cy];
					}
					else if(vX -cx >= 0 && vY - cy >= 0)
					{
						this.captureCorners[1] = [vX, vY];
						this.captureCorners[0] = [cx, cy];
					}
					else
					{
						cx = vX;
						vX = this.captureCorners[0][0];
						if (vX -cx <= 0 && vY - cy <= 0)
						{
							this.captureCorners[0] = [vX, vY];
							this.captureCorners[1] = [cx, cy];
						}
						else if(vX -cx >= 0 && vY - cy >= 0)
						{
							this.captureCorners[1] = [vX, vY];
							this.captureCorners[0] = [cx, cy];
						}
						else
						{
							exitCaptureMode();
							return;
						}
					}
					
					var capturedBP: Blueprint = Blueprint.tryCaptureFromField(this.captureCorners).setBlueprintOptions(blueprintOptions);
					blueprints.unshift(capturedBP);
					currentBlueprintIndex = 0;
					selectedBlueprint = blueprints[currentBlueprintIndex];
					exitCaptureMode();
				}
			}
			else
				return;
				
			mE.stopImmediatePropagation();
		}
		
		public function rightClickOnScene(mE:MouseEvent): void
		{
			if (this.buildingMode)
			{
				exitBuildingMode();
			}
			
			if (this.captureMode)
			{
				exitCaptureMode();
			}
		}
		
		private function exitCaptureMode(): void
		{
			this.captureCorners[0] = null;
			this.captureCorners[1] = null;
			this.captureMode = false;
			infoPanel.hide();
			GV.mcInfoPanel.visible = true;
			restoreAllMouseInput();
			crosshair.graphics.clear();
		}
		
		private function drawBuildingOverlay(e: Event): void
		{
			if (!this.buildingMode)
				return;
				
			redrawRetinaHud();
			
			infoPanel.setup(1920 - 1728, 670, 1728, 230, 4278190080);
			infoPanel.basePanel.addTextfield(16777215, this.selectedBlueprint.blueprintName || "No blueprint", true, 11);
			infoPanel.basePanel.addExtraHeight(10);
			infoPanel.addOptions(blueprintOptions);
			infoPanel.show();
			infoPanel.basePanel.mouseEnabled = infoPanel.basePanel.mouseChildren = true;
		}
		
		public function redrawRetinaHud(...args): void
		{
			GV.ingameCore.controller.deselectEverything(true, true);
				
			var rHUD:SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
				
			if(!rHUD.contains(GV.ingameCore.cnt.bmpWallPlaceAvailMap))
				rHUD.addChild(GV.ingameCore.cnt.bmpWallPlaceAvailMap);
			if(!rHUD.contains(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap))
				rHUD.addChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
		}
		
		public function updateBPOrigin(mX: Number, mY: Number): void
		{
			if(this.buildingMode)
				this.selectedBlueprint.updateOrigin(mX, mY);
		}
		
		private function drawCaptureOverlay(e: Event): void
		{
			if (!this.captureMode)
				return;
				
			var mX: Number = GV.main.cntScreens.cntIngame.root.mouseX;
			var mY: Number = GV.main.cntScreens.cntIngame.root.mouseY;
			
			infoPanel.setup(1680, -1, 50, 8, 4278190080);
			var text: String = "";
			
			if (mX > 50 &&
				mX < 50 + 1680 &&
				mY > 8 &&
				mY < 8 + 1064)
			{
				var rHUD: SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
				rHUD.removeChildren();
				crosshair.graphics.clear();
				crosshair.graphics.lineStyle(2, 0x00FF00, 1);
				if (this.captureCorners[0] == null) {
					text = "Please click one corner of your selection.";
					crosshair.graphics.moveTo(50, mY);
					crosshair.graphics.lineTo(1680+50, mY);
					crosshair.graphics.moveTo(mX, 8);
					crosshair.graphics.lineTo(mX, 1064+8);
				}
				else if (this.captureCorners[1] == null)
				{
					text = "Please click the opposite corner of your selection.";
					crosshair.graphics.moveTo(50 + 14 + 28 * (this.captureCorners[0][0]), 8 + 14 + 28 * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(50 + 14 + 28 * (this.captureCorners[0][0]), mY);
					crosshair.graphics.lineTo(mX, mY);
					crosshair.graphics.lineTo(mX, 8 + 14 + 28 * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(50 + 14 + 28 * (this.captureCorners[0][0]), 8 + 14 + 28 * (this.captureCorners[0][1]));
				}
				rHUD.addChild(crosshair);
			}
			
			infoPanel.basePanel.addTextfield(16777215, text, true, 11);
			infoPanel.show();
		}
		
		private function exitBuildingMode(): void
		{
			var rHUD:Object = GV.ingameCore.cnt.cntRetinaHud;
			rHUD.removeChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
			rHUD.removeChild(GV.ingameCore.cnt.bmpWallPlaceAvailMap);
			infoPanel.hide();
			restoreAllMouseInput();
			GV.mcInfoPanel.visible = true;
			GV.main.stage.removeChild(this.selectedBlueprint);
			this.buildingMode = false;
		}
	}

}
