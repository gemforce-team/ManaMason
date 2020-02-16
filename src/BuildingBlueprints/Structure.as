package BuildingBlueprints 
{
	import adobe.utils.CustomActions;
	import flash.display.Bitmap;
	/**
	 * ...
	 * @author Hellrage
	 */
	
	
	
	public class Structure 
	{
		public var type:String;
		
		private var blueprintIndexX:int;
		private var blueprintIndexY:int;
		
		public var buildingGridX:int;
		public var buildingGridY:int;
		
		public var buildingX:Number;
		public var buildingY:Number;
		
		public var rendered:Boolean;
		public var size:int;
		private var xOffset:int;
		private var yOffset:int;
		public var buildingType:String;
		
		public function Structure(type:String, bpIX:int, bpIY:int) 
		{
			var BUILDING_TYPE:Object = BuildingBlueprints.BuildingBlueprints.bezel.gameObjects.constants.buildingType;
			this.type = type;
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			this.rendered = (type == "-");
			if (this.type == "w") 
			{
				this.size = 1;
				this.buildingType = BUILDING_TYPE.WALL;
				xOffset = 0;
				yOffset = 0;
			}
			else if (this.type == "-")
			{
				this.size = 1;
				this.buildingType = "AIR";
			}
			else 
			{
				this.size = 2;
				xOffset = -4;
				yOffset = -5;
				
				if (this.type == "r")
				{
					this.buildingType = BUILDING_TYPE.TRAP;
					xOffset = 4;
					yOffset = 4;
				}
				else if (this.type == "t")
				{
					this.buildingType = BUILDING_TYPE.TOWER;
				}
				else if (this.type == "l")
				{
					this.buildingType = BUILDING_TYPE.LANTERN;
				}
				else if (this.type == "p")
				{
					this.buildingType = BUILDING_TYPE.PYLON;
				}
				else if (this.type == "a")
				{
					this.buildingType = BUILDING_TYPE.AMPLIFIER;
				}
			}
		}
		
		public function fitsOnScene(): Boolean
		{
			return (this.buildingX <= 50 + 1680 - 28*this.size) && (this.buildingX >= 50 + this.xOffset) && (this.buildingY <= 8 + 1064 - 28*this.size) && (this.buildingY >= 8 + this.yOffset);
		}
		
		public function setBuildingCoords(mouseX:Number, mouseY:Number): void
		{
			var vX:Number = Math.floor((mouseX - 50) / 28);
			var vY:Number = Math.floor((mouseY - 8) / 28);
			
			this.buildingGridX = Math.max(0,Math.floor((mouseX - 50) / 28)) + this.blueprintIndexX;
			this.buildingGridY = Math.max(0, Math.floor((mouseY - 8) / 28)) + this.blueprintIndexY;
			
			this.buildingX = 50 + 28 * this.buildingGridX + xOffset;
			this.buildingY = 8 + 28 * this.buildingGridY + yOffset;
		}
		
		public function flipHorizontal(rowLength:int): void
		{
			this.blueprintIndexX = rowLength - 1 - this.blueprintIndexX - (this.size - 1);
		}
		
		public function flipVertical(rowCount:int): void
		{
			this.blueprintIndexY = rowCount - 1 - this.blueprintIndexY - (this.size -1);
		}
		
		public function transpose(): void
		{
			var temp:int = this.blueprintIndexX;
			this.blueprintIndexX = this.blueprintIndexY;
			this.blueprintIndexY = temp;
		}
		
		public function castBuild(): void
		{
			if (this.type == "-" || this.type == "w")
				return;
				
			var core:Object = BuildingBlueprints.BuildingBlueprints.bezel.gameObjects.GV.ingameCore;
			if (core.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (this.type == "r")
				{
					if (core.buildingAreaMatrix[buildingGridY][buildingGridX] == null
						&& core.groundMatrix[buildingGridY][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY][buildingGridX + 1] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX + 1] == "#")
					core.creator.buildTrap(buildingGridX, buildingGridY);
				}
				else
				if (!core.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY))
				{
					switch (this.type) 
					{
						case "t":
							core.creator.buildTower(buildingGridX, buildingGridY);
							break;
						case "a":
							core.creator.buildAmplifier(buildingGridX, buildingGridY);
							break;
						case "p":
							core.creator.buildPylon(buildingGridX, buildingGridY);
							break;
						case "l":
							core.creator.buildLantern(buildingGridX, buildingGridY);
							break;
						default:
					}
				}
			}
		}
		
		public function toString(): String
		{
			return this.type + "(" + this.blueprintIndexX+";"+this.blueprintIndexY+ ") at " + this.buildingX + ";" + this.buildingY;
		}
	}

}