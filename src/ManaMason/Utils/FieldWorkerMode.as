package ManaMason.Utils 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	
	import flash.errors.IllegalOperationError;
	
	public class FieldWorkerMode 
	{
		public static const NONE:int = 0;
		public static const CAPTURE:int = 1;
		public static const UPGRADE:int = 2;
		public static const REFUND:int = 3;
		
		public static var colors:Array = [0xFFFFFF, 0x00FF00, 0xDD5500, 0x0000FF];
		
		public function FieldWorkerMode() 
		{
			throw new IllegalOperationError("FieldWorkerMode mustn't be instantiated");
		}
		
	}

}