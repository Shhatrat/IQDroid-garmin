using IQDroid.IQ;

class IQScreenDelegate extends Toybox.WatchUi.BehaviorDelegate {

	function initialize() {
		Toybox.WatchUi.BehaviorDelegate.initialize();
   }

   function onKey(key){
		IQDroid.IQ.keyPressed(key);
   }
}