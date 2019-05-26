using Toybox.Application;
using Toybox.WatchUi;
using IQDroid.UpdateManager;
using Toybox.Position;
using Toybox.System;

class IQDroidexampleApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
	    IQDroid.UpdateManager.startIQDroid(method(:dd), method(:ee), 8000, false);
    }
    
    function dd(data){
    	Toybox.System.println(data);
    }
    
    function ee(code){
    	Toybox.System.println(code);
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new IQDroidexampleView(), new IQDroidexampleDelegate() ];
    }

}
