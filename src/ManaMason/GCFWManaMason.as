package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import Bezel.Events.EventTypes;
	import Bezel.Events.IngameGemInfoPanelFormedEvent;
	import Bezel.Events.IngameKeyDownEvent;
	import Bezel.Utils.Keybind;
	import Bezel.Utils.SettingManager;
	import com.giab.common.abstract.SpriteExt;
	import com.giab.games.gcfw.entity.Amplifier;
	import com.giab.games.gcfw.entity.Lantern;
	import com.giab.games.gcfw.entity.Pylon;
	import com.giab.games.gcfw.entity.Tower;
	import com.giab.games.gcfw.entity.Trap;
	import com.giab.games.gcfw.entity.Wall;
	import flash.display.Shape;
	
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.SB;
	import com.giab.games.gcfw.ingame.IngameCore;
	import com.giab.games.gcfw.mcDyn.McInfoPanel;
	import com.giab.games.gcfw.mcStat.CntIngame;
	
	import air.update.events.StatusFileUpdateErrorEvent;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.filesystem.*;
	import flash.events.*;
	import flash.globalization.LocaleID;
	import flash.utils.*;
	
	public class GCFWManaMason extends MovieClip
	{
		internal static var storage:File;
		public static var structureClasses: Object;
		
		private var blueprints:Array;
		private var activeBitmaps:Object;
		private var activeWallHelpers:Object;
		private var selectedBlueprint:Blueprint;
		private var currentBlueprintIndex:int;
		
		private var buildingMode:Boolean;
		private var captureMode:Boolean;
		private var captureCorners: Object;
		private var shiftKeyPressed:Boolean;
		
		private var crosshair:Shape;
		
		private static var settings: SettingManager;
		
		public function GCFWManaMason() 
		{
			super();
			storage = File.applicationStorageDirectory.resolvePath("ManaMason");
			
			this.blueprints = new Array();
			this.shiftKeyPressed = false;
			this.captureMode = false;
			this.captureCorners = new Object();
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
			
			initCrosshair();
			
			registerKeybinds();
			
			initActiveBitmaps();
			
			initBuildingHelpers();
			
			prepareFolders();
			
			reloadBlueprintList();
			
			addEventListeners();
			
			ManaMasonMod.logger.log("bind", "ManaMason initialized!");
		}
		
		private function initCrosshair(): void
		{
			crosshair = new Shape();
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
		
		private function initBuildingHelpers(): void
		{
			BuildHelper.bitmaps = new Object();
			var buildHelperBitmaps:Object = BuildHelper.bitmaps;
			buildHelperBitmaps["a"] = GV.ingameCore.cnt.bmpBuildHelperAmp;
			buildHelperBitmaps["t"] = GV.ingameCore.cnt.bmpBuildHelperTower;
			buildHelperBitmaps["r"] = GV.ingameCore.cnt.bmpBuildHelperTrap;
			buildHelperBitmaps["p"] = GV.ingameCore.cnt.bmpBuildHelperPylon;
			buildHelperBitmaps["l"] = GV.ingameCore.cnt.bmpBuildHelperLantern;
		}
		
		private function initActiveBitmaps(): void
		{
			this.activeBitmaps = new Object();
			this.activeBitmaps["a"] = {"occupied":0, "bitmaps": new Array()};
			this.activeBitmaps["t"] = {"occupied":0, "bitmaps": new Array()};
			this.activeBitmaps["r"] = {"occupied":0, "bitmaps": new Array()};
			this.activeBitmaps["p"] = {"occupied":0, "bitmaps": new Array()};
			this.activeBitmaps["l"] = {"occupied":0, "bitmaps": new Array()};
			
			this.activeWallHelpers = {"occupied":0, "movieClips": new Array()};
		}
		
		private function reloadBlueprintList(): void
		{
			var newBlueprints: Array = new Array();
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			
			var fileList: Array = blueprintsFolder.getDirectoryListing();
			for(var f:int = 0; f < fileList.length; f++)
			{
				var fileName:String = fileList[f].name;
				if (fileName.substring(fileName.length - 4, fileName.length) == ".txt")
				{
					var blueprint:Blueprint = Blueprint.fromFile(blueprintsFolder.resolvePath(fileName).nativePath);
					if(blueprint != Blueprint.emptyBlueprint)
						newBlueprints.push(blueprint);
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
				
			this.selectedBlueprint = this.blueprints[this.currentBlueprintIndex];
			this.eh_ingamePreRenderInfoPanel(null);
		}
		
		/*private function checkForUpdates(): void
		{
			if(!this.configuration["Check for updates"])
				return;
			
			logger.log("CheckForUpdates", "Mod version: " + prettyVersion());
			logger.log("CheckForUpdates", "Checking for updates...");
			var repoAddress:String = "https://api.github.com/repos/gemforce-team/gemsmith/releases/latest";
			var request:URLRequest = new URLRequest(repoAddress);
			
			var loader:URLLoader = new URLLoader();
			var localThis:Gemsmith = this;
			
			loader.addEventListener(Event.COMPLETE, function(e:Event): void {
				var latestTag:Object = JSON.parse(loader.data).tag_name;
				var latestVersion:String = latestTag.replace(/[v]/gim, ' ').split('-')[0];
				localThis.updateAvailable = (latestVersion != VERSION);
				logger.log("CheckForUpdates", localThis.updateAvailable ? "Update available! " + latestTag : "Using the latest version: " + latestTag);
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent): void {
				logger.log("CheckForUpdates", "Caught an error when checking for updates!");
			});
			
			loader.load(request);
		}*/
		
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
			ManaMasonMod.bezel.addEventListener("ingamePreRenderInfoPanel", eh_ingamePreRenderInfoPanel);
			ManaMasonMod.bezel.addEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			ManaMasonMod.bezel.addEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			ManaMasonMod.bezel.addEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
			GV.ingameCore.cnt.addEventListener(MouseEvent.MOUSE_MOVE, drawCaptureOverlay);
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
			
			for each (var mc:Object in this.activeWallHelpers.movieClips)
			{
				mc.stop();
				mc = null;
			}
			
			this.activeWallHelpers = {"occupied":0, "movieClips": new Array()};
			
			if(this.buildingMode)
				exitBuildingMode();
		}
		
		private function removeEventListeners(): void
		{
			ManaMasonMod.bezel.removeEventListener("ingamePreRenderInfoPanel", eh_ingamePreRenderInfoPanel);
			ManaMasonMod.bezel.removeEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			ManaMasonMod.bezel.removeEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			ManaMasonMod.bezel.removeEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
			GV.ingameCore.cnt.removeEventListener(MouseEvent.MOUSE_MOVE, drawCaptureOverlay);
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;
			this.shiftKeyPressed = pE.shiftKey;
			
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
					
				this.buildingMode = !this.buildingMode;
				if (!this.buildingMode)
				{
					exitBuildingMode();
				}
				else
				{
					if (this.currentBlueprintIndex == -1)
					{
						SB.playSound("sndalert");
						GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"No blueprints in the blueprints folder!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
						this.buildingMode = false;
					}
					else
					{
						GV.ingameCore.controller.deselectEverything(true, true);
					}
				}
				eh_ingamePreRenderInfoPanel(null);
				e.eventArgs.continueDefault = !this.buildingMode;
				return;
			}
			else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Reload recipes").matches(pE))
			{
				reloadBlueprintList();
				SB.playSound("sndalert");
				GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Reloading blueprints!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
				e.eventArgs.continueDefault = false;
				eh_ingamePreRenderInfoPanel(null);
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
					e.eventArgs.continueDefault = false;
					this.eh_ingamePreRenderInfoPanel(null);
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Flip blueprint horizontally").matches(pE))
				{
					this.selectedBlueprint.flipHorizontal();
					e.eventArgs.continueDefault = false;
					this.eh_ingamePreRenderInfoPanel(null);
				}
				else if (ManaMasonMod.bezel.keybindManager.getHotkeyValue("ManaMason: Rotate blueprint").matches(pE))
				{
					this.selectedBlueprint.rotate();
					e.eventArgs.continueDefault = false;
					this.eh_ingamePreRenderInfoPanel(null);
				}
			}
		}
		
		private function enterCaptureMode(): void
		{
			this.captureMode = true;
			GV.vfxEngine.createFloatingText4(GV.main.mouseX,GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20),"Click top left and bottom right corners to capture structures!",16768392,12,"center",Math.random() * 3 - 1.5,-4 - Math.random() * 3,0,0.55,12,0,1000);
		}
		
		public function eh_ingameClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			
			if (this.buildingMode)
			{
				this.selectedBlueprint.castBuild(!this.shiftKeyPressed);
				e.eventArgs.continueDefault = false;	
			}
			else if (this.captureMode)
			{
				var mouseX:Number = GV.ingameCore.cnt.root.mouseX;
				var mouseY:Number  = GV.ingameCore.cnt.root.mouseY;
				if (mouseX < 50 || mouseX > 50 + 1680 || mouseY < 8 || mouseY > 8 + 1064)
				{
					return;
				}
					
				var vX:Number = Math.floor((mouseX - 50) / 28);
				var vY:Number = Math.floor((mouseY - 8) / 28);
				
				if (this.captureCorners[0] == null)
				{
					this.captureCorners[0] = [vX, vY];

				}
				else if (this.captureCorners[1] == null)
				{
					this.captureCorners[1] = [vX, vY];
					tryCaptureFromField();
					exitCaptureMode();
				}
				e.eventArgs.continueDefault = false;
			}
		}
		
		public function eh_ingameRightClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if (this.buildingMode)
			{
				exitBuildingMode();
			}
			
			if (this.captureMode)
			{
				exitCaptureMode();
			}
		}
		
		private function tryCaptureFromField(): void
		{
			var grid:Object = GV.ingameCore.buildingAreaMatrix;
			var tileProcessed: Boolean = false;
			var structureString: String = "";
			
			for (var i:int = captureCorners[0][1]; i <= captureCorners[1][1]; i++) 
			{
				for (var j:int = captureCorners[0][0]; j <= captureCorners[1][0]; j++) 
				{
					tileProcessed = false;
					for (var type:String in structureClasses)
					{
						if (grid[i][j] is structureClasses[type]){
							structureString += type;
							tileProcessed = true;
							break;
						}
					}
					
					if (!tileProcessed)
					{
						structureString += "-";
					}
				}
				structureString += "\r\n";
			}
			var capturedBP: Blueprint = Blueprint.fromString(structureString);
			blueprints.unshift(capturedBP);
			currentBlueprintIndex = 0;
			selectedBlueprint = blueprints[currentBlueprintIndex];
			exportBlueprintFile(structureString);
		}
		
		private function exportBlueprintFile(bpString: String): void
		{
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			var bpFile:File = blueprintsFolder.resolvePath("capturedBP.txt");
			var bpWriter:FileStream = new FileStream();
			try
			{
				bpWriter.open(bpFile, FileMode.WRITE);
				bpWriter.writeUTFBytes(bpString);
			}
			catch (err:Error)
			{
				ManaMasonMod.logger.log("BPexport", "Error when exporting a BP!" + err.message);
			}
		}
		
		private function exitCaptureMode(): void
		{
			GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20), "Exiting capture mode!", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 1000);
			this.captureCorners[0] = null;
			this.captureCorners[1] = null;
			this.captureMode = false;
			crosshair.graphics.clear();
		}
		
		public function eh_ingamePreRenderInfoPanel(e:Object): void
		{
			cleanupRetinaHud();
			for each (var bitmapType:Object in this.activeBitmaps)
			{
				bitmapType.occupied = 0;
			}
			this.activeWallHelpers.occupied = 0;
			
			if (this.buildingMode)
			{
				if (this.currentBlueprintIndex == -1)
				{
					exitBuildingMode();
					return;
				}
				drawBuildingOverlay();
				return;
			}
		}
		
		private function drawBuildingOverlay(): void
		{
			GV.main.cntInfoPanel.removeChild(GV.mcInfoPanel);
			
			var mouseX:Number = GV.ingameCore.cnt.root.mouseX;
			var mouseY:Number  = GV.ingameCore.cnt.root.mouseY;
			if (GV.main.cntScreens.cntIngame.root.mouseX < 50 || GV.main.cntScreens.cntIngame.root.mouseX > 50 + 1680 || GV.main.cntScreens.cntIngame.root.mouseY < 8 || GV.main.cntScreens.cntIngame.root.mouseY > 8 + 1064)
			{
				return;
			}
                
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			GV.ingameCore.lastZoneXMin = 50 + 28 * vX;
			GV.ingameCore.lastZoneXMax = 50 + 28 + 28 * vX;
			GV.ingameCore.lastZoneYMin = 8 + 28 * vY;
			GV.ingameCore.lastZoneYMax = 8 + 28 + 28 * vY;
			
			var rHUD:SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
			if(!rHUD.contains(GV.ingameCore.cnt.bmpWallPlaceAvailMap))
                rHUD.addChild(GV.ingameCore.cnt.bmpWallPlaceAvailMap);
			//if(!rHUD.contains(GV.ingameCore.cnt.bmpTowerPlaceAvailMap))
			//	rHUD.addChild(GV.ingameCore.cnt.bmpTowerPlaceAvailMap);
			if(!rHUD.contains(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap))
				rHUD.addChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
			
			//ManaMasonMod.logger.log("eh_ingamePreRender", "Working ");
			for each(var structure:Structure in this.selectedBlueprint.updateStructureCoords(mouseX, mouseY))
			{
				if (structure.fitsOnScene() && structure.type != "-" && !structure.rendered && GV.ingameCore.arrIsSpellBtnVisible[structure.spellButtonIndex])
				{
					if (structure.type == "w")
					{
						if (activeWallHelpers.occupied >= activeWallHelpers.movieClips.length)
						{
							var mcbwh:Class = Object(GV.ingameCore.cnt.mcBuildHelperWallLine).constructor;
							activeWallHelpers.movieClips.push(new mcbwh());
						}
						activeWallHelpers.movieClips[activeWallHelpers.occupied].x = structure.buildingX;
						activeWallHelpers.movieClips[activeWallHelpers.occupied].y = structure.buildingY;
						activeWallHelpers.movieClips[activeWallHelpers.occupied].rotation = 0;
						activeWallHelpers.movieClips[activeWallHelpers.occupied].gotoAndStop(1);
						activeWallHelpers.occupied++;
					}
					else
					{
						var typeBitmaps:Object = this.activeBitmaps[structure.type];
						if (typeBitmaps.occupied >= typeBitmaps.bitmaps.length)
						{
							typeBitmaps.bitmaps.push(new Bitmap(BuildHelper.bitmaps[structure.type].bitmapData));
						}
						typeBitmaps.bitmaps[typeBitmaps.occupied].x = structure.buildingX;
						typeBitmaps.bitmaps[typeBitmaps.occupied].y = structure.buildingY;
						typeBitmaps.occupied++;
					}
					structure.rendered = true;
				}
			}
			
			for each (var type:Object in this.activeBitmaps)
			{
				for (var i:int = 0; i < type.occupied; i++)
				{
					rHUD.addChild(type.bitmaps[i]);
				}
			}
			
			for (var wmci:int = 0; wmci < this.activeWallHelpers.occupied; wmci++)
			{
				rHUD.addChild(this.activeWallHelpers.movieClips[wmci]);
			}
		}
		
		private function drawCaptureOverlay(e: MouseEvent): void
		{
			if (this.captureMode)
			{
				var rHUD: SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
				crosshair.graphics.clear();
				crosshair.graphics.lineStyle(2, 0x00FF00, 1);
				if(this.captureCorners[0] == null) {
					crosshair.graphics.moveTo(0, GV.main.cntScreens.cntIngame.root.mouseY);
					crosshair.graphics.lineTo(1680, GV.main.cntScreens.cntIngame.root.mouseY);
					crosshair.graphics.moveTo(GV.main.cntScreens.cntIngame.root.mouseX, 0);
					crosshair.graphics.lineTo(GV.main.cntScreens.cntIngame.root.mouseX, 1064);
				}
				else if (this.captureCorners[1] == null)
				{
					crosshair.graphics.moveTo(50 + 28 * (this.captureCorners[0][0]), 8 + 28 * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(50 + 28 * (this.captureCorners[0][0]), GV.main.cntScreens.cntIngame.root.mouseY);
					crosshair.graphics.lineTo(GV.main.cntScreens.cntIngame.root.mouseX, GV.main.cntScreens.cntIngame.root.mouseY);
					crosshair.graphics.lineTo(GV.main.cntScreens.cntIngame.root.mouseX, 8 + 28 * (this.captureCorners[0][1]));
					crosshair.graphics.lineTo(50 + 28 * (this.captureCorners[0][0]), 8 + 28 * (this.captureCorners[0][1]));
				}
				rHUD.addChild(crosshair);
			}
		}
		
		private function cleanupRetinaHud(): void
		{
			var rHUD: SpriteExt = GV.ingameCore.cnt.cntRetinaHud;
			//ManaMasonMod.logger.log("cleanupRetinaHud", "Cleaning up...");
			for each (var bitmapType: Object in this.activeBitmaps)
			{
				for each (var bitmap: Bitmap in bitmapType.bitmaps)
				{
					rHUD.removeChild(bitmap);
				}
			}
			
			for each (var wallMC: MovieClip in this.activeWallHelpers.movieClips)
			{
				rHUD.removeChild(wallMC);
			}
			
			for each(var baseBitmap: Bitmap in BuildHelper.bitmaps)
			{
				rHUD.removeChild(baseBitmap);
			}
			//GV.ingameCore.controller.deselectEverything(true,true);
		}
		
		private function exitBuildingMode(): void
		{
			var rHUD:Object = GV.ingameCore.cnt.cntRetinaHud;
			rHUD.removeChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
			rHUD.removeChild(GV.ingameCore.cnt.bmpWallPlaceAvailMap);
			cleanupRetinaHud();
			this.buildingMode = false;
		}
	}

}