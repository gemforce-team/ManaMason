package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.filesystem.*;
	import flash.events.*;
	import flash.globalization.LocaleID;
	import flash.utils.*;
	
	public class ManaMason extends MovieClip
	{
		public const VERSION:String = "1.0";
		public const GAME_VERSION:String = "1.0.20c";
		public const BEZEL_VERSION:String = "0.1.0";
		public const MOD_NAME:String = "BuildingBlueprints";
		
		internal  var gameObjects:Object;
		
		// Game object shortcuts
		internal var core:Object;/*IngameCore*/
		internal var cnt:Object;/*CntIngame*/
		internal var GV:Object;/*GV*/
		internal var SB:Object;/*SB*/
		internal var prefs:Object;/*Prefs*/
		
		// Mod loader object
		internal static var bezel:Object;
		internal static var logger:Object;
		internal static var storage:File;
		
		private var blueprints:Array;
		private var activeBitmaps:Object;
		private var activeWallHelpers:Object;
		private var selectedBlueprint:Blueprint;
		private var currentBlueprintIndex:int;
		
		private var buildingMode:Boolean;
		
		public function ManaMason() 
		{
			super();
		}
		
		public function bind(modLoader:Object, gameObjects:Object): ManaMason
		{
			bezel = modLoader;
			logger = bezel.getLogger("BuildingBlueprints");
			this.gameObjects = gameObjects;
			this.core = gameObjects.GV.ingameCore;
			this.cnt = gameObjects.GV.main.cntScreens.cntIngame;
			this.SB = gameObjects.SB;
			this.GV = gameObjects.GV;
			this.prefs = gameObjects.prefs;
			storage = File.applicationStorageDirectory.resolvePath("Building Blueprints");
			
			this.blueprints = new Array();
			initActiveBitmaps();
			
			initBuildingHelpers();
			
			prepareFolders();
			
			this.blueprints = formBlueprintList();
			
			addEventListeners();
			
			logger.log("bind", "BuildingBlueprints initialized!");
			return this;
		}
		
		private function initBuildingHelpers(): void
		{
			BuildHelper.bitmaps = new Object();
			var buildHelperBitmaps:Object = BuildHelper.bitmaps;
			buildHelperBitmaps["a"] = this.core.cnt.bmpBuildHelperAmp;
			buildHelperBitmaps["t"] = this.core.cnt.bmpBuildHelperTower;
			buildHelperBitmaps["r"] = this.core.cnt.bmpBuildHelperTrap;
			buildHelperBitmaps["p"] = this.core.cnt.bmpBuildHelperPylon;
			buildHelperBitmaps["l"] = this.core.cnt.bmpBuildHelperLantern;
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
		
		public function prettyVersion(): String
		{
			return 'v' + VERSION + ' for ' + GAME_VERSION;
		}
		
		private function formBlueprintList(): Array
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
			
			logger.log("formBlueprintList", "Found " + newBlueprints.length + " blueprint files.");
			
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
			return newBlueprints;
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
			storage = File.applicationStorageDirectory.resolvePath("Building Blueprints");
			if (!storage.isDirectory)
			{
				storage.createDirectory();
			}
			
			var blueprintsFolder:File = storage.resolvePath("blueprints");
			if (!blueprintsFolder.isDirectory)
			{
				blueprintsFolder.createDirectory();
			}
		}
		
		private function addEventListeners(): void
		{
			bezel.addEventListener("ingamePreRenderInfoPanel", eh_ingamePreRenderInfoPanel);
			bezel.addEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			bezel.addEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			bezel.addEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
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
			bezel.removeEventListener("ingamePreRenderInfoPanel", eh_ingamePreRenderInfoPanel);
			bezel.removeEventListener("ingameKeyDown", eh_interceptKeyboardEvent);
			bezel.removeEventListener("ingameClickOnScene", eh_ingameClickOnScene);
			bezel.removeEventListener("ingameRightClickOnScene", eh_ingameRightClickOnScene);
		}
		
		public function eh_interceptKeyboardEvent(e:Object): void
		{
			var pE:KeyboardEvent = e.eventArgs.event;

			if (pE.keyCode == 45)
			{
				if (this.buildingMode)
				{
					this.buildingMode = !this.buildingMode;
					exitBuildingMode();
					eh_ingamePreRenderInfoPanel(null);
				}
				else
				{
					//logger.log("eh_intercept", "Building mode is now:" + this.buildingMode);
					this.core.controller.deselectEverything(true,true);
					this.buildingMode = true;
					eh_ingamePreRenderInfoPanel(null);
				}
			}
			
			if (this.buildingMode)
			{
				if (pE.keyCode == 33)
				{
					cycleSelectedBlueprint(-1);
				}
				else if (pE.keyCode == 34)
				{
					cycleSelectedBlueprint(1);
				}
				else if (pE.keyCode == 86)
				{
					this.selectedBlueprint.flipVertical();
					this.eh_ingamePreRenderInfoPanel(null);
				}
				else if (pE.keyCode == 70)
				{
					this.selectedBlueprint.flipHorizontal();
					this.eh_ingamePreRenderInfoPanel(null);
				}
				else if (pE.keyCode == 82)
				{
					this.selectedBlueprint.rotate();
					this.eh_ingamePreRenderInfoPanel(null);
				}
			}
			
			e.eventArgs.continueDefault = !this.buildingMode;
		}
		
		public function eh_ingameClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			
			if (this.buildingMode)
			{
				//logger.log("eh_ingameClickOnScene", "Got a leftclick");
				this.selectedBlueprint.castBuild();
				e.eventArgs.continueDefault = false;	
			}
			
		}
		
		public function eh_ingameRightClickOnScene(e:Object): void
		{
			var mE:MouseEvent = e.eventArgs.event as MouseEvent;
			if (this.buildingMode)
			{
				exitBuildingMode();
				this.buildingMode = false;
			}
		}
		
		public function eh_ingamePreRenderInfoPanel(e:Object): void
		{
			cleanupRetinaHud();
			for each (var bitmapType:Object in this.activeBitmaps)
			{
				bitmapType.occupied = 0;
			}
			this.activeWallHelpers.occupied = 0;
			if (!this.buildingMode)
			{
				return;
			}
			
			this.GV.main.cntInfoPanel.removeChild(this.GV.mcInfoPanel);
			
			var mouseX:Number = this.core.cnt.root.mouseX;
			var mouseY:Number  = this.core.cnt.root.mouseY;
			if (this.cnt.root.mouseX < 50 || this.cnt.root.mouseX > 50 + 1680 || this.cnt.root.mouseY < 8 || this.cnt.root.mouseY > 8 + 1064)
			{
				return;
			}
                
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			this.core.lastZoneXMin = 50 + 28 * vX;
			this.core.lastZoneXMax = 50 + 28 + 28 * vX;
			this.core.lastZoneYMin = 8 + 28 * vY;
			this.core.lastZoneYMax = 8 + 28 + 28 * vY;
			
			var rHUD:Object = this.core.cnt.cntRetinaHud;
			if(!rHUD.contains(this.core.cnt.bmpWallPlaceAvailMap))
                rHUD.addChild(this.core.cnt.bmpWallPlaceAvailMap);
			//if(!rHUD.contains(this.core.cnt.bmpTowerPlaceAvailMap))
			//	rHUD.addChild(this.core.cnt.bmpTowerPlaceAvailMap);
			if(rHUD.contains(this.core.cnt.bmpNoPlaceBeaconAvailMap))
				rHUD.addChild(this.core.cnt.bmpNoPlaceBeaconAvailMap);
			
			//logger.log("eh_ingamePreRender", "Working ");
			for each(var structure:Structure in this.selectedBlueprint.updateStructureCoords(mouseX, mouseY))
			{
				if (structure.fitsOnScene() && structure.type != "-" && !structure.rendered)
				{
					if (structure.type == "w")
					{
						if (activeWallHelpers.occupied >= activeWallHelpers.movieClips.length)
						{
							var mcbwh:Class = Object(this.core.cnt.mcBuildHelperWallLine).constructor;
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
		
		private function cleanupRetinaHud(): void
		{
			var rHUD:Object = this.core.cnt.cntRetinaHud;
			//logger.log("cleanupRetinaHud", "Cleaning up...");
			for each (var bitmapType:Object in this.activeBitmaps)
			{
				for each (var bitmap:Object in bitmapType.bitmaps)
				{
					rHUD.removeChild(bitmap);
				}
			}
			
			for each (var wallMC:Object in this.activeWallHelpers.movieClips)
			{
				rHUD.removeChild(wallMC);
			}
			
			for each(var baseBitmap:Object in BuildHelper.bitmaps)
			{
				rHUD.removeChild(baseBitmap);
			}
			//this.core.controller.deselectEverything(true,true);
		}
		
		private function exitBuildingMode(): void
		{
			var rHUD:Object = this.core.cnt.cntRetinaHud;
			//rHUD.removeChild(this.core.cnt.bmpTowerPlaceAvailMap);
			rHUD.removeChild(this.core.cnt.bmpNoPlaceBeaconAvailMap);
			rHUD.removeChild(this.core.cnt.bmpWallPlaceAvailMap);
			cleanupRetinaHud();
		}
		
		private function test(): void
		{
					
			//this.buildingSprites.push(new Bitmap(this.cnt.bmpBuildHelperAmp.bitmapData));
		}
	}

}