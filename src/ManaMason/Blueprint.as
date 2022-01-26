package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.BlueprintOptions;
	import ManaMason.Structures.PylonStruct;
	import ManaMason.Utils.BlueprintOption;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.Orblet;
	import com.giab.games.gcfw.mcDyn.McBuildWallHelper;
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.filesystem.*;
	import flash.geom.ColorTransform;
	
	public class Blueprint extends MovieClip
	{
		private var blueprintOptions: BlueprintOptions;
		private var lastOrigin: Object;
		
		private static var redColor:ColorTransform = new ColorTransform(1, 0, 0);
		private static var whiteColor:ColorTransform = new ColorTransform(1, 1, 1);
		
		public var structures:Array;
		public var gemTemplates:Object;
		public var dimX:Number;
		public var dimY:Number;
		
		private static var activeBitmaps:Object;
		private static var activeWallHelpers:Object;
		private static var buildHelperBitmaps:Object;
		private static var allowedSymbols:Array = ["a", "t", "w", "p", "l", "r"];
		
		private static var _emptyBlueprint:Blueprint;
		public static function get emptyBlueprint():Blueprint 
		{
			return _emptyBlueprint || new Blueprint();
		}
		
		public var blueprintName:String;
		
		public function Blueprint() 
		{
			super();
			
			if (activeBitmaps == null)
				initActiveBitmaps();
			if(buildHelperBitmaps == null)
				initBuildingHelpers();
				
			this.structures = new Array();
			this.blueprintName = "Empty BP";
			this.gemTemplates = new Object();
			this.lastOrigin = new Object();
			this.lastOrigin["xTile"] = 0;
			this.lastOrigin["yTile"] = 0;
			this.x = 0;
			this.y = 0;
		}
		
		public static function fromFile(filePath:String, fileName: String = "Unnamed.txt"): Blueprint
		{
			var stream:FileStream = new FileStream();
			try
			{
				stream.open(new File(filePath), FileMode.READ);
				var bpString:String = stream.readUTFBytes(stream.bytesAvailable);
				stream.close();
				return fromString(bpString, fileName.split(".")[0]);
			}
			catch (e:Error)
			{
				ManaMasonMod.logger.log("fromFile", "Caught an error when trying to load " + filePath);
				ManaMasonMod.logger.log("fromFile", e.message);
				ManaMasonMod.logger.log("fromFile", e.getStackTrace());
			}
			return emptyBlueprint;
		}
		
		public static function fromString(bpString: String, bpName: String): Blueprint
		{
			var result:Blueprint = new Blueprint();
			var parts:Array = bpString.split("Gems:"+File.lineEnding);
			var grid:Array = parts[0].split(File.lineEnding);
			for (var row: String in grid)
				grid[row] = grid[row].split("");
			
			if (parts.length > 1)
				parseGemTemplates(parts[1].split(File.lineEnding), result);
		
			parseBlueprintGrid(grid, result);
			result.blueprintName = bpName;
			return result;
		}
		
		public function setBlueprintOptions(bpo: BlueprintOptions): Blueprint
		{
			this.blueprintOptions = bpo;
			return this;
		}
		
		public function findDimensions(): void
		{
			var xMin:Number = BuildHelper.FIELD_WIDTH;
			var xMax:Number = 0;
			var yMin:Number = BuildHelper.FIELD_HEIGHT;
			var yMax:Number = 0;
			for each(var structure:Structure in this.structures)
			{
				xMin = Math.min(xMin, structure.blueprintIndexX);
				xMax = Math.max(xMax, structure.blueprintIndexX + structure.size);
				yMin = Math.min(yMin, structure.blueprintIndexY);
				yMax = Math.max(yMax, structure.blueprintIndexY + structure.size);
			}
			this.dimX = xMax - xMin;
			this.dimY = yMax - yMin;
			for each(structure in this.structures)
			{
				structure.blueprintIndexX -= xMin;
				structure.blueprintIndexY -= yMin;
			}
		}
		
		private static function parseBlueprintGrid(grid:Array, res:Blueprint): Blueprint
		{
			for (var r:int = 0; r < grid.length; r++)
			{
				for (var c:int = 0; c < grid[0].length; c++)
				{
					var char:String = grid[r][c];
					if (allowedSymbols.indexOf(char) != -1)
					{
						var structure:Structure = StructureFactory.CreateStructure(char, c, r);
						res.structures.push(structure);
						if (structure.size == 2)
						{
							if (grid[r + 1] != undefined)
							{
								var gemIdString:String = grid[r + 1][c] + grid[r + 1][c + 1];
								var gemId:int = parseInt(gemIdString);
								if (!isNaN(gemId))
								{
									if (structure.type == "p")
									{
										var pylon:PylonStruct = structure as PylonStruct;
										pylon.targetPriority = gemId;
									}
									else
									{
										structure.gemTemplate = res.gemTemplates[gemId];
										structure.gem = BuildHelper.CreateFakeGemFromTemplate(res.gemTemplates[gemId] || null);
										structure.fitGemGhostImage();
									}
								}
								grid[r + 1][c] = grid[r + 1][c + 1] = "-";
							}
							if(grid[r][c + 1] != undefined)
								grid[r][c + 1] = "-";
						}
					}
				}
			}
			res.findDimensions();
			return res;
		}
		
		private static function parseGemTemplates(lines:Array, res:Blueprint): Blueprint
		{
			for each(var template:String in lines)
			{
				if (template.length < 3)
					continue;
				var parts:Array = template.split("=");
				var gemId:int = parseInt(parts[0]);
				if (isNaN(gemId))
					continue;
				var gem:FakeGem = new FakeGem(parts[1], gemId, -1, 0);
				var props:Array = parts[1].split(",");
				res.gemTemplates[gemId] = applyProps(gem, props);
			}
			return res;
		}
		
		private static function applyProps(gem:FakeGem, props:Array): FakeGem
		{
			try
			{
				switch (props[0]) 
				{
					case "y":
					case "yellow":
						gem.gemType = 0;
						break;
					case "o":
					case "orange":
						gem.gemType = 1;
						break;
					case "r":
					case "red":
						gem.gemType = 2;
						break;
					case "p":
					case "purple":
						gem.gemType = 3;
						break;
					case "g":
					case "green":
						gem.gemType = 4;
						break;
					case "b":
					case "blue":
						gem.gemType = 5;
						break;
					case "inv":
					case "inventory":
						gem.gemType = -1;
						gem.fromInventory = true;
						setGemInventorySlot(gem, parseInt(props[1]));
						if (gem.inventorySlot == -1)
							return null;
						if(props.length >= 3)
							setGemTargetPriority(gem, parseInt(props[2]));
						if(props.length >= 4)
							setGemRange(gem, parseFloat(props[3]));
						return gem;
						break;
					default:
						return null;
				}
				
				if (props[1] == "gs" || props[1] == "gemsmith")
				{
					gem.usesGemsmith = true;
					gem.gemsmithRecipeName = props[2];
					setGemGrade(gem, parseInt(props[3]));
					if (isNaN(gem.gemGrade))
						return null;
					if (props.length >= 5)
						setGemTargetPriority(gem, parseInt(props[4]));
					if(props.length >= 6)
						setGemRange(gem, parseFloat(props[5]));
					return gem;
				}
				else
				{
					setGemGrade(gem, parseInt(props[1]));
					if (isNaN(gem.gemGrade))
						return null;
					if (props.length >= 3)
						setGemTargetPriority(gem, parseInt(props[2]));
					if(props.length >= 4)
						setGemRange(gem, parseFloat(props[3]));
					return gem;
				}
			}
			catch (e:Error)
			{
				ManaMasonMod.logger.log("applyProps", "Caught an error while parsing a gem's props!");
				ManaMasonMod.logger.log("applyProps", e.message);
				return null;
			}
			return null;
		}
		
		private static function setGemTargetPriority(gem:FakeGem, tpId:int): void
		{
			if (!isNaN(tpId) && tpId >= 0 && tpId <= 7)
				gem.targetPriority = tpId;
			else
				gem.targetPriority = 0;
		}
		
		private static function setGemInventorySlot(gem:FakeGem, slot:int): void
		{
			if (!isNaN(slot) && slot >= 0 && slot <= 8)
				gem.inventorySlot = slot;
			else
				gem.inventorySlot = -1;
		}
		
		private static function setGemGrade(gem:FakeGem, grade:int): void
		{
			if (!isNaN(grade) && grade >= 0)
				gem.gemGrade = grade;
			else
				gem.gemGrade = NaN;
		}
		
		private static function setGemRange(gem:FakeGem, rangeMulti:Number): void
		{
			if (!isNaN(rangeMulti) && rangeMulti >= 0.05 && rangeMulti <= 1)
			{
				//ManaMason.ManaMason.logger.log("applyProps", "Setting gem range multi to " + rangeMulti.toString());
				gem.rangeMultiplier = rangeMulti;
			}
		}
		
		public function updateInPlace(): void
		{
			updateStructures(this.lastOrigin.xTile, this.lastOrigin.yTile);
		}
		
		public function updateOrigin(mouseX:Number, mouseY:Number, force: Boolean = false): void
		{
			var fieldX:Number = Math.round((mouseX - BuildHelper.WAVESTONE_WIDTH) / BuildHelper.TILE_SIZE - this.dimX / 2);
			var fieldY:Number = Math.round((mouseY - BuildHelper.TOP_UI_HEIGHT) / BuildHelper.TILE_SIZE - this.dimY / 2);
			fieldX = Math.min(Math.max(fieldX, 0), BuildHelper.FIELD_WIDTH - this.dimX);
			fieldY = Math.min(Math.max(fieldY, 0), BuildHelper.FIELD_HEIGHT - this.dimY);
			if (this.lastOrigin.xTile != fieldX || this.lastOrigin.yTile != fieldY || force)
			{
				updateStructures(fieldX, fieldY);
			}
			this.lastOrigin.xTile = fieldX;
			this.lastOrigin.yTile = fieldY;
		}
		
		public function updateStructures(x:Number, y:Number): void
		{
			for each(var structure:Structure in this.structures)
			{
				structure.setBuildingCoords(x, y);
				
				if (!structure.fitsOnScene())
				{
					structure.ghost.visible = false;
					continue;
				}
				
				var placeable: Boolean = structure.placeable(blueprintOptions, false);
				
				if (!placeable)
				{
					if (!blueprintOptions.read(BlueprintOption.SHOW_UNPLACED))
					{
						structure.ghost.visible = false;
						continue;
					}
					structure.ghost.transform.colorTransform = redColor;
				}
				else
					structure.ghost.transform.colorTransform = new ColorTransform();
				
				structure.ghost.visible = true;
				if (structure.gem != null)
				{
					structure.gemGhost.visible = true;
					if (!blueprintOptions.read(BlueprintOption.CONJURE_GEMS))
					{
						if (blueprintOptions.read(BlueprintOption.SHOW_UNPLACED))
							structure.gemGhost.transform.colorTransform = redColor;
						else
							structure.gemGhost.visible = false;
						
					}
					else
						structure.gemGhost.transform.colorTransform = new ColorTransform();
				}
				
				structure.ghost.x = structure.buildingX;
				structure.ghost.y = structure.buildingY;
			}
		}
		
		public function flipHorizontal(): void
		{
			for each (var struct:Structure in this.structures)
			{
				struct.flipHorizontal(this.dimX);
			}
		}
		
		public function flipVertical(): void
		{
			for each (var struct:Structure in this.structures)
			{
				struct.flipVertical(this.dimY);
			}
		}
		
		public function rotate(): void
		{
			for each (var struct:Structure in this.structures)
			{
				struct.transpose();
				
			}
			var temp: Number = this.dimY;
			this.dimY = this.dimX;
			this.dimX = temp;
			flipVertical();
		}
		
		public function castBuild(options:BlueprintOptions): void
		{
			for each (var str:Structure in this.structures)
			{
				if (str.fitsOnScene() && GV.ingameCore.arrIsSpellBtnVisible[str.spellButtonIndex])
				{
					str.castBuild(options);
				}
			}
			GV.ingameCore.renderer2.redrawHighBuildings();
			GV.ingameCore.renderer2.redrawWalls();
			GV.ingameCore.resetAllPNNMatrices();
			var iLim:int = GV.ingameCore.monstersOnScene.length;
			for(var i:int = 0; i < iLim; i++)
			{
				if(GV.ingameCore.monstersOnScene[i] == null)
				{
					GV.ingameCore.monstersOnScene.splice(i,1);
					i--;
					iLim--;
				}
				else
				{
					GV.ingameCore.monstersOnScene[i].getNextPatrolSector();
				}
			}
			iLim = GV.ingameCore.orblets.length;
			for(i = 0; i < iLim; i++)
			{
				var orblet: Orblet = GV.ingameCore.orblets[i];
				if(orblet.status == Orblet.ST_DROPPED)
				{
					orblet.getNextPatrolSector();
				}
			}
		}
		
		public function resetGhosts(): void
		{
			this.removeChildren();
			
			for each (var bitmapType:Object in activeBitmaps)
			{
				bitmapType.occupied = 0;
			}
			activeWallHelpers.occupied = 0;
			
			for each(var structure:Structure in this.structures)
			{
				if (structure.type == "-")
					continue;
					
				structure.ghost.removeChildren();
					
				var placeable: Boolean = structure.placeable(blueprintOptions, false);
				if (structure.type == "w")
				{
					if (activeWallHelpers.occupied >= activeWallHelpers.movieClips.length)
					{
						activeWallHelpers.movieClips.push(new McBuildWallHelper());
					}
					structure.ghost.addChild(activeWallHelpers.movieClips[activeWallHelpers.occupied]);
					structure.ghost.x = structure.buildingX;
					structure.ghost.y = structure.buildingY;
					structure.ghost.rotation = 0;
					activeWallHelpers.movieClips[activeWallHelpers.occupied].gotoAndStop(1);
					activeWallHelpers.occupied++;
				}
				else
				{
					var typeBitmaps:Object = activeBitmaps[structure.type];
					if (typeBitmaps.occupied >= typeBitmaps.bitmaps.length)
					{
						typeBitmaps.bitmaps.push(new Bitmap(BuildHelper.bitmaps[structure.type].bitmapData));
					}
					structure.ghost.addChild(typeBitmaps.bitmaps[typeBitmaps.occupied]);
					if (structure.gem != null)
					{
						structure.fitGemGhostImage();
					}
					structure.ghost.x = structure.buildingX;
					structure.ghost.y = structure.buildingY;
					typeBitmaps.occupied++;
				}
				this.addChild(structure.ghost);
			}
		}
		
		public function cleanup(): void
		{
			for each(var struct: Structure in this.structures)
			{
				struct.gem = null;
			}
		}
		
		public function cleanupOnUnload(): void
		{
			for each(var struct: Structure in this.structures)
			{
				if(struct.gem != null)
					(Bitmap)(struct.gem.mc.getChildAt(0)).bitmapData = null;
			}
			
			if (activeWallHelpers != null)
			{
				for each (var mc: MovieClip in activeWallHelpers.movieClips)
				{
					mc.stop();
					mc = null;
				}
			}
			
			activeWallHelpers = {"occupied":0, "movieClips": new Array()};
			
			for each(var bmp: Bitmap in BuildHelper.bitmaps)
			{
				bmp = null;
			}
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
			activeBitmaps = new Object();
			activeBitmaps["a"] = {"occupied":0, "bitmaps": new Array()};
			activeBitmaps["t"] = {"occupied":0, "bitmaps": new Array()};
			activeBitmaps["r"] = {"occupied":0, "bitmaps": new Array()};
			activeBitmaps["p"] = {"occupied":0, "bitmaps": new Array()};
			activeBitmaps["l"] = {"occupied":0, "bitmaps": new Array()};
			
			activeWallHelpers = {"occupied":0, "movieClips": new Array()};
		}
		
		public static function tryCaptureFromField(captureCorners: Object): Blueprint
		{
			var grid:Object = GV.ingameCore.buildingAreaMatrix;
			var regGrid:Object = GV.ingameCore.buildingRegPtMatrix;
			var tileProcessed: Boolean = false;
			var bp: Blueprint = new Blueprint();
			bp.blueprintName = "Captured BP";
			for (var i:int = captureCorners[0][1]; i <= captureCorners[1][1]; i++) 
			{
				for (var j:int = captureCorners[0][0]; j <= captureCorners[1][0]; j++) 
				{
					tileProcessed = false;
					for (var type:String in ManaMasonMod.structureClasses)
					{
						if (grid[i][j] is ManaMasonMod.structureClasses[type] && regGrid[i][j] == grid[i][j])
						{
							var struct: Structure = StructureFactory.CreateStructure(type, j - captureCorners[0][0], i - captureCorners[0][1]);
							if (grid[i][j].hasOwnProperty("insertedGem") && grid[i][j].insertedGem != null)
							{
								var newGem: Gem =  GV.ingameSpellCaster.cloneGem(grid[i][j].insertedGem);
								newGem.manaLeeched = 0;
								newGem.kills.s(0);
								newGem.hits.s(0);
								newGem.recalculateSds();
								GV.gemBitmapCreator.giveGemBitmaps(newGem);
								GV.ingameCore.cnt.cntGemsInInventory.removeChild(newGem.mc);
								struct.gem = newGem;
							}
							bp.structures.push(struct);
							break;
						}
					}
				}
			}
			bp.findDimensions();
			exportBlueprintFile(bp);
			GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60?Number(GV.main.mouseY + 30):Number(GV.main.mouseY - 20), "Blueprint captured!", 16768392, 18, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 46, 0, 13);
			return bp;
		}
		
		private static function exportBlueprintFile(bp: Blueprint): void
		{
			var blueprintsFolder:File = ManaMasonMod.storage.resolvePath("blueprints");
			var bpFile:File = blueprintsFolder.resolvePath("Exported BP.txt");
			var bpWriter:FileStream = new FileStream();
			try
			{
				bpWriter.open(bpFile, FileMode.WRITE);
				bpWriter.writeUTFBytes(bp.exportToString());
			}
			catch (err:Error)
			{
				ManaMasonMod.logger.log("BPexport", "Error when exporting a BP!" + err.message);
			}
		}
		
		public function exportToString(): String
		{
			var res:String = "";
			var usedGems:Object = new Object();
			var gemId:int = 0;
			var grid: Object = new Object();
			for (var row: Number = 0; row < this.dimY; row++)
			{
				grid[row] = new Object();
				for (var c: Number = 0; c < this.dimX; c++)
					grid[row][c] = "-";
			}
			
			for each(var struct:Structure in this.structures) 
			{
				grid[struct.blueprintIndexY][struct.blueprintIndexX] = struct.type;
				if (struct.size == 2)
				{
					if (struct.gem != null && gemId <= 99)
					{
						var spec: String = struct.exportGemSpecToString();
						if (spec != null)
						{
							var usedId:int;
							if (usedGems[spec])
								usedId = (int)(usedGems[spec]);
							else
							{
								gemId++;
								usedGems[spec] = gemId;
								usedId = gemId;
							}
							grid[struct.blueprintIndexY + 1][struct.blueprintIndexX] = Math.floor(usedId / 10);
							grid[struct.blueprintIndexY + 1][struct.blueprintIndexX + 1] = usedId % 10;
						}
					}
				}
			}
			
			for (var i:Number = 0; i < this.dimY; i++) 
			{
				for (var j:Number = 0; j < this.dimX; j++) 
				{
					res += grid[i][j];
				}
				res += "\r\n";
			}
			if (gemId > 0)
			{
				res += "Gems:\r\n";
				for (var gem: String in usedGems)
				{
					var gemIdString:String = (int)(usedGems[gem]).toString();
					if (gemIdString.length == 1)
						res += 0;
					res += gemIdString + "=" + gem + "\r\n";
				}
			}
			return res;
		}
	}

}
