using Toybox.WatchUi;

class IQDroidexampleDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new IQDroidexampleMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}