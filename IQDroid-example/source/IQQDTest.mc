using IQDroid.IQ;

class IQQDTest extends Toybox.WatchUi.BehaviorDelegate {

	function initialize() {
		Toybox.WatchUi.BehaviorDelegate.initialize();
   }

   function onKey(key){
		IQDroid.IQ.keyPressed(key);
   }
}