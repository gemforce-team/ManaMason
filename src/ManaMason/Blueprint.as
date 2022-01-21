package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Orblet;
	 
	import ManaMason.Structures.Pylon;
	import flash.filesystem.*;
	
	public class Blueprint 
	{
		private var structureGrid:Array;
		public var structures:Array;
		public var gemTemplates:Object;
		private static var buildHelperBitmaps:Object;
		private static var allowedSymbols:Array = ["-", "a", "t", "w", "p", "l", "r"];
		
		private static var _emptyBlueprint:Blueprint;
		public static function get emptyBlueprint():Blueprint 
		{
			return _emptyBlueprint || new Blueprint();
		}
		
		public var name:String;
		
		public function Blueprint() 
		{
			this.structureGrid = new Array();
			this.structures = new Array();
			this.gemTemplates = new Object();
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
			
			if (parts.length > 1)
				parseGemTemplates(parts[1].split(File.lineEnding), result);
		
			parseBlueprintGrid(grid, result);
			result.name = bpName;
			return result;
		}
		
		private static function parseBlueprintGrid(grid:Array, res:Blueprint): Blueprint
		{
			for (var c:int = 0; c < grid[0].length; c++)
			{
				for (var r:int = 0; r < grid.length; r++)
				{
					var char:String = grid[r].charAt(c);
					//ManaMasonMod.logger.log("fromFile", "Row\t" + rows[r] + "; Looking at symbol " + r + ";" + c + " : " + char);
					if (allowedSymbols.indexOf(char) != -1)
					{
						if (res.structureGrid[c] != undefined)
						{
							if (res.structureGrid[c][r] != undefined)
								continue;
						}
						//ManaMasonMod.logger.log("fromFile", "Setting " + char);
						//ManaMasonMod.logger.log("fromFile", "Pushing a new structure " + char + " at " + r + ";" + c);
						var structure:Structure = StructureFactory.CreateStructure(char, c, r);
						res.setStructureGridSlot(c, r, structure);
						if (structure.size == 2)
						{
							if (grid[r + 1] != undefined)
							{
								var gemIdString:String = grid[r + 1].charAt(c) + grid[r + 1].charAt(c + 1);
								var gemId:int = parseInt(gemIdString);
								if (!isNaN(gemId))
								{
									if (structure.type == "p")
									{
										var pylon:Pylon = structure as Pylon;
										pylon.targetPriority = gemId;
									}
									else
										structure.gemTemplate = res.gemTemplates[gemId] || null;
								}
							}
						}
					}
					//ManaMason.ManaMason.logger.log("fromFile", "Done processing symbol: " + r + ";" + c);
				}
			}
			return res;
		}
		
		private static function parseGemTemplates(lines:Array, res:Blueprint): Blueprint
		{
			for each(var template:String in lines)
			{
				if (template.length < 3)
					continue;
				var gem:FakeGem = new FakeGem(-1, 0);
				var parts:Array = template.split("=");
				var gemId:int = parseInt(parts[0]);
				if (isNaN(gemId))
					continue;
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
		
		private function setStructureGridSlot(row:int, column:int, value:Structure): void
		{
			if (this.structureGrid[row] == undefined)
				this.structureGrid[row] = new Array();
				
			if (this.structureGrid[row][column] == undefined)
			{
				this.structureGrid[row][column] = value;
				this.structures.push(value);
			}
			else
				return;
			
			if (value.size == 2)
			{
				this.structureGrid[row][column+1] = value;
				if (this.structureGrid[row+1] == undefined)
					this.structureGrid[row+1] = new Array();
				this.structureGrid[row+1][column] = value;
				this.structureGrid[row+1][column+1] = value;
			}
			//ManaMasonMod.logger.log("setStructureGridSlot", "Pushed a new structure " + value.toString());
		}
		
		private static function createTestBlueprint(): Blueprint
		{
			var res:Blueprint = new Blueprint();
			res.structureGrid = new Array();
			var amp1:Structure = new Structure("a", 0, 2);
			var amp2:Structure = new Structure("a", 2, 0);
			var amp3:Structure = new Structure("a", 2, 4);
			var amp4:Structure = new Structure("a", 4, 2);
			var tow1:Structure = new Structure("t", 2, 2);
			var walls:Array = new Array();
			walls.push(new Structure("w", 2, 0));
			walls.push(new Structure("w", 2, 1));
			walls.push(new Structure("w", 2, 2));
			walls.push(new Structure("w", 4, 4));
			walls.push(new Structure("w", 4, 8));
			walls.push(new Structure("w", 5, 4));
			walls.push(new Structure("w", 5, 8));
			var air:Structure = new Structure("air", 0, 0);
			/*res.structureGrid.push(new Array(air, air, air, air, air, amp1, amp1, air, air));
			res.structureGrid.push(new Array(air, air, air, air, air, amp1, amp1, air, air));
			res.structureGrid.push(new Array(walls[0], walls[1], walls[2], amp2, amp2, tow1, tow1, amp3, amp3));
			res.structureGrid.push(new Array(air, air, air, amp2, amp2, tow1, tow1, amp3, amp3));
			res.structureGrid.push(new Array(air, air, air, air, walls[3], amp4, amp4, air, walls[4]));
			res.structureGrid.push(new Array(air, air, air, air, walls[5], amp4, amp4, air, walls[6]));*/
			
			res.structureGrid.push(new Array(air, air, amp1, amp1, air, air));
			res.structureGrid.push(new Array(air, air, amp1, amp1, air, air));
			res.structureGrid.push(new Array(amp2, amp2, tow1, tow1, amp3, amp3));
			res.structureGrid.push(new Array(amp2, amp2, tow1, tow1, amp3, amp3));
			res.structureGrid.push(new Array(air, air, amp4, amp4, air, air));
			res.structureGrid.push(new Array(air, air, amp4, amp4, air, air));
			
			return res;
		}
		
		public function updateStructureCoords(mouseX:Number, mouseY:Number): Array
		{
			//ManaMason.ManaMason.logger.log("updateStructureCoords", "Updating...");
			for each(var element:Structure in this.structures)
			{
				element.setBuildingCoords(mouseX, mouseY);
				element.rendered = false;
			}
		
			return this.structures;
		}
		
		public function flipHorizontal(): void
		{
			for each (var struct:Structure in this.structures)
			{
				//ManaMason.ManaMason.logger.log("flipHorizontal", "Flipping..." + struct.toString());
				struct.flipHorizontal(this.structureGrid.length);
				//ManaMason.ManaMason.logger.log("flipHorizontal", "Flipped..." + struct.toString());
			}
			for each (var row:Array in this.structureGrid)
			{
				row.reverse();
			}
		}
		
		public function flipVertical(): void
		{
			for each (var struct:Structure in this.structures)
			{
				//ManaMason.ManaMason.logger.log("flipVertical", "Flipping..." + struct.toString());
				struct.flipVertical(this.structureGrid[0].length);
				//ManaMason.ManaMason.logger.log("flipVertical", "Flipped..." + struct.toString());
			}
			this.structureGrid.reverse();
		}
		
		public function rotate(): void
		{
			for each (var struct:Structure in this.structures)
				struct.transpose();
			var newGrid:Array = new Array();
			for (var row:int = 0; row < this.structureGrid.length; row++)
			{
				for (var column:int = 0; column < this.structureGrid[row].length; column++)
				{
					if (newGrid[column] == undefined)
						newGrid.push(new Array());
					newGrid[column][row] = this.structureGrid[row][column];
				}
			}
			this.structureGrid = newGrid;
			flipVertical();
		}
		
		public function castBuild(bpo:BlueprintOptions): void
		{
			var options:Object = bpo.optionsObject;
			for each (var str:Structure in this.structures)
			{
				if (str.type == "-" ||
					(str.type == "t" && !options["Place Towers"]) ||
					(str.type == "w" && !options["Place Walls"]) ||
					(str.type == "p" && !options["Place Pylons"]) ||
					(str.type == "r" && !options["Place Traps"]) ||
					(str.type == "l" && !options["Place Lanterns"]) ||
					(str.type == "a" && !options["Place Amplifiers"]))
				{
					continue;
				}
				if (str.fitsOnScene() && GV.ingameCore.arrIsSpellBtnVisible[str.spellButtonIndex])
				{
					str.castBuild(options["Build on Path"], options["Conjure Gems"]);
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
		
		public function toString(): String
		{
			var res:String = "";
			for each (var row:Array in this.structureGrid)
			{
				res += "\n";
				for each (var str:Structure in row)
				{
					res += str.type;
				}
			}
			return res;
		}
	}

}
