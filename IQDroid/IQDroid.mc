using Toybox.Lang;


module IQDroid {

	/**
	*	Consts for whole IQDroid lib
	**/
	const url = "127.0.0.1:";
	const options = {	:responseType => Toybox.Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
	const parameters = null;

	//in millis
	const SENDING_INTERVAL = 1000;
	const DOWNLOADING_INTERVAL = 1000;

	(:IQ)
	module IQ{

		/**
		*	Model classes
		**/

		/**
		*	Class for storing data from android device.
		*/
		class UpdatedData{
			var id;
			var requests;

			function initialize(id, requests){
				id = id;
				requests = requests;
			}
		}

		/**
		*	Class for storing data which need callbacks
		*/
		class FieldHolder{
			var tryEnableByIQ = false;
			var enabledByIQ = false;
			var enabledByUser = false;
			var working = false;
			var callbackForUser;
			var value;
		}


		/**
		*	Class for storing data which no need
		*/
		class SimpleFieldHolder{
			var enableByIQ = false;
			var lastValue;
			var name;

			function initialize(fieldName){
				name = fieldName;
			}

			function prepareValue(){
			log("SimpleFieldHolder.prepareValue(), name ="+name);
				if(name.equals("BATTERY")){ return Toybox.System.getSystemStats().battery; }
				if(name.equals("MAG")){ return Toybox.Sensor.getInfo().mag; }
				if(name.equals("ALTITUDE")){ return Toybox.Sensor.getInfo().altitude; }
				if(name.equals("HEADING")){ return Toybox.Sensor.getInfo().heading; }
				if(name.equals("PRESSURE")){ return Toybox.Sensor.getInfo().pressure; }
				if(name.equals("TIME")){return Toybox.Time.now().value();}
			}
		}

		class AntContainer{
			var lastValue;
			var items;	// list of AntHolder's

			function isAnyToEnable(){
				var size = items.size();
	    		for( var i = 0; i < size; i += 1 ) {
	    			var currentItem = items[i];
	    			if((currentItem.enabledByIQ == false && currentItem.enabledByUser == false)
	    				&& (currentItem.tryEnableByIQ == true || currentItem.tryEnableByUser == true )){
	    				return true;
	    			}
	    		}
	    		return false;
			}

			function isAnyToDisable(){
				var size = items.size();
	    		for( var i = 0; i < size; i += 1 ) {
	    			var currentItem = items[i];
	    			if((currentItem.enabledByIQ == true || currentItem.enabledByUser == true)
	    				&& (currentItem.tryEnableByIQ == false || currentItem.tryEnableByUser == false )){
	    				return true;
	    			}
	    		}
	    		return false;
			}

			function enableRequiredDevices(){
				log("AntContainer.enableRequiredDevices()");
				var size = items.size();
	    		for( var i = 0; i < size; i += 1 ) {
	    			var currentItem = items[i];
	    			if(currentItem.tryEnableByIQ == true){
	    				currentItem.enabledByIQ = true;
	    			}
	    			if(currentItem.tryEnableByUser == true){
	    				currentItem.enabledByUser = true;
	    			}
	    		}

	    		var arrayToEnable=[];
	    		for( var i = 0; i < size; i += 1 ) {
	    			var currentItem = items[i];
					if(currentItem.enabledByIQ == true || currentItem.enabledByUser == true){
						arrayToEnable.add(currentItem.typeValue);
					}
	    		}
				log("AntContainer.enableRequiredDevices(), arrayToEnable="+arrayToEnable);
	    		Toybox.Sensor.setEnabledSensors(arrayToEnable);
	    		Toybox.Sensor.enableSensorEvents(method(:onAnt));
			}
		}

		function onAnt(sensorInfo){
			antContainer.lastValue = sensorInfo;
			sendData();
		}

		class AntHolder{
			var tryEnableByIQ = false;
			var tryEnableByUser = false;
			var enabledByIQ = false;
			var enabledByUser = false;
			var callbackForUser;
			var typeValue;

			function initialize(type){
				typeValue = type;
			}
		}

		/**
		*	Storing data objects
		*/

		var gpsHolder = new FieldHolder();

		var batteryHolder = new SimpleFieldHolder("BATTERY");
		var	accelHolder = new SimpleFieldHolder("ACCEL");
		var altitudeHolder = new SimpleFieldHolder("ALTITUDE");
		var headingHolder = new SimpleFieldHolder("HEADING");
		var magHolder = new SimpleFieldHolder("MAG");
		var pressureHolder = new SimpleFieldHolder("PRESSURE");
		var timeHolder = new SimpleFieldHolder("TIME");

		var cadenceHolder = new AntHolder(Toybox.Sensor.SENSOR_BIKECADENCE);
		var heartRateHolder = new AntHolder(Toybox.Sensor.SENSOR_HEARTRATE);
		var powerHolder =  new AntHolder(Toybox.Sensor.SENSOR_BIKEPOWER);
		var speedHolder = new AntHolder(Toybox.Sensor.SENSOR_BIKESPEED);
		var temperatureHolder = new AntHolder(Toybox.Sensor.SENSOR_BIKEPOWER);

		var antContainer = new AntContainer();
		var simpleItems;	//list of SimpleFieldHolder

		var otherData = "";
		var screensDataToSend = "";

		function initData(){
		//create AntContainer.items
			log("initialize()");
			antContainer.items = [cadenceHolder, heartRateHolder, powerHolder, powerHolder, speedHolder, temperatureHolder];
			simpleItems = [batteryHolder ,accelHolder ,altitudeHolder ,headingHolder ,magHolder ,pressureHolder, timeHolder];
		}

		/**
		*	Utils
		**/

		 var logsEnabled = false;


		/**
		*	function for converting GPS data
		*/
		function convertInfo(info){
			return  {
			    "accuracy" => info.accuracy,
			    "altitude" => info.altitude,
		    	"heading" => info.heading,
			    "speed" => info.speed,
			    "timestamp" => info.when.value(),
			    "lat" => info.position.toDegrees()[0],
	 	    	"lng" => info.position.toDegrees()[1]};
	 	}

	 	function log(msg){
	 		if(logsEnabled == true){
	 			Toybox.System.println("IQDroid log -> "+msg);
	 		}
	 	}

		/**
		*	Timer managment
		**/
		 var timer = new Toybox.Timer.Timer();
		 var timerEnabled = false;
		 var screensEnabled;
		 var dataCallback;
		 var errorCallback;
		 var port;

		/**
		*	StartIQDroid function
		*	@param c callback for UpdatedData from Android device
		*	@param ec callback for errors of communcation with Android device
		*	@param p port of web server in Android device
		*	@param l enable logs
		*	@param s enable screens
		**/
		function startIQDroid(c, ec, p, l, s){
			if(!timerEnabled){
				port = p;
				dataCallback = c;
				errorCallback = ec;
				logsEnabled = l;
				timerEnabled = true;
				screensEnabled = s;
				initData();
		    	timer.start(Toybox.Lang.Object.method(:requestCallback), DOWNLOADING_INTERVAL, true);
		    }
		}

		/**
		*	checking is IQDroid enabled
		**/
		function isIQDroidEnabled(){
			return timerEnabled;
		}

		/**
		*	Stoping IQDroid function
		**/
		function stopIQDroid(){
			if(timerEnabled){
				timerEnabled = false;
				timer.stop();
			}
		}

		/**
		*	Update managment
		**/

		 var isDownloading = false;

		function requestCallback(){
			if(!isDownloading){
			  isDownloading = true;
			  Toybox.Communications.makeWebRequest("http://127.0.0.1:8000/", parameters, options, Toybox.Lang.Object.method(:downloadCallback));
//			  Toybox.Communications.makeWebRequest("https://pastebin.com/raw/jaa4fEP1", parameters, options, Toybox.Lang.Object.method(:downloadCallback));
//			  Toybox.Communications.makeWebRequest("https://pastebin.com/raw/7khxeVgE", parameters, options, Toybox.Lang.Object.method(:downloadCallback));
			}
		}

		 function downloadCallback(code, data){
			isDownloading = false;
			if(code == 200){
				handleDataFromAndroidDev(data);
			}else{
				errorCallback.invoke(code);
			}
		}

		 var lastId = 0;

		 function disableAll(){
			gpsHolder.tryEnableByIQ = false;

			batteryHolder.enableByIQ = false;
			accelHolder.enableByIQ = false;
			altitudeHolder.enableByIQ = false;
			headingHolder.enableByIQ = false;
			magHolder.enableByIQ = false;
			pressureHolder.enableByIQ = false;
			timeHolder.enableByIQ = false;

			tryEnableCadenceByIQ(false);
			tryEnableHeartRateByIQ(false);
			tryEnablePowerByIQ(false);
			tryEnableSpeedByIQ(false);
			tryEnableTemperatureByIQ(false);
		}

		 function handleDataFromAndroidDev(data){
			log("function handleDataFromAndroidDev()");
			log("function handleDataFromAndroidDev()"+data);
			var id = data["id"];
			var requests = data["req"];
			var updatedData = new UpdatedData(id,requests);
			if(screensEnabled==true){
				var screens = data["screens"];
				log("screens="+screens);
				if(screens!=null){
					sharedScreenData.items = screens;
					sharedScreenData.prepareCurrentItem();
					sharedScreenData.dataUpdated();
				}
			}
			log("function handleDataFromAndroidDev() id="+id+" lastId="+lastId);
			if(id>lastId){
//			if(true){
				lastId=id;
				log("function handleDataFromAndroidDev() disableAll()");
				log("function handleDataFromAndroidDev() requests.size() ="+requests.size());
				log("function handleDataFromAndroidDev() requests="+requests);
				disableAll();
				for(var i = 0 ; i < requests.size(); i++){
					var item = requests[i];
					log("function handleDataFromAndroidDev() item ===>" + item);
					switch (item){
					case "GPS":
						tryEnableGPSbyIQ();
						break;
					case "BATTERY":
						batteryHolder.enableByIQ = true;
						break;
					case "ACCEL":
						accelHolder.enableByIQ = true;
						break;
					case "ALTITUDE":
						altitudeHolder.enableByIQ = true;
						break;
					case "HEADING":
						headingHolder.enableByIQ = true;
						break;
					case "MAG":
						magHolder.enableByIQ = true;
						break;
					case "TIME":
						timeHolder.enableByIQ = true;
						break;
					case "PRESSURE":
						pressureHolder.enableByIQ = true;
						break;
					case "CADENCE":
						tryEnableCadenceByIQ(true);
						break;
					case "HEART_RATE":
						tryEnableHeartRateByIQ(true);
						break;
					case "POWER":
						tryEnablePowerByIQ(true);
						break;
					case "SPEED":
						tryEnableSpeedByIQ(true);
						break;
					case "TEMPERATURE":
						tryEnableTemperatureByIQ(true);
						break;
					}
				}
				checkIsAnyToDisable();
				dataCallback.invoke(updatedData);
				setSendingTimer();
			}
		}

		/**
		*	Enable sensors by IQ
		**/
		 function tryEnablePowerByIQ(enabled){
			 powerHolder.tryEnableByIQ = enabled;
		}

		 function tryEnableCadenceByIQ(enabled){
 			 cadenceHolder.tryEnableByIQ = enabled;
		}

		 function tryEnableHeartRateByIQ(enabled){
			 heartRateHolder.tryEnableByIQ = enabled;
		}

		 function tryEnableSpeedByIQ(enabled){
			 speedHolder.tryEnableByIQ = enabled;
		}

		 function tryEnableTemperatureByIQ(enabled){
			 temperatureHolder.tryEnableByIQ = enabled;
		}

		/**
		*	Enable sensors by User
		**/
		 function tryEnablePowerByUser(c, enabled){
			 powerHolder.tryEnableByUser = enabled;
			 powerHolder.callbackForUser = c;
		}

		 function tryEnableCadenceByUser(c, enabled){
 			 cadenceHolder.tryEnableByUser = enabled;
			 cadenceHolder.callbackForUser = c;
		}

		 function tryEnableHeartRateByUser(c, enabled){
			 heartRateHolder.tryEnableByUser = enabled;
			 heartRateHolder.callbackForUser = c;
		}

		 function tryEnableSpeedByUser(c, enabled){
			 speedHolder.tryEnableByUser = enabled;
			 speedHolder.callbackForUser = c;
		}

		 function enableTemperatureByUser(c, enabled){
			 temperatureHolder.tryEnableByUser = enabled;
			 temperatureHolder.callbackForUser = c;
		}


		/**
		*	check to disable
		**/

		 function checkIsAnyToDisable(){
			if(gpsField.enabledByIQ==false){
				disableGPSByIQ();
			}

			// check ANT+
			//enable
			log("function checkIsAnyToDisable(), antContainer.isAnyToEnable()="+ antContainer.isAnyToEnable());
			if(antContainer.isAnyToEnable()){
				antContainer.enableRequiredDevices();
			}else if(antContainer.isAnyToDisable()){
				antContainer.enableRequiredDevices();
			}
		}

		/**
		*	Other data
		**/
		function setOtherData(dataToSet){
			otherData = dataToSet;
		}

		/**
		*	GPS
		**/
		 var gpsField = new FieldHolder();

		/**
		*	Main function to enable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS... )
		**/
		 function enableGPS(){
			log("function enableGPS(), working ="+gpsField.working);
			if(gpsField.working == false){
				gpsField.working = true;
				log("function enableGPS(), enableLocationEvents");
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS, Toybox.Lang.Object.method(:onPositionIQ));
			}
		}

		/**
		*	Main function to disable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE... )
		**/
		 function disableGPS(){
			log("function disableGPS()");
			if(gpsField.working ==true){
				log("function disableGPS() disabled");
				gpsField.working = false;
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE, Toybox.Lang.Object.method(:onPositionIQ));
			}
		}

		/**
		*	function for enabling gps by IQDroid.
		**/
		 function tryEnableGPSbyIQ(){
			gpsField.enabledByIQ = true;
			enableGPS();
		}

		/**
		*	function for disabling gps by IQDroid.
		**/
		 function disableGPSByIQ(){
			log("function disableGPSByIQ()");
			gpsField.enabledByIQ = false;
			disableGPS();
		}

		/**
		*	function for enabling gps by user.
		**/
		function tryEnableGpsWithCallback(gpsC){
			log("function tryEnableGpsWithCallback()");
			gpsField.callbackForUser = gpsC;
			gpsField.enabledByUser = true;
			enableGPS();
		}

		/**
		*	function for disabling gps by user.
		**/
		function disableGpsWithCallback(){
			log("function disableGpsWithCallback()");
			gpsField.callbackForUser = null;
			gpsField.enabledByUser = false;
			disableGPS();
		}

		/**
		*	Callback function for handling gps position.
		**/
		 function onPositionIQ(info){
			log("function onPositionIQ("+info+"), gpsEnabledByUser="+gpsField.enabledByUser);
			if(gpsField.enabledByUser == true){
				gpsField.callbackForUser.invoke(info);
			}
			log("function onPositionIQ("+info+"), gpsEnabledByIQ="+gpsField.enabledByIQ);
			gpsField.value = convertInfo(info);
			if(gpsField.enabledByIQ == true){
				sendData();
			}
		}

		/**
		*	Send managment
		**/
		 var sendingTimer;
		 var sendingInProgress=false;


		 function getDataToSend(){
		 var responseDictionary = {};
			log("function getDataToSend() getting data...");

			//gps
			if(gpsField.enabledByIQ == true){
				log("function getDataToSend gps");
				responseDictionary.put("GPS", gpsField.value);
			}

			//simple fields
			for(var i = 0 ; i < simpleItems.size(); i++){
				var item = simpleItems[i];
				if(item.enableByIQ == true){
					item.lastValue = item.prepareValue();
					log("function getDataToSend"+item.name+"="+item.lastValue);
					responseDictionary.put(item.name , item.lastValue);
				}
			}

			// other data
			responseDictionary.put("OTHER", otherData);

			// screensData data
			if(screensEnabled==true){
				responseDictionary.put("SCREENS", screensDataToSend);
			}
			
			// ant+
			if(heartRateHolder.enabledByIQ == true){
				responseDictionary.put("HEART_RATE", antContainer.lastValue.heartRate);
			}
			if(cadenceHolder.enabledByIQ == true){
				responseDictionary.put("CADENCE", antContainer.lastValue.cadence);
			}
			if(powerHolder.enabledByIQ == true){
				responseDictionary.put("POWER", antContainer.lastValue.power);
			}
			if(speedHolder.enabledByIQ == true){
				responseDictionary.put("SPEED", antContainer.lastValue.speed);
			}
			if(temperatureHolder.enabledByIQ == true){
				responseDictionary.put("TEMPERATURE", antContainer.lastValue.temperature);
			}
			log("function getDataToSend data="+responseDictionary);
			return responseDictionary;
		}

		 function setSendingTimer(){
			log("function setSendingTimer()");
				if(sendingTimer == null){
				sendingTimer = new Toybox.Timer.Timer();
				sendingTimer.start(Toybox.Lang.Object.method(:sendData), SENDING_INTERVAL , false);
			}
		}

		 function sendData(){
			log("function sendData()");
			if(sendingInProgress == false){
				sendingInProgress = true;
				sendingTimer.stop();
				sendingTimer = null;
				log(getDataToSend());
				Toybox.Communications.transmit(getDataToSend(), null, new SendingCallback());
			}
		}

		class SendingCallback extends Toybox.Communications.ConnectionListener{

	    	function initialize(){
				Toybox.Communications.ConnectionListener.initialize();
 			}

    		function onError(){
    			log("function SendingCallback.onError()");
    			otherData = "";
    			screensDataToSend = "";
	    		sendingInProgress=false;
				errorCallback.invoke("ERROR SENDING");
				setSendingTimer();
	    	}

    		function onComplete(){
	   			log("function SendingCallback.onComplete()");
	    		sendingInProgress=false;
	    		setSendingTimer();
    		}
   		}


   		/**
   		*	handling graphs classes
   		*/

   		class Screen{
   			var id;
   			var navigation; //type NavigationType
   			var screenItemList;	//type ScreenItem
   		}

   		class NavigationType{
   			var id;
   			var keyCode;
   			var transition;
   		}

   		class ScreenItem{
   			var type;
   			var x;
   			var y;
   			var color;
   			var backgroundColor;
   			var data;	//mapOfData
   		}

		/**
		*	This class contains all logic for chaining and dealing with screens.
		**/
   		class SharedData{
   			var onUpdateViewCallback;
   			var lastScreenId = 1;
   			var items;			//list of Screen's
			var currentItem;	//type Screen

			function initialize(){}

   			function dataUpdated(){
   				if(onUpdateViewCallback!=null){
	   				onUpdateViewCallback.invoke();
	   			}
   			}

   			function prepareCurrentItem(){
   			    if(currentItem==null){
   			        for(var i = 0 ; i < items.size(); i++){
   			            if(items[i]["id"] == lastScreenId){
   			                currentItem = items[i];
   			            }
   			        }
   			    }
   			}

  			function setCallback(callback){
       				onUpdateViewCallback = callback;
       		}

   			function keyPressed(key){
   				sendClick(lastScreenId, key);

      			for(var i = 0 ; i < currentItem["navigation"].size(); i++){
      			    if(currentItem["navigation"][i]["keyCode"] == key){
      			        for(var j = 0; j < items.size(); j++){
      			            if(currentItem["navigation"][i]["id"] == items[j]["id"]){
          			            currentItem = items[j];
          			            lastScreenId = currentItem["id"];
	            				dataUpdated();
          			            break;
      			            }
      			        }
      			        break;
      			    }
                }
   			}

   			function removeCallback(){
   			    onUpdateViewCallback = null;
   			}

   			function sendClick(id, key){
   				var tmpData= {};
   				tmpData.put("ID", id);
   				tmpData.put("KEYS", key);
				screensDataToSend = tmpData;
   			}
   		}

   		function keyPressed(key){
	   		sharedScreenData.keyPressed(key.getKey());
   		}

   		function setCallbackTest(cb){
   			sharedScreenData.setCallback(cb);
   		}

   		/**
   		*	Shared object
   		**/

   		var sharedScreenData = new SharedData();

		function screenItemsSize(){
			if(sharedScreenData.currentItem!=null && sharedScreenData.currentItem["screenItemList"]!=null){
				var item = sharedScreenData.currentItem["screenItemList"];
			return item.size();
			}
			return "zero";
		}

		function onScreenUpdate(dc){
				if(sharedScreenData.currentItem!=null && sharedScreenData.currentItem["screenItemList"]!=null){
				var item = sharedScreenData.currentItem["screenItemList"];
				log("item -->"+item);
                    handleItem(dc, item);
				}
		}

            	    function handleItem(dc, item){
	    	        			for(var i = 0 ; i < item.size(); i++){
                                    switch (item[i]["type"]){
                                    case "DRAW_TEXT":
                                        drawText(item[i], dc);
                                        break;
                                    case "BACKGROUND":
                                        drawBackgroundColor(item[i], dc);
                                        break;
                                    case "LINE":
                                        drawLine(item[i], dc);
                                        break;
                                    case "ELLIPSE":
                                    	drawEllipse(item[i], dc);
                                    	break;
                                    case "CIRCLE":
                                    	drawCircle(item[i], dc);
                                    	break;
                                    case "RECTANGLE":
                                    	drawRectangle(item[i], dc);
                                    	break;
                                    case "RECTANGLE_ROUNDED":
                                    	drawRectangleRounded(item[i], dc);
                                    	break;
                                    }                                    
            	    		    }
	    	}

	    	/**
	    	*   Function for handling items
	    	**/
	    	function drawRectangleRounded(item, dc){
                rawDrawRectangleRounded(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["x"],
                            item["y"],
                            item["data"]["width"],	    	
                            item["data"]["height"],
                            item["data"]["radius"]);	    	
	    	}
	    	
	    	function drawRectangle(item, dc){
                rawDrawRectangle(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["x"],
                            item["y"],
                            item["data"]["width"],	    	
                            item["data"]["height"]);	    	
	    	}
	    	
	    	function drawCircle(item, dc){
                rawDrawEllipse(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["x"],
                            item["y"],
                            item["data"]["radius"]);	    	
	    	}
	    	
	    	function drawEllipse(item, dc){
                rawDrawEllipse(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["x"],
                            item["y"],
                            item["data"]["a"],
                            item["data"]["b"]);
	    	}
	    	
	    	function drawLine(item, dc){
                rawDrawLine(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["data"]["x1"],
                            item["data"]["y1"],
                            item["data"]["x2"],
                            item["data"]["y2"]);
	    	}

	    	function drawText(item, dc){
                rawDrawText(dc,
                            item["color"],
                            item["backgroundColor"],
                            item["x"],
                            item["y"],
                            item["data"]["font"],
                            item["data"]["text"],
                            item["data"]["justification"]);
	    	}

	    	function drawBackgroundColor(item, dc){
                rawDrawBackgroundColor(	dc,
                            item["color"]);
	    	}

			/**
			*	Functions for creating UI.
			**/
			function rawDrawRectangleRounded(dc, color, backgroundColor, x, y, width, height, radius){
				dc.setColor(color, backgroundColor);
				dc.drawRectangleRounded(x,y,width, height, radius);
			}

			function rawDrawRectangle(dc, color, backgroundColor, x, y, width, height){
				dc.setColor(color, backgroundColor);
				dc.drawRectangle(x,y,width, height);
			}
			
			function rawDrawCircle(dc, color, backgroundColor, x, y, radius){
				dc.setColor(color, backgroundColor);
				dc.drawCircle(x,y,radius);
			}
			
			function rawDrawEllipse(dc, color, backgroundColor, x, y, a, b){
				dc.setColor(color, backgroundColor);
				dc.drawEllipse(x,y,a,b);
			}
			
			function rawDrawLine(dc, color, backgroundColor, x1, y1, x2, y2){
				dc.setColor(color, backgroundColor);
				dc.drawLine(x1, y1, x2, y2);
			}

			function rawDrawBackgroundColor(dc, color){
	           	dc.setColor(color, color);
				dc.clear();
			}

			function rawDrawText(dc, color, backgroundColor, x, y, font, text, justification){
				dc.setColor(color, backgroundColor);
				dc.drawText(x,y,font,text,justification);
			}
	}
}
