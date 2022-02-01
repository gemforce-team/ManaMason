package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import Bezel.Bezel;
	import Bezel.BezelMod;
	import Bezel.GCCS.GCCSBezel;
	import Bezel.Logger;
	import Bezel.Utils.Keybind;
	import Bezel.Utils.SettingManager;
	import ManaMason.Utils.FieldWorker;
	import ManaMason.Utils.FieldWorkerMode;
	import ManaMason.Utils.LockedInfoPanel;
	import com.giab.common.abstract.SpriteExt;
	import com.giab.games.gccs.steam.GV;
	import com.giab.games.gccs.steam.SB;
	import com.giab.games.gccs.steam.constants.ActionStatus;
	import com.giab.games.gccs.steam.constants.IngameStatus;
	import com.giab.games.gccs.steam.entity.Amplifier;
	import com.giab.games.gccs.steam.entity.Tower;
	import com.giab.games.gccs.steam.entity.Trap;
	import com.giab.games.gccs.steam.entity.Wall;
	import com.giab.games.gccs.steam.mcDyn.McInfoPanel;
	import com.giab.games.gccs.steam.mcStat.McIngameFrame;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.filesystem.*;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	
	public class ManaMasonMod extends MovieClip implements BezelMod
	{
		
		public function get VERSION():String { return "1.7"; }
		public function get BEZEL_VERSION():String { return "1.1.0"; }
		public function get MOD_NAME():String { return "ManaMason"; }
		
		private var manaMason:Object;
		
		internal static var bezel:Bezel;
		internal static var logger:Logger;
		internal static var instance:ManaMasonMod;
		internal static var gameObjects:Object;
		
		public static var gemTypeToName: Array;
		
		public static const GCCS_VERSION:String = "1.0.6";
		
		internal static var storage:File;
		public static var structureClasses: Object;
		public static var selectedBlueprint:Blueprint;
		
		private var blueprints:Array;
		private var infoPanelTitle:TextField;
		private var currentBlueprintIndex:int;
		
		private var buildingMode:Boolean;
		private var shiftKeyPressed:Boolean;
		
		private var _lockedInfoPanel: LockedInfoPanel;
		private function get infoPanel():LockedInfoPanel {
			if (_lockedInfoPanel == null)
			{
				_lockedInfoPanel = new LockedInfoPanel();
			}
			return _lockedInfoPanel;
		}
		
		private static var settings: SettingManager;
		private static var blueprintOptions:BlueprintOptions;
		private var fieldWorker:FieldWorker;
		
		public function ManaMasonMod() 
		{
			super();
		}
		
		// This method binds the class to the game's objects
		public function bind(modLoader:Bezel, gObjects:Object):void
		{
			bezel = modLoader;
			logger = bezel.getLogger("ManaMason");
			if (!(bezel.mainLoader is GCCSBezel))
				return;
			
			gameObjects = gObjects;
			storage = File.applicationStorageDirectory.resolvePath("ManaMason");
			this.shiftKeyPressed = false;
			blueprintOptions = new BlueprintOptions();
			this.fieldWorker = new FieldWorker();
			initStaticDictionaries();
			
			//settings = SettingManager.getManager("ManaMason");
			//registerDefaultSettings();
			
			registerKeybinds();
			
			prepareFolders();
			
			initInfoPanelTitle();
			
			addEventListeners();
			
			instance = this;
			if (GV.ingameCore != null && GV.ingameCore.ingameStatus == IngameStatus.PLAYING)
				reloadBlueprintList();
			else
				this.blueprints = null;
			
			ManaMasonMod.logger.log("bind", "ManaMason initialized!");
		}
		
		private function initInfoPanelTitle(): void
		{
			var dummyInfoPanel: McInfoPanel = new McInfoPanel();
			dummyInfoPanel.addTextfield(15984813, "No blueprint", false, 9);
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
		
		private function initStaticDictionaries(): void
		{
			gemTypeToName = new Array();
			gemTypeToName[0] = "orange";
			gemTypeToName[1] = "yellow";
			gemTypeToName[2] = "white";
			gemTypeToName[3] = "red";
			gemTypeToName[4] = "green";
			gemTypeToName[5] = "cyan";
			gemTypeToName[6] = "black";
			gemTypeToName[7] = "blue";
			gemTypeToName[8] = "purple";
			
			structureClasses = new Object();
			structureClasses['w'] = Wall;
			structureClasses['t'] = Tower;
			structureClasses['a'] = Amplifier;
			structureClasses['r'] = Trap;
		}
		
		private function registerDefaultSettings(): void
		{
		}
		
		private function registerKeybinds(): void
		{
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Cycle selected blueprint left", new Keybind("page_up"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter building mode", new Keybind("ctrl+v"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter copy mode", new Keybind("ctrl+c"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter refund mode", new Keybind("ctrl+x"));
			ManaMasonMod.bezel.keybindManager.registerHotkey("ManaMason: Enter upgrade mode", new Keybind("ctrl+u"));
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
			if (this.fieldWorker.busy)
				this.fieldWorker.abort();
			
			cleanupAllBlueprints();
			
			var newBlueprints: Array = new Array();
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			
			var fileList: Array = blueprintsFolder.getDirectoryListing();
			for(var f:int = 0; f < fileList.length; f++)
			{
				var fileName:String = fileList[f].name;
				var file:File = fileList[f];
				if (file.extension == "txt")
				{
					var blueprint:Blueprint = Blueprint.fromFile(file.nativePath, fileName);
					if(blueprint != Blueprint.emptyBlueprint)
						newBlueprints.push(blueprint.setBlueprintOptions(blueprintOptions));
					else
					{
						SB.playSound("sndalert");
						GV.vfxEngine.createFloatingText(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Error opening" + fileName + "!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
					}
				}
			}
			
			ManaMasonMod.logger.log("reloadBlueprintList", "Found " + newBlueprints.length + " blueprint files.");
			
			newBlueprints.sortOn("name");
			this.blueprints = newBlueprints;
			
			selectBlueprintAt(0);
		}
		
		private function firstBlueprintLoad(e: Event): void
		{
			if (this.blueprints == null)
				reloadBlueprintList();
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
				
			selectBlueprintAt(this.currentBlueprintIndex);
		}
		
		public function selectBlueprintAt(index: int): void
		{
			if (index < 0 || index >= this.blueprints.length)
			{
				selectedBlueprint = Blueprint.emptyBlueprint;
				this.currentBlueprintIndex = -1;
			}
			else
			{
				this.currentBlueprintIndex = index;
				if(this.buildingMode)
					GV.main.cntScreens.cntIngame.removeChild(selectedBlueprint);
				selectedBlueprint = this.blueprints[this.currentBlueprintIndex];
				this.infoPanelTitle.text = selectedBlueprint.blueprintName;
				selectedBlueprint.resetGhosts();
				selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
				if (this.buildingMode)
				{
					GV.main.cntScreens.cntIngame.addChild(selectedBlueprint);
					drawBuildingOverlay(null);
				}
			}
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
			ManaMasonMod.bezel.addEventListener("ingameNewScene", firstBlueprintLoad);
			gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true, 10);
			gameObjects.main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true, 10);
			gameObjects.main.stage.addEventListener(Event.ENTER_FRAME, this.fieldWorker.frameUpdate);
			gameObjects.main.stage.addEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true, 10);
			//ManaMasonMod.bezel.gameObjects.main.stage.addEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.addEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
		}
		
		private function removeEventListeners(): void
		{
			ManaMasonMod.bezel.removeEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			ManaMasonMod.bezel.removeEventListener("ingameNewScene", firstBlueprintLoad);
			gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveBPUpdateHandler);
			gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, clickOnScene, true);
			gameObjects.main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightClickOnScene, true);
			gameObjects.main.stage.addEventListener(Event.ENTER_FRAME, this.fieldWorker.frameUpdate);
			gameObjects.main.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, eh_ingameWheelScrolled, true);
			//ManaMasonMod.bezel.gameObjects.main.stage.removeEventListener(Event.RESIZE, this.infoPanel.resizeHandler);
			this.infoPanel.removeEventListener(MouseEvent.MOUSE_DOWN, redrawRetinaHud);
		}
		
		private function mouseMoveBPUpdateHandler(e: MouseEvent): void
		{
			if (this.buildingMode)
			{
				this.updateBPOrigin();
				this.redrawRetinaHud();
			}
		}
		
		private function eh_discardAllMouseInput(e:MouseEvent): void
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
			cleanupAllBlueprints();
		}
		
		private function cleanupAllBlueprints(): void
		{
			if(this.blueprints)
				for each(var bp: Blueprint in this.blueprints)
					bp.cleanup();
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			
			if (pE.keyCode == Keyboard.ESCAPE)
			{
				if (this.buildingMode)
					exitBuildingMode();
				if (this.fieldWorker.busy)
				{
					this.fieldWorker.abort();
					afterWorkerDone();
				}
			}
			
			if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter copy mode").matches(pE))
			{
				if (this.buildingMode)
					exitBuildingMode();
					
				if (this.fieldWorker.mode == FieldWorkerMode.CAPTURE)
				{
					this.fieldWorker.abort();
					afterWorkerDone();
				}
				else
					enterCaptureMode();
				e.eventArgs.continueDefault = false;
				return;
			}
			else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter refund mode").matches(pE))
			{
				if (this.buildingMode)
					exitBuildingMode();
					
				if (this.fieldWorker.mode == FieldWorkerMode.REFUND)
				{
					this.fieldWorker.abort();
					afterWorkerDone();
				}
				else
					enterRefundMode();
				e.eventArgs.continueDefault = false;
				return;
			}
			else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter upgrade mode").matches(pE))
			{
				if (this.buildingMode)
					exitBuildingMode();
					
				if (this.fieldWorker.mode == FieldWorkerMode.UPGRADE)
				{
					this.fieldWorker.abort();
					afterWorkerDone();
				}
				else
					enterUpgradeMode();
				e.eventArgs.continueDefault = false;
				return;
			}
			if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Enter building mode").matches(pE))
			{
				if (this.fieldWorker.busy)
					this.fieldWorker.abort();
					
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
				GV.vfxEngine.createFloatingText(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Reloading blueprints!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
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
					selectedBlueprint.flipVertical();
					selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
					e.eventArgs.continueDefault = false;
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Flip blueprint horizontally").matches(pE))
				{
					selectedBlueprint.flipHorizontal();
					selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
					e.eventArgs.continueDefault = false;
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Rotate blueprint").matches(pE))
				{
					selectedBlueprint.rotate();
					selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
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
				
			this.fieldWorker.setMode(FieldWorkerMode.CAPTURE, wrapForWorkerOnDone(addBlueprint));
			GV.main.addChild(this.fieldWorker.crosshair);
			infoPanel.setup(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH, 20, BuildHelper.WAVESTONE_WIDTH, BuildHelper.TOP_UI_HEIGHT, 3.087007744E9);
			this.infoPanelTitle.width = this.infoPanel.width;
			this.infoPanelTitle.y = 5;
			this.infoPanelTitle.x = 0;
			this.infoPanelTitle.text = "Select area to copy. ESC or rightclick to cancel.";
			infoPanel.addTitle(this.infoPanelTitle);
			
			GV.mcInfoPanel.visible = false;
			showInfoPanel();
			discardAllMouseInput();
		}
		
		private function enterRefundMode(): void
		{
			if(GV.ingameCore.actionStatus == ActionStatus.CAST_GEMBOMB_INITIATED)
			{
				GV.ingameCore.controller.deselectEverything(true,false);
			}

			if(!(GV.ingameCore.actionStatus < ActionStatus.DRAGGING_GEM_FROM_TOWER_IDLE || GV.ingameCore.actionStatus >= ActionStatus.CAST_ENHANCEMENT_INITIATED))
				return;
				
			this.fieldWorker.setMode(FieldWorkerMode.REFUND, afterWorkerDone);
			GV.main.addChild(this.fieldWorker.crosshair);
			infoPanel.setup(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH, 20, BuildHelper.WAVESTONE_WIDTH, BuildHelper.TOP_UI_HEIGHT, 3.087007744E9);
			this.infoPanelTitle.width = this.infoPanel.width;
			this.infoPanelTitle.y = 5;
			this.infoPanelTitle.x = 0;
			this.infoPanelTitle.text = "Select area to refund all gems within. ESC or rightclick to cancel.";
			infoPanel.addTitle(this.infoPanelTitle);
			
			GV.mcInfoPanel.visible = false;
			showInfoPanel();
			discardAllMouseInput();
		}
		
		private function enterUpgradeMode(): void
		{
			if(GV.ingameCore.actionStatus == ActionStatus.CAST_GEMBOMB_INITIATED)
			{
				GV.ingameCore.controller.deselectEverything(true,false);
			}

			if(!(GV.ingameCore.actionStatus < ActionStatus.DRAGGING_GEM_FROM_TOWER_IDLE || GV.ingameCore.actionStatus >= ActionStatus.CAST_ENHANCEMENT_INITIATED))
				return;
				
			this.fieldWorker.setMode(FieldWorkerMode.UPGRADE, afterWorkerDone);
			GV.main.addChild(this.fieldWorker.crosshair);
			infoPanel.setup(BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH, 20, BuildHelper.WAVESTONE_WIDTH, BuildHelper.TOP_UI_HEIGHT, 3.087007744E9);
			this.infoPanelTitle.width = this.infoPanel.width;
			this.infoPanelTitle.y = 5;
			this.infoPanelTitle.x = 0;
			this.infoPanelTitle.text = "Select area to upgrade all gems within. ESC or rightclick to cancel.";
			infoPanel.addTitle(this.infoPanelTitle);
			
			GV.mcInfoPanel.visible = false;
			showInfoPanel();
			discardAllMouseInput();
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
			{
				SB.playSound("sndalert");
				GV.vfxEngine.createFloatingText(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"No blueprints in the blueprints folder!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
			}
			else
			{
				this.buildingMode = true;
				GV.mcInfoPanel.visible = false;
				selectedBlueprint.resetGhosts();
				selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY, true);
				GV.main.cntScreens.cntIngame.addChild(selectedBlueprint);
				changeRightSideUIVisibility(false);
				
				infoPanel.setup(1088 - BuildHelper.WAVESTONE_WIDTH - BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH - 4, BuildHelper.TILE_SIZE * BuildHelper.FIELD_HEIGHT, BuildHelper.WAVESTONE_WIDTH + BuildHelper.TILE_SIZE * BuildHelper.FIELD_WIDTH + 4, BuildHelper.TOP_UI_HEIGHT, 3.087007744E9);
				
				this.infoPanelTitle.text = selectedBlueprint.blueprintName;
				this.infoPanelTitle.x = 0;
				this.infoPanelTitle.y = 10;
				this.infoPanelTitle.width = this.infoPanel.width;
				infoPanel.addTitle(this.infoPanelTitle);
				
				infoPanel.addOptions(blueprintOptions);
				showInfoPanel();
			
				//discardAllMouseInput();
				GV.ingameCore.controller.deselectEverything(true, true);
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
			GV.main.cntScreens.cntIngame.removeChild(selectedBlueprint);
			this.buildingMode = false;
		}
		
		private function changeRightSideUIVisibility(shouldShow: Boolean): void
		{
			var frame: McIngameFrame = GV.main.cntScreens.cntIngame.mcIngameFrame;
			frame.mcInventory.visible = shouldShow;
			frame.mcGemGradeAvailBar.visible = shouldShow;
			for each(var gemBtn: MovieClip in frame.gemCreateButtons)
				gemBtn.visible = shouldShow;
			frame.btnCastBuildWall.visible = shouldShow;
			frame.btnCastBuildTrap.visible = shouldShow;
			frame.btnCastBuildTower.visible = shouldShow;
			frame.btnCastBuildAmplifier.visible = shouldShow;
			frame.btnCastCombineGems.visible = shouldShow;
			frame.btnCastThrow.visible = shouldShow;
			frame.tfBombAmount.visible = shouldShow;
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
				selectedBlueprint.castBuild(blueprintOptions);
			}
			else if (this.fieldWorker.busy)
			{
				this.fieldWorker.fieldClicked(mouseX, mouseY);
			}
			else
				return;
				
			mE.stopImmediatePropagation();
		}
		
		private function addBlueprint(bp:Blueprint): void
		{
			var capturedBP:Blueprint = bp.setBlueprintOptions(blueprintOptions);
			this.blueprints.unshift(capturedBP);
			this.currentBlueprintIndex = 0;
			selectedBlueprint = this.blueprints[currentBlueprintIndex];
		}
		
		private function wrapForWorkerOnDone(callback:Function):Function
		{
			var self:ManaMasonMod = this;
			return function(...args):void {
				callback(args[0]);
				self.afterWorkerDone();
			}
		}
		
		public function rightClickOnScene(mE:MouseEvent): void
		{
			if (this.buildingMode)
			{
				exitBuildingMode();
			}
			
			if (this.fieldWorker.busy)
			{
				this.fieldWorker.abort();
				afterWorkerDone();
			}
		}
		
		public function afterWorkerDone(): void
		{
			GV.main.removeChild(this.fieldWorker.crosshair);
			hideInfoPanel();
			restoreAllMouseInput();
			GV.mcInfoPanel.visible = true;
			changeRightSideUIVisibility(true);
		}
		
		private function drawBuildingOverlay(e:Event): void
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
				selectedBlueprint.updateOrigin(GV.main.mouseX, GV.main.mouseY);
		}
		
		private function showInfoPanel(): void
		{
			GV.main.addChild(this.infoPanel);
		}
		
		private function hideInfoPanel(): void
		{
			GV.main.removeChild(this.infoPanel);
		}
		
		public function prettyVersion(): String
		{
			return 'v' + VERSION + ' for ' + GCCS_VERSION;
		}
	}

}
