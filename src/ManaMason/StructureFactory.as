package ManaMason 
{
	import ManaMason.Structures.Air;
	import ManaMason.Structures.Amplifier;
	import ManaMason.Structures.Lantern;
	import ManaMason.Structures.Pylon;
	import ManaMason.Structures.Tower;
	import ManaMason.Structures.Trap;
	import ManaMason.Structures.Wall;
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
				case "-":
					return new Air(bpIX, bpIY);
					break;
				case "w":
					return new Wall(bpIX, bpIY);
					break;
				case "a":
					return new Amplifier(bpIX, bpIY);
					break;
				case "t":
					return new Tower(bpIX, bpIY);
					break;
				case "r":
					return new Trap(bpIX, bpIY);
					break;
				case "p":
					return new Pylon(bpIX, bpIY);
					break;
				case "l":
					return new Lantern(bpIX, bpIY);
					break;
				default:
			}
			return new Air(bpIX, bpIY);
		}
	}

}