package ManaMason 
{
	/**
	 * ...
	 * @author Hellrage
	 */
	public class FakeGem 
	{
		public var gemGrade:int;
		public var gemType:int;
		public var targetPriority:int;
		public var usesGemsmith:Boolean;
		public var gemsmithRecipeName:String;
		public var fromInventory:Boolean;
		public var inventorySlot:int;
		public var rangeMultiplier:Number;
		
		public function FakeGem(type:int, grade:int) 
		{
			this.gemType = type;
			this.gemGrade = grade;
			this.usesGemsmith = false;
			this.gemsmithRecipeName = "No recipe";
			this.fromInventory = false;
			this.inventorySlot = -1;
			this.targetPriority = 0;
			this.rangeMultiplier = 1;
		}
		
	}

}