package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import ManaMason.Structures.AmplifierStruct;
	import ManaMason.Structures.LanternStruct;
	import ManaMason.Structures.PylonStruct;
	import ManaMason.Structures.TowerStruct;
	import ManaMason.Structures.TrapStruct;
	import ManaMason.Structures.WallStruct;
	
	public class StructureFactory 
	{
		
		public function StructureFactory() 
		{
		}
		
		public static function CreateStructure(type:String, bpIX:int, bpIY:int): Structure
		{
			switch (type) 
			{
				case "w":
					return new WallStruct(bpIX, bpIY);
					break;
				case "a":
					return new AmplifierStruct(bpIX, bpIY);
					break;
				case "t":
					return new TowerStruct(bpIX, bpIY);
					break;
				case "r":
					return new TrapStruct(bpIX, bpIY);
					break;
				case "p":
					return new PylonStruct(bpIX, bpIY);
					break;
				case "l":
					return new LanternStruct(bpIX, bpIY);
					break;
				default:
			}
			return new WallStruct(bpIX, bpIY);
		}
	}
}