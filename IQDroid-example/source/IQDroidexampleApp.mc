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
	    IQDroid.UpdateManager.startIQDroid(method(:onDownloadSuccessfully), method(:onError), 8000, false);
    }
    
    function onDownloadSuccessfully(data){
    	Toybox.System.println(data);
    }
    
    function onError(code){
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
