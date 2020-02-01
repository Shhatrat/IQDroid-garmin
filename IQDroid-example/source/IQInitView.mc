using Toybox.WatchUi;
using IQDroid.IQ;
using Toybox.Graphics as Gfx;

class IQInitView extends WatchUi.View {

    function initialize() {
        View.initialize();
        IQDroid.IQ.startIQDroid(method(:onDownloadSuccessfully), method(:onError), 8000, true, true); 
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
    function onDownloadSuccessfully(data){
    	Toybox.System.println(data);
    }
       
    
    function onError(code){
	    	Toybox.System.println(code);
			mCode = code;
    		Toybox.WatchUi.requestUpdate();
    }
    var mCode = 99;

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
		dc.clear();
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth()/2, dc.getHeight()* 0.2, Gfx.FONT_SMALL, mCode, Gfx.TEXT_JUSTIFY_CENTER);
        
//        Toybox.WatchUi.pushView( new IQDroid.IQ.IQView(), new IQDroid.IQ.IQDelegate(), Toybox.WatchUi.SLIDE_UP );
        Toybox.WatchUi.pushView( new IQScreenView(), new IQScreenDelegate(), Toybox.WatchUi.SLIDE_UP );
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}