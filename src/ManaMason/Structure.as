package ManaMason 
{
	import adobe.utils.CustomActions;
	import flash.display.Bitmap;
	import flash.utils.*;
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
		public var spellButtonIndex:int;
		
		public function Structure(type:String, bpIX:int, bpIY:int) 
		{
			var BUILDING_TYPE:Object = ManaMason.ManaMason.bezel.gameObjects.constants.buildingType;
			this.type = type;
			this.blueprintIndexX = bpIX;
			this.blueprintIndexY = bpIY;
			this.rendered = (type == "-");
			if (this.type == "w") 
			{
				this.size = 1;
				this.buildingType = BUILDING_TYPE.WALL;
				this.spellButtonIndex = 12;
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
					this.spellButtonIndex = 15;
					xOffset = 4;
					yOffset = 4;
				}
				else if (this.type == "t")
				{
					this.buildingType = BUILDING_TYPE.TOWER;
					this.spellButtonIndex = 13;
				}
				else if (this.type == "l")
				{
					this.buildingType = BUILDING_TYPE.LANTERN;
					this.spellButtonIndex = 16;
				}
				else if (this.type == "p")
				{
					this.buildingType = BUILDING_TYPE.PYLON;
					this.spellButtonIndex = 17;
				}
				else if (this.type == "a")
				{
					this.buildingType = BUILDING_TYPE.AMPLIFIER;
					this.spellButtonIndex = 14;
				}
			}
		}
		
		public function fitsOnScene(): Boolean
		{
			return (this.buildingX <= 50 + 1680 - 28*this.size + this.xOffset) && (this.buildingX >= 50 + this.xOffset) && (this.buildingY <= 8 + 1064 - 28*this.size + this.yOffset) && (this.buildingY >= 8 + this.yOffset);
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
		
		public function castBuild(spendMana:Boolean = true, trackStats:Boolean = false): void
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			
			if (this.type == "-")
				return;
				
			if (spendMana && core.getMana() < this.getCurrentManaCost())
				return;
				
			if (core.controller.isBuildingBuildPointFree(buildingGridX, buildingGridY, this.buildingType))
			{
				if (this.type == "w")
				{
					if (core.calculator.isNewWallBlocking(buildingGridX, buildingGridX, buildingGridY, buildingGridY))// (this.buildingX, this.buildingX, this.buildingY, this.buildingY))
						return;
					if(!(core.buildingAreaMatrix[buildingGridY][buildingGridX] is (getDefinitionByName('com.giab.games.gcfw.steam.entity.Wall') as Class)))
					{
						core.creator.buildWall(buildingGridX, buildingGridY);
						core.stats.spentManaOnWalls += Math.max(0, this.getCurrentManaCost());
					}
					else return;
				}
				else if (this.type == "r")
				{
					if (core.buildingAreaMatrix[buildingGridY][buildingGridX] == null
						&& core.groundMatrix[buildingGridY][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY][buildingGridX + 1] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX] == "#"
						&& core.buildingAreaMatrix[buildingGridY + 1][buildingGridX + 1] == null
						&& core.groundMatrix[buildingGridY + 1][buildingGridX + 1] == "#")
					{
						core.creator.buildTrap(buildingGridX, buildingGridY);
						if (trackStats)
						{
							core.stats.spentManaOnTraps += Math.max(0, this.getCurrentManaCost());
						}
					}
					else return;
				}
				else if (!core.calculator.isNew2x2BuildingBlocking(buildingGridX, buildingGridY))
				{
					switch (this.type) 
					{
						case "t":
							core.creator.buildTower(buildingGridX, buildingGridY);
							if (trackStats)
							{
								core.stats.spentManaOnTowers += Math.max(0, this.getCurrentManaCost());
							}
							break;
						case "a":
							core.creator.buildAmplifier(buildingGridX, buildingGridY);
							if (trackStats)
							{
								core.stats.spentManaOnAmplifiers += Math.max(0, this.getCurrentManaCost());
							}
							break;
						case "p":
							core.creator.buildPylon(buildingGridX, buildingGridY);
							if (trackStats)
							{
								core.stats.spentManaOnPylons += Math.max(0, this.getCurrentManaCost());
							}
							break;
						case "l":
							core.creator.buildLantern(buildingGridX, buildingGridY);
							if (trackStats)
							{
								core.stats.spentManaOnLanterns += Math.max(0, this.getCurrentManaCost());
							}
							break;
						default:
							return;
					}
				}
				else return;
			}
			else return;
			
			if (spendMana)
			{
				core.changeMana( -this.getCurrentManaCost(), false, true);
				this.incrementManaCost();
			}
		}
		
		public function toString(): String
		{
			return this.type + "(" + this.blueprintIndexX + ";" + this.blueprintIndexY + ") at " + this.buildingX + ";" + this.buildingY;
		}
		
		public function incrementManaCost(): void
		{
			var GV:Object = ManaMason.ManaMason.bezel.gameObjects.GV;
			var core:Object = GV.ingameCore;
			switch (this.type) 
			{
				case "r":
					core.currentTrapBuildingManaCost.s(core.currentTrapBuildingManaCost.g() + Math.round(GV.TRAP_COST_INCREMENT.g()));
					break;
				case "t":
					core.currentTowerBuildingManaCost.s(core.currentTowerBuildingManaCost.g() + Math.round(GV.TOWER_COST_INCREMENT.g()));
					break;
				case "a":
					core.currentAmplifierBuildingManaCost.s(core.currentAmplifierBuildingManaCost.g() + Math.round(GV.AMPLIFIER_COST_INCREMENT.g()));
					break;
				case "p":
					core.currentPylonBuildingManaCost.s(Math.round(GV.PYLON_COST_MULT.g() * (core.currentPylonBuildingManaCost.g() + Math.round(GV.PYLON_COST_INCREMENT.g()))));
					break;
				case "l":
					core.currentLanternBuildingManaCost.s(core.currentLanternBuildingManaCost.g() + Math.round(GV.LANTERN_COST_INCREMENT.g()));
					break;
				case "w":
					core.currentWallBuildingManaCost.s(core.currentWallBuildingManaCost.g() + Math.round(GV.WALL_COST_INCREMENT.g()));
					break;
				default:
			}
		}
		
		public function getCurrentManaCost(): Number
		{
			var core:Object = ManaMason.ManaMason.bezel.gameObjects.GV.ingameCore;
			switch (this.type) 
			{
				case "r":
					return core.currentTrapBuildingManaCost.g();
					break;
				case "t":
					return core.currentTowerBuildingManaCost.g();
					break;
				case "a":
					return core.currentAmplifierBuildingManaCost.g();
					break;
				case "p":
					return core.currentPylonBuildingManaCost.g();
					break;
				case "l":
					return core.currentLanternBuildingManaCost.g();
					break;
				case "w":
					return core.currentWallBuildingManaCost.g();
					break;
				default:
					return 0;
					break;
			}
		}
	}

}