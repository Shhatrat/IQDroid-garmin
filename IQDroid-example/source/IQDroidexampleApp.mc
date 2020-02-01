using Toybox.Application;
using Toybox.WatchUi;
using IQDroid.IQ;
using Toybox.Position;
using Toybox.System;

class IQDroidexampleApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new IQInitView(), new IQInitDelegate() ];
   }
}
