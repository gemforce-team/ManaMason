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
	import com.giab.games.gcfw.constants.ActionStatus;
	import com.giab.games.gcfw.constants.IngameStatus;
	import com.giab.games.gcfw.entity.Amplifier;
	import com.giab.games.gcfw.entity.Lantern;
	import com.giab.games.gcfw.entity.Pylon;
	import com.giab.games.gcfw.entity.Tower;
	import com.giab.games.gcfw.entity.Trap;
	import com.giab.games.gcfw.entity.Wall;
	import com.giab.games.gcfw.mcStat.McIngameFrame;
	import flash.display.Shape;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
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
		private var infoPanelTitle:TextField;
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
				_crosshair = new Shape;
			}
			return _crosshair;
		}
		private function get infoPanel():LockedInfoPanel {
			if (_lockedInfoPanel == null)
			{
				_lockedInfoPanel = new LockedInfoPanel();
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
			
			registerKeybinds();
			
			prepareFolders();
			
			initInfoPanelTitle();
			
			this.currentBlueprintIndex = -1;
			
			var self: GCFWManaMason = this;
			this.mouseMoveBPUpdateHandler = function(e: MouseEvent):void {
				if (self.buildingMode)
				{
					self.updateBPOrigin();
					self.redrawRetinaHud();
				}
				
			};
			
			addEventListeners();
			
			ManaMasonMod.logger.log("bind", "ManaMason initialized!");
		}
		
		private function initInfoPanelTitle(): void
		{
			var dummyInfoPanel: McInfoPanel = new McInfoPanel();
			dummyInfoPanel.addTextfield(15984813, "No blueprint", false, 10);
			this.infoPanelTitle = dummyInfoPanel.textfields.pop();
			this.infoPanelTitle.y = 10;
			this.infoPanelTitle.width = infoPanel.width - 10;
			this.infoPanelTitle.multiline = false;
			this.infoPanelTitle.wordWrap = false;
			this.infoPanelTitle.autoSize = TextFieldAutoSize.NONE
			this.infoPanelTitle.getTextFormat().align = "center";
			/*this.infoPanelTitle.defaultTextFormat = dummyInfoPanel.tFormat;
			this.infoPanelTitle.textColor = 15984813;
			this.infoPanelTitle.selectable = false;
			this.infoPanelTitle.antiAliasType = AntiAliasType.ADVANCED;
			//this.infoPanelTitle.height = 25;
			this.infoPanelTitle.y = 5;
			this.infoPanelTitle.text = "No blueprint";*/
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
				
			GV.main.cntScreens.cntIngame.removeChild(this.selectedBlueprint);
			this.selectedBlueprint = this.blueprints[this.currentBlueprintIndex];
			this.infoPanelTitle.text = this.selectedBlueprint.blueprintName;
			this.selectedBlueprint.resetGhosts();
			this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
			GV.main.cntScreens.cntIngame.addChild(this.selectedBlueprint);
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
			ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true, 10);
			ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true, 10);
			ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(Event.ENTER_FRAME, drawCaptureOverlay);
			ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true, 10);
			//ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.addEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
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
			ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true);
			ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true);
			ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(Event.ENTER_FRAME, drawCaptureOverlay);
			ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true);
			//ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.removeEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			
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
			if(GV.ingameCore.actionStatus == ActionStatus.CAST_GEMBOMB_INITIATED)
			{
				GV.ingameCore.controller.deselectEverything(true,false);
			}

			if(!(GV.ingameCore.actionStatus < ActionStatus.DRAGGING_GEM_FROM_TOWER_IDLE || GV.ingameCore.actionStatus >= ActionStatus.CAST_ENHANCEMENT_INITIATED))
				return;
				
			GV.ingameCore.cnt.cntRetinaHud.addChild(crosshair);
			infoPanel.setup(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH, 30, BuildHelper.WAVESTONE_WIDTH, BuildHelper.TOP_UI_HEIGHT, 4278190080);
			this.infoPanelTitle.width = this.infoPanel.width;
			this.infoPanelTitle.y = 5;
			this.infoPanelTitle.x = 0;
			infoPanel.addTitle(this.infoPanelTitle);
			
			this.captureMode = true;
			GV.mcInfoPanel.visible = false;
			showInfoPanel();
			discardAllMouseInput();
			drawCaptureOverlay(null);
		}
		
		private function enterBuildingMode(): void
		{
			if(GV.ingameCore.actionStatus == ActionStatus.CAST_GEMBOMB_INITIATED)
			{
				GV.ingameCore.controller.deselectEverything(true,false);
			}

			if(!(GV.ingameCore.actionStatus < ActionStatus.DRAGGING_GEM_FROM_TOWER_IDLE || GV.ingameCore.actionStatus >= ActionStatus.CAST_ENHANCEMENT_INITIATED))
				return;
				
			if (this.currentBlueprintIndex == -1)
				this.reloadBlueprintList();
				
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
				GV.main.cntScreens.cntIngame.addChild(this.selectedBlueprint);
				changeRightSideUIVisibility(false);
				
				infoPanel.setup(1920 - BuildHelper.WAVESTONE_WIDTH - BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH, 670, BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH + 4, 230, 0);
				
				this.infoPanelTitle.text = this.selectedBlueprint.blueprintName;
				this.infoPanelTitle.x = 0;
				this.infoPanelTitle.y = 15;
				this.infoPanelTitle.width = this.infoPanel.width;
				infoPanel.addTitle(this.infoPanelTitle);
				
				infoPanel.addOptions(blueprintOptions);
				showInfoPanel();
			
				//discardAllMouseInput();
				GV.ingameCore.controller.deselectEverything(true, true);
			}
		}
		
		private function changeRightSideUIVisibility(shouldShow: Boolean): void
		{
			var frame: McIngameFrame = GV.main.cntScreens.cntIngame.mcIngameFrame;
			//frame.mcInventory.visible = shouldShow;
			//frame.mcGemGradeAvailBar.visible = shouldShow;
			for each(var gemBtn: MovieClip in frame.gemCreateButtons)
				gemBtn.visible = shouldShow;
			frame.btnCastBuildWall.visible = shouldShow;
			frame.btnCastBuildTrap.visible = shouldShow;
			frame.btnCastBuildTower.visible = shouldShow;
			frame.btnCastBuildAmplifier.visible = shouldShow;
			frame.btnCastCombineGems.visible = shouldShow;
			//frame.btnCastThrow.visible = shouldShow;
			//frame.tfBombAmount.visible = shouldShow;
			GV.ingameCore.cnt.cntGemsInInventory.visible = shouldShow;
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
			
			if (mouseX < BuildHelper.WAVESTONE_WIDTH || mouseX > BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH || mouseY < BuildHelper.TOP_UI_HEIGHT || mouseY > BuildHelper.TOP_UI_HEIGHT + BuildHelper.TILE_SIZE * BuildHelper.FIELD_HEIGHT)
			{
				return;
			}
			
			if (this.buildingMode)
			{
				this.selectedBlueprint.castBuild(blueprintOptions);
			}
			else if (this.captureMode)
			{
					
				var vX:Number = Math.floor((mouseX - BuildHelper.WAVESTONE_WIDTH) / BuildHelper.TILE_SIZE);
				var vY:Number = Math.floor((mouseY - BuildHelper.TOP_UI_HEIGHT) / BuildHelper.TILE_SIZE);
				
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
			hideInfoPanel();
			GV.mcInfoPanel.visible = true;
			restoreAllMouseInput();
			crosshair.graphics.clear();
			GV.ingameCore.cnt.cntRetinaHud.addChild(crosshair);
		}
		
		private function drawBuildingOverlay(e: Event): void
		{
			if (!this.buildingMode)
				return;
				
			redrawRetinaHud();
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
		
		public function updateBPOrigin(): void
		{
			if(this.buildingMode && this.currentBlueprintIndex != -1)
				this.selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY);
		}
		
		private function drawCaptureOverlay(e: Event): void
		{
			if (!this.captureMode)
				return;
				
			var mX: Number = GV.main.cntScreens.cntIngame.root.mouseX;
			var mY: Number = GV.main.cntScreens.cntIngame.root.mouseY;
			
			var text: String = "";
			
			if (mX > BuildHelper.WAVESTONE_WIDTH &&
				mX < BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH &&
				mY > BuildHelper.TOP_UI_HEIGHT &&
				mY < BuildHelper.TOP_UI_HEIGHT + BuildHelper.TILE_SIZE*BuildHelper.FIELD_HEIGHT)
			{
				var rHUD: SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
				/*if(rHUD.getChildIndex(crosshair) >=0 )
					rHUD.removeChild(crosshair);*/
				crosshair.graphics.clear();
				crosshair.graphics.lineStyle(2, 0x00FF00, 1);
				if (this.captureCorners[0] == null) {
					this.infoPanelTitle.text = "Please click one corner of your selection.";
					crosshair.graphics.moveTo(BuildHelper.WAVESTONE_WIDTH, mY);
					crosshair.graphics.lineTo(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH+BuildHelper.WAVESTONE_WIDTH, mY);
					crosshair.graphics.moveTo(mX, BuildHelper.TOP_UI_HEIGHT);
					crosshair.graphics.lineTo(mX, BuildHelper.TILE_SIZE * BuildHelper.FIELD_HEIGHT+BuildHelper.TOP_UI_HEIGHT);
				}
				else if (this.captureCorners[1] == null)
				{
					this.infoPanelTitle.text = "Please click the opposite corner of your selection.";
					crosshair.graphics.moveTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][0]), BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][0]), mY);
					crosshair.graphics.lineTo(mX, mY);
					crosshair.graphics.lineTo(mX, BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(BuildHelper.WAVESTONE_WIDTH + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][0]), BuildHelper.TOP_UI_HEIGHT + 8 + BuildHelper.TILE_SIZE * (this.captureCorners[0][1]));
				}
			}
		}
		
		private function exitBuildingMode(): void
		{
			var rHUD:Object = GV.ingameCore.cnt.cntRetinaHud;
			rHUD.removeChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
			rHUD.removeChild(GV.ingameCore.cnt.bmpWallPlaceAvailMap);
			hideInfoPanel();
			restoreAllMouseInput();
			changeRightSideUIVisibility(true);
			GV.mcInfoPanel.visible = true;
			GV.main.cntScreens.cntIngame.removeChild(this.selectedBlueprint);
			this.buildingMode = false;
		}
		
		private function showInfoPanel(): void
		{
			GV.main.addChild(this.infoPanel);
		}
		
		private function hideInfoPanel(): void
		{
			GV.main.removeChild(this.infoPanel);
		}
	}
}
