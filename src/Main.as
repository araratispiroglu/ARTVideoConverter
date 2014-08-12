package 
{
	import com.art.videoconverter.ARTVideoConverter;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Ararat Ispiroglu
	 */
	[SWF(frameRate="60")] 
	public class Main extends Sprite 
	{
		public function Main():void 
		{
			addChild(new ARTVideoConverter());
		}
	}
}