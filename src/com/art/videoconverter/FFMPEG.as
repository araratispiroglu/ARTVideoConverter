package com.art.videoconverter 
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	/**
	 * ...
	 * @author Ararat Ispiroglu
	 */
	public class FFMPEG 
	{
		private var _process:NativeProcess;
		private var _processArgs:Vector.<String>;
		private var _nativeProcessStartupInfo:NativeProcessStartupInfo;
		private var _currentSeconds:Number = 0;
		private var _totalSeconds:Number = 0;
		private var _onProgress:Function;
		private var _onComplete:Function;
		
		public function convert(inPath:File, outPath:File, onProgress:Function, onComplete:Function):void
		{
			_onProgress= onProgress;
			_onComplete = onComplete;
			_nativeProcessStartupInfo = new NativeProcessStartupInfo();
			
			// set executable to the location of ffmpeg.exe
			var executable:String = "ffmpeg";
			
			if (ARTVideoConverter.IsSystemWindows)
			{
				executable += ".exe";
			}
			
			_nativeProcessStartupInfo.executable = File.applicationDirectory.resolvePath(executable);
			
			_processArgs = new Vector.<String>();
			_processArgs.push('-y'); // always overwrite existing file
			_processArgs.push('-i'); // input flag
			_processArgs.push(inPath.nativePath); // input path
			_processArgs.push("-movflags"); //moov atom fix
			_processArgs.push("faststart"); //moov atom fix
			_processArgs.push(outPath.nativePath); // output path
			_nativeProcessStartupInfo.arguments = _processArgs;
			
			_process = new NativeProcess();
			_process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, progress);
			_process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			_process.start(_nativeProcessStartupInfo);
		}
		
		private function progress(e:ProgressEvent):void 
		{
			var s:String = _process.standardError.readUTFBytes(_process.standardError.bytesAvailable);
			var reg:RegExp;
			var matches:Array;
			var time:Array;
			
			if (s.indexOf("frame=") != -1)
			{
				//is progress
				reg = /time=([^ ]+)/; // regexp to extract time portion
				matches = s.match(reg);
				
				if (matches.length > 0)
				{
					// split timestamp into sections
					time = matches[0].substring(5).split(":");
					// calculate the total seconds from the time stamp to get current seconds
					_currentSeconds = Math.round(((Number(time[0]) * 3600) + (Number(time[1]) * 60) + Number(time[2])));
				}
			}
			// Duration is sent at the beginning of the process which tells us how long the video is
			else if (s.indexOf("Duration:") != -1)
			{
				// find duration
				reg = /Duration:([^,]+)/; // regepx to extract duration portion
				matches = s.match(reg);
				
				if (matches.length > 0)
				{
					// split timestamp into sections
					time = matches[0].split(":");
					// calculate the total seconds from the time stamp to get total seconds
					_totalSeconds = Math.round(((Number(time[1]) * 3600) + (Number(time[2]) * 60) + Number(time[3])));
				}
			}
			// trace out the message if it contains Error, as there was probably something wrong with the encoding settings
			else if (s.indexOf("Error ") != -1)
			{
				trace("Error: " + s);
			}
			
			// trace percentage
			var percent:Number = Math.round(_currentSeconds / _totalSeconds * 100);
			_onProgress(percent);
		}
		
		private function onExit(e:NativeProcessExitEvent):void 
		{
			if (_onComplete != null)
				_onComplete();
			stop();
		}
		
		public function stop():void
		{
			_onProgress = null;
			_onComplete = null;
			
			if (_process != null)
			{
				_process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, progress);
				_process.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
				_process.exit(true);
			}
			_process = null;
		}
	}
}