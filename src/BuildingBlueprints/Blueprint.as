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
		private static var buildHelperBitmaps:Object;
		private static var allowedSymbols:Array = ["a", "t", "w", "p", "l", "r"];
		
		private static var _emptyBlueprint:Blueprint;
		public static function get emptyBlueprint():Blueprint 
		{
			return _emptyBlueprint || new Blueprint();
		}
		
		public var name:String;
		
		public function Blueprint() 
		{
			this.structureGrid = new Array();
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
				var rows:Array = recipe.split("\n");
				//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Split into " + rows.length + " rows");
				
				for (var c:int = 0; c <= rows[0].length; c++)
				{
					for (var r:int = 0; r < rows.length; r++)
					{
						//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Row" + rows[r] + "; Looking at symbol " + r + ";" + c + " : " + rows[r].charAt(c));
						if (rows[r].charAt(c) == "-" || rows[r].charAt(c) == " ")
						{
							//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Setting air");
							res.setStructureGridSlot(c, r, new Structure("air", c, r));
						}
						else if (allowedSymbols.indexOf(rows[r].charAt(c)) != -1)
						{
							//BuildingBlueprints.BuildingBlueprints.logger.log("fromFile", "Setting " + rows[r].charAt(c));
							res.setStructureGridSlot(c, r, new Structure(rows[r].charAt(c), c, r));
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
			for (var w:int = 0; w < value.size.width; w++)
			{
				for (var h:int = 0; h < value.size.height; h++)
				{
					while (this.structureGrid[row+h] == null)
					{
						this.structureGrid.push(new Array());
					}
					while (this.structureGrid[row+h][column+w] == null)
					{
						this.structureGrid[row+h].push(new Object());
					}
				
					if (this.structureGrid[row + h][column + w] is Structure)
					{
						return;
					}
					else
					{
						this.structureGrid[row + h][column + w] = value;
					}
				}
			}
			
			
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
			for each (var row:Array in this.structureGrid)
			{
				for each(var element:Structure in row)
				{
					element.setBuildingCoords(mouseX, mouseY);
					element.processed = false;
				}
			}
			
			return this.structureGrid;
		}
	}

}