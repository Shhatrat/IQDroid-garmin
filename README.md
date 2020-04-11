# IQDroid-garmin

Library for monkey-c devices. 

Please see full description here: https://github.com/Shhatrat/IQDroid

Download: [1.2.0](https://github.com/Shhatrat/IQDroid-garmin/raw/master/IQDroid-1.2.0.barrel)

# Usage
### Init
Usage is quite simple. Firstly, you have to init library:

```        
using IQDroid.IQ;
...
function someFunction(){
  IQDroid.IQ.startIQDroid(method(:onDownloadSuccessfully), method(:onError), 8000, true, true); 
}
```
Parameters:
 - callback for data
 - callback for errors
 - server's port on Android device
 - is log enabled
 - is screen functionality enabled

### Getting data

Now you can communicate with Android library. It allows us to get automatically data of:
 - battery
 - altitude
 - mag
 - heading
 - preassure
 - time
 - accel
 - heart rate(ANT+)
 - bike power(ANT+)
 - bike cadence(ANT+)
 - bike speed(ANT+)
 - temperature(ANT+)
 - gps data


Some data need special handling if you need get it on IQ device and Android lib in the same time. Types:
 - gps
 - heart rate(ANT+)
 - bike power(ANT+)
 - bike cadence(ANT+)
 - bike speed(ANT+)
 - temperature(ANT+)
 
 For getting this data you should use functions:

```
IQDroid.IQ.tryEnableGpsWithCallback(callback, enabled);
IQDroid.IQ.tryEnablePowerByUser(callback, enabled);
IQDroid.IQ.tryEnableCadenceByUser(callback, enabled);
IQDroid.IQ.tryEnableHeartRateByUser(callback, enabled);
IQDroid.IQ.tryEnableSpeedByUser(callback, enabled);
IQDroid.IQ.tryEnableTemperatureByUser(callback, enabled);
```
Parameters:
 - callback for data
 - is function enabled
 
Of course you have to disable it if getting data is no longer necessary.

### Screen support
Screen is feature for creating dynamically IQ app.
```
var callback = Toybox.Lang.Object.method(:update);

function initialize() {
	Toybox.WatchUi.View.initialize();
	IQDroid.IQ.setCallbackTest(callback);
}

function update(){
	Toybox.WatchUi.requestUpdate();
}

function onUpdate(dc){
	...
	IQDroid.IQ.onScreenUpdate(dc);
}
```
