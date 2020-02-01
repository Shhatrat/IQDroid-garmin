using IQDroid.IQ;
using Toybox.Graphics as Gfx;

class IQScreenView extends Toybox.WatchUi.View {

	var cb = Toybox.Lang.Object.method(:update);

	function initialize() {
	    Toybox.WatchUi.View.initialize();
		IQDroid.IQ.setCallbackTest(cb);
	}
	
	function onDownloadSuccessfully(info){
	    	Toybox.System.println(info);
	}
	
	function onError(code){
	    	Toybox.System.println(code);
	}
	
	function update(){
		Toybox.WatchUi.requestUpdate();
	}

	function onUpdate(dc){
	    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		dc.clear();
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth()/2, dc.getHeight()* 0.2, Gfx.FONT_SMALL, IQDroid.IQ.screenItemsSize(), Gfx.TEXT_JUSTIFY_CENTER);
		IQDroid.IQ.onScreenUpdate(dc);
	}
}