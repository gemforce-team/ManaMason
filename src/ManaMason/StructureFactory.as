package ManaMason 
{
	import ManaMason.Structures.AmplifierStruct;
	import ManaMason.Structures.TowerStruct;
	import ManaMason.Structures.TrapStruct;
	import ManaMason.Structures.WallStruct;
	/**
	 * ...
	 * @author Hellrage
	 */
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
				default:
			}
			return new WallStruct(bpIX, bpIY);
		}
	}

}