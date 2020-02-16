package BuildingBlueprints 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import flash.filesystem.*;
	import flash.display.Bitmap;
	import BuildingBlueprints.BuildHelper;
	
	public class Blueprint 
	{
		private var structureGrid:Array;
		public var structures:Array;
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
		}
		
		public static function fromFile(filePath:String): Blueprint
		{
			var res:Blueprint = new Blueprint();
			var stream:FileStream = new FileStream();
			try
			{
				stream.open(new File(filePath), FileMode.READ);
				var recipe:String = stream.readUTFBytes(stream.bytesAvailable);
				//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Recipe: " + recipe);
				var rows:Array = recipe.split("\r\n");
				//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Split into " + rows.length + " rows");
				
				for (var c:int = 0; c < rows[0].length; c++)
				{
					for (var r:int = 0; r < rows.length; r++)
					{
						var char:String = rows[r].charAt(c);
						//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Row\t" + rows[r] + "; Looking at symbol " + r + ";" + c + " : " + char);
						if (allowedSymbols.indexOf(char) != -1)
						{
							//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Setting " + char);
							//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Pushing a new structure " + char + " at " + r + ";" + c);
							res.setStructureGridSlot(c, r, new Structure(char, c, r));
						}
						//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Done processing symbol: " + r + ";" + c);
					}
				}
				return res;
			}
			catch (e:Error)
			{
				BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Caught an error when trying to load " + filePath);
				BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", e.message);
				BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", e.getStackTrace());
			}
			return emptyBlueprint;
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
			//BuildingBlueprints.BuildingBlueprints.logger.log("setStructureGridSlot", "Pushed a new structure " + value.toString());
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
			//BuildingBlueprints.BuildingBlueprints.logger.log("updateStructureCoords", "Updating...");
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
				//BuildingBlueprints.BuildingBlueprints.logger.log("flipHorizontal", "Flipping..." + struct.toString());
				struct.flipHorizontal(this.structureGrid[0].length);
				//BuildingBlueprints.BuildingBlueprints.logger.log("flipHorizontal", "Flipped..." + struct.toString());
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
				//BuildingBlueprints.BuildingBlueprints.logger.log("flipVertical", "Flipping..." + struct.toString());
				struct.flipVertical(this.structureGrid.length);
				//BuildingBlueprints.BuildingBlueprints.logger.log("flipVertical", "Flipped..." + struct.toString());
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
		
		public function castBuild(): void
		{
			for each (var str:Structure in this.structures)
			{
				if(str.fitsOnScene())
					str.castBuild();
			}
			var core:Object = BuildingBlueprints.BuildingBlueprints.bezel.gameObjects.GV.ingameCore;
			core.renderer2.redrawHighBuildings();
			core.renderer2.redrawWalls();
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