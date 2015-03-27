package com.art.videoconverter
{
	import flash.system.Capabilities;
	import com.bit101.components.IndicatorLight;
	import com.bit101.components.Label;
	import com.bit101.components.List;
	import com.bit101.components.ProgressBar;
	import com.bit101.components.PushButton;
	import com.bit101.components.Text;
	import com.bit101.components.Window;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author Ararat Ispiroglu
	 */
	public class ARTVideoConverter extends Sprite 
	{
		private var title:Label;
		private var items:List;
		private var addItems:PushButton;
		private var removeItem:PushButton;
		private var removeAllItems:PushButton;
		private var convert:PushButton;
		private var stop:PushButton;
		private var changeDic:PushButton;
		private var about:PushButton;
		private var outputDicLbl:Label;
		private var outputDic:Text;
		private var fileProgressLbl:Label;
		private var fileProgress:ProgressBar;
		private var totalProgressLbl:Label;
		private var totalProgress:ProgressBar;
		private var window:Window;
		
		private var defaultConvertLocation:String;
		private var converting:Boolean;
		private var files:Vector.<File> = new Vector.<File>();
		private var toConvert:Vector.<File>;
		private var ffmpeg:FFMPEG;
		private var indicator:IndicatorLight;
		
		public function ARTVideoConverter() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.nativeWindow.addEventListener(Event.CLOSING, onClose);
			
			defaultConvertLocation = File.desktopDirectory.nativePath + PathSeperatorNotation + "converted" + PathSeperatorNotation;
			
			title = new Label(this, 0, 0, "ART Video Converter");
			var tf:TextFormat = title.textField.getTextFormat();
			tf.color = 0x0;
			tf.size = 11;
			title.textField.setTextFormat(tf);
			
			items = new List(this);
			
			addItems = new PushButton(this, 0, 0, "Add Items", onButtonClick);
			
			removeItem = new PushButton(this, 0, 0, "Remove Item", onButtonClick);
			
			removeAllItems = new PushButton(this, 0, 0, "Remove All Items", onButtonClick);
			
			convert = new PushButton(this, 0, 0, "Convert", onButtonClick);
			convert.enabled = false;
			
			stop = new PushButton(this, 0, 0, "Stop", onButtonClick);
			stop.enabled = false;
			
			changeDic = new PushButton(this, 0, 0, "Change Output Dic.", onButtonClick);
			
			about = new PushButton(this, 0, 0, "About", onButtonClick);
			
			outputDicLbl = new Label(this);
			outputDicLbl.text = "Output Dictionary:";
			
			outputDic = new Text(this, 0, 0, defaultConvertLocation);
			outputDic.editable = false;
			
			fileProgressLbl = new Label(this);
			fileProgressLbl.text = "File Progress:";
			
			fileProgress = new ProgressBar(this);
			
			totalProgressLbl = new Label(this);
			totalProgressLbl.text = "Total Progress:";
			
			totalProgress = new ProgressBar(this);
			
			indicator = new IndicatorLight(this, 0, 0, 0x00FF00);
			
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onClose(e:Event):void 
		{
			if (converting)
			{
				e.preventDefault();
				alert("Warning", "Converting ... \nStop Before close !", true);
			}
		}
		
		private function onButtonClick(e:MouseEvent):void 
		{
			var label:String = e.target.label;
			switch (label)
			{
				case addItems.label:
					var file:File = new File();
					file.addEventListener(FileListEvent.SELECT_MULTIPLE, function(e:FileListEvent):void
					{
						for (var i:int = 0; i < e.files.length; i++)
						{
							var item:File = File(e.files[i]);
							
							var found:Boolean;
							for (var j:int = 0; j < files.length; j++)
							{
								if (files[j].nativePath == item.nativePath)
								{
									found = true;
									break;
								}
							}
							
							if (!found)
							{
								files.push(item);
							}
						}
						updateList();
					});
					const videoFormats:String = "*.flv; *.mp4; *.mpeg; *.3gp; *.wmv; *.avi; *.mkv; *.mov; *.webm";
					file.browseForOpenMultiple("", [new FileFilter("Video Files", videoFormats)]);
					break;
				case removeItem.label:
					if (items.selectedIndex > -1 && items.selectedIndex < files.length)
					{
						files.splice(items.selectedIndex, 1);
						updateList();
					}
					break;
				case removeAllItems.label:
					files = new Vector.<File>();
					updateList();
					break;
				case convert.label:
					if (outputDic.text == defaultConvertLocation)
					{
						var f:File = new File(outputDic.text);
						if (!f.exists)
							f.createDirectory();
					}
					indicator.flash();
					toConvert = new Vector.<File>();
					for (var i:int = 0; i < files.length; i++) 
						toConvert.push(files[i]);
					fileProgress.maximum = 100;
					totalProgress.maximum = 100 * toConvert.length;
					converting = true;
					startConvert();
					addItems.enabled = false;
					removeItem.enabled = false;
					removeAllItems.enabled = false;
					convert.enabled = false;
					stop.enabled = true;
					changeDic.enabled = false;
					break;
				case stop.label:
					indicator.flash(0);
					ffmpeg.stop();
					ffmpeg = null;
					converting = false;
					addItems.enabled = true;
					removeItem.enabled = true;
					removeAllItems.enabled = true;
					convert.enabled = true;
					stop.enabled = false;
					changeDic.enabled = true;
					break;
				case changeDic.label:
					var folder:File = new File();
					folder.addEventListener(Event.SELECT, function(e:Event):void
					{
						outputDic.text = File(e.currentTarget).nativePath + PathSeperatorNotation;
					});
					folder.browseForDirectory("");
					break;
				case about.label:
					alert("About", "Developer: Ararat Ispiroglu \nE-Mail: ararat@ispiroglu.com\nwww.ispiroglu.com");
					break;
			}
		}
		
		private function startConvert():void 
		{
			if (toConvert.length > 0)
			{
				ffmpeg = new FFMPEG();
				ffmpeg.convert(toConvert[0], new File(outputDic.text + toConvert[0].name.replace(toConvert[0].extension, "mp4")),  onProgress, onComplete);
			}
			else
			{
				indicator.flash(0);
				converting = false;
				addItems.enabled = true;
				removeItem.enabled = true;
				removeAllItems.enabled = true;
				convert.enabled = true;
				stop.enabled = false;
				changeDic.enabled = true;
				files = new Vector.<File>();
				updateList();
				alert("Warning", "Video(s) Converted Successfully!", true);
			}
		}
		
		private function onProgress(e:Number):void
		{
			var totalCompleted:int = files.length - toConvert.length;
			fileProgress.value = e;
			totalProgress.value = (totalCompleted * 100) + e;
		}
		
		private function onComplete():void
		{
			if (toConvert.length > 0)
			{
				toConvert.splice(0, 1);
			}
			ffmpeg.stop();
			ffmpeg = null;
			startConvert();
		}
		
		private function onResize(e:Event = null):void 
		{
			graphics.clear();
			graphics.beginFill(0xF0F0F0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
			
			const space:Number = 10;
			var _y:Number = 10;
			var _yRight:Number = 10;
			
			title.x = space;
			title.y = _y;
			
			_y += title.textField.textHeight + space;
			_yRight = _y;
			
			addItems.x = stage.stageWidth - addItems.width - space;
			addItems.y = _yRight;
			
			_yRight += addItems.height + space;
			removeItem.x = stage.stageWidth - removeItem.width - space;
			removeItem.y = _yRight;
			
			_yRight += removeItem.height + space;
			removeAllItems.x = stage.stageWidth - removeAllItems.width - space;
			removeAllItems.y = _yRight;
			
			_yRight += removeAllItems.height + space;
			convert.x = stage.stageWidth - convert.width - space;
			convert.y = _yRight;
			
			_yRight += convert.height + space;
			stop.x = stage.stageWidth - stop.width - space;
			stop.y = _yRight;
			
			_yRight += stop.height + space;
			changeDic.x = stage.stageWidth - changeDic.width - space;
			changeDic.y = _yRight;
			
			_yRight += changeDic.height + space;
			about.x = stage.stageWidth - about.width - space;
			about.y = _yRight;
			
			totalProgress.x = space;
			totalProgress.y = stage.stageHeight - totalProgress.height - space;
			totalProgress.width = addItems.x - space - space;
			
			totalProgressLbl.x = space;
			totalProgressLbl.y = totalProgress.y - totalProgressLbl.height - (space / 2);
			
			fileProgress.x = space;
			fileProgress.y =  totalProgressLbl.y - fileProgress.height - (space / 2);
			fileProgress.width = addItems.x - space - space;
			
			fileProgressLbl.x = space;
			fileProgressLbl.y =  fileProgress.y - fileProgressLbl.height - (space / 2);
			
			outputDic.height = 20;
			outputDic.width = addItems.x - space - space;
			outputDic.x = space;
			outputDic.y = fileProgressLbl.y - outputDic.height - space;			
			
			outputDicLbl.x = space;
			outputDicLbl.y = outputDic.y - outputDicLbl.height - (space / 2);
			
			items.x = space;
			items.y = _y;
			items.width = addItems.x - space - space;
			items.height = outputDicLbl.y - items.y - space;
			
			indicator.width = indicator.height = 10;
			indicator.x = stage.stageWidth - indicator.width - space;
			indicator.y = stage.stageHeight - indicator.height - space;
		}
		
		private function updateList():void
		{
			items.removeAll();
			items.addItem("");//BUG FIX
			items.removeItemAt(0);//BUG FIX
			for (var i:int = 0; i < files.length; i++)
			{
				items.addItem(files[i].nativePath);
			}
			convert.enabled = (files.length > 0);
		}
		
		private function alert(title:String, text:String, force:Boolean = false):void
		{
			if (force && window != null)
			{
				window.parent.removeChild(window);
				window = null;
			}
			
			if (window == null)
			{
				window = new Window(this, 0, 0, title);
				window.width = 160;
				window.height = 110;
				window.x = (stage.stageWidth - window.width) / 2;
				window.y = (stage.stageHeight - window.height) / 2;
				
				var aboutLbl:Label = new Label(window, 10, 10, text);
				aboutLbl.width = window.width - 20;
				aboutLbl.height = window.height - 50;
				
				var close:PushButton = new PushButton(window, 0, 0, "Close", function(e:MouseEvent):void
				{
					window.parent.removeChild(window);
					window = null;
				});
				close.x = (window.width - close.width) / 2;
				close.y = window.height - close.height - 30;
			}
		}
		
		public static function get IsSystemWindows():Boolean
		{
			return Capabilities.os.indexOf("Windows") >= 0;	
		}
		
		public static function get PathSeperatorNotation():String
		{
			return IsSystemWindows ? "\\" : "/";
		}
	}
}