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
	
	(:UpdateManager)
	module UpdateManager{
		
		/**
		*	Model classes
		**/
		
		class UpdatedData{
			var id;
			var requests;
		
			function initialize(id, requests){
				id = id;
				requests = requests;
			}
		}
		
		class FieldHolder{
			var callback;
			var enabledByIQ = false;
			var enabledByUser = false;
			var working = false;
		}
		
		/**
		*	Utils
		**/
		
		private var logsEnabled = false;		
		
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
		private var timer = new Toybox.Timer.Timer();
		private var timerEnabled = false;
		private var dataCallback;
		private var errorCallback;
		private var port;
		
		/**
		*	StartIQDroid function
		*	@param c callback for UpdatedData from Android device
		*	@param ec callback for errors of communcation with Android device
		*	@param p port of web server in Android device
		*	@param l enable logs		
		**/
		function startIQDroid(c, ec, p, l){
			if(!timerEnabled){
				port = p;
				dataCallback = c;
				errorCallback = ec;
				logsEnabled = l;
				timerEnabled = true;
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
		
		private var isDownloading = false;
		
		function requestCallback(){
			if(!isDownloading){
			  isDownloading = true;
			  Toybox.Communications.makeWebRequest("http://127.0.0.1:8000/", parameters, options, Toybox.Lang.Object.method(:downloadCallback));
			}
		} 
		
		private function downloadCallback(code, data){
			isDownloading = false;
			if(code == 200){
				handleDataFromAndroidDev(data);
			}else{
				errorCallback.invoke(code);
			}
		}
		
		/**
		*	handling data from Android device
		**/
		
		private var gps = false;
		private var battery = false;
		private var accel = false;
		private var altitude = false;
		private var cadence = false;
		private var heading = false;
		private var heartRate = false;
		private var mag = false;
		private var power = false;
		private var pressure = false;
		private var speed = false;
		private var temperature = false;
		
		private var lastId = 0;
		
		private function disableAll(){
			gps = false;
			battery = false;
			accel = false;
			altitude = false;
			cadence = false;
			heading = false;
			heartRate = false;
			mag = false;
			power = false;
			pressure = false;
			speed = false;
			temperature = false;
		}
		
		/**
		*	enable services
		*	GPS below
		*	sensors below
		**/
		
		private function enableBattery(){
			if(battery == false){
				battery = true;
			}
		}
		
		private function enableAccel(){
			accel = true;
		}
		
		private function enablePressure(){
			pressure = true;
		}
		
		
		private function enableAltitude(){
			altitude = true;
		}
		
		
		private function enableHeading(){
			heading = true;
		}
				
		private function enableMag(){
			mag = true;
		}
		
		private function disableAccel(){
			accel = false;
		}
		
		private function disablePressure(){
			pressure = false;
		}
		
		
		private function disableAltitude(){
			altitude = false;
		}
		
		
		private function disableHeading(){
			heading = false;
		}
				
		private function disableMag(){
			mag = false;
		}			
	
		private function handleDataFromAndroidDev(data){
			log("function handleDataFromAndroidDev()");
			log(data);
			var id = data["id"];
			var requests = data["req"];
			var updatedData = new UpdatedData(id,requests);
			log("id="+id+" lastId="+lastId);
			if(id>lastId){
				lastId=id;
				disableAll();
				for(var i = 0 ; i < requests.size(); i++){
					var item = requests[i];
					log("item ===>" + item);					
					switch (item){
					case "GPS":
						tryEnableGPSbyIQ();
						break;
					case "BATTERY":
						enableBattery();
						break;
					case "ACCEL":
						enableAccel();
						break;
					case "ALTITUDE":
						enableAltitude();
						break;
					case "HEADING":
						enableHeading();
						break;
					case "MAG":
						enableMag();
						break;
					case "PRESSURE":
						enablePressure();
						break;
					case "CADENCE":
						tryEnableCadenceByIQ();
						break;
					case "HEART_RATE":
						tryEnableHeartRateByIQ();
						break;
					case "POWER":
						tryEnablePowerByIQ();
						break;
					case "SPEED":
						tryEnableSpeedByIQ();
						break;
					case "TEMPERATURE":
						tryEnableTemperatureByIQ();
						break;
					}
					
				}
				checkIsAnyToDisable();
				dataCallback.invoke(updatedData);
				setSendingTimer();
			}
		}
		
		/**
		*	ANT+ sensors
		**/

		private var powerField = new FieldHolder();
		private var cadenceField = new FieldHolder();
		private var heartRateField = new FieldHolder();
		private var speedField = new FieldHolder();
		private var temperatureField = new FieldHolder();

						
		/**
		*	Main functions to enable sensors. Only this function can invoke Sensor.setEnabledSensors(...)
		**/
		private function enablePower(force){
			if(force || powerField.working == false){
			    Toybox.Sensor.setEnabledSensors([Toybox.Sensor.SENSOR_BIKEPOWER]);
			    Toybox.Sensor.enableSensorEvents(Toybox.Lang.Object.method(:onPower));			    
				power = true;
			}
		}
		
		private function enableCadence(force){
			if(force || cadenceField.working == false){
			    Toybox.Sensor.setEnabledSensors([Toybox.Sensor.SENSOR_BIKECADENCE]);
			    Toybox.Sensor.enableSensorEvents(Toybox.Lang.Object.method(:onCadence));			    
				cadence = true;
			}
		}

		private function enableHeartRate(force){
			if(force || heartRateField.working == false){
			    Toybox.Sensor.setEnabledSensors([Toybox.Sensor.SENSOR_HEARTRATE]);
			    Toybox.Sensor.enableSensorEvents(Toybox.Lang.Object.method(:onHeartRate));			 
				heartRate = true;
			}
		}

		private function enableSpeed(force){
			if(force || speedField.working == false){
			    Toybox.Sensor.setEnabledSensors([Toybox.Sensor.SENSOR_BIKESPEED]);
			    Toybox.Sensor.enableSensorEvents(Toybox.Lang.Object.method(:onSpeed));
				speed = true;
			}
		}
		
		private function enableTemperature(force){
			if(force || temperatureField.working == false){
			    Toybox.Sensor.setEnabledSensors([Toybox.Sensor.SENSOR_BIKEPOWER]);
			    Toybox.Sensor.enableSensorEvents(Toybox.Lang.Object.method(:onTemperature));
				temperature = true;
			}
		}
		
		/**
		*	Enable sensors by IQ
		**/
		private function tryEnablePowerByIQ(){
			powerField.enabledByIQ = true;
			enablePower(false);
		}
		
		private function tryEnableCadenceByIQ(){
			cadenceField.enabledByIQ = true;
			enableCadence(false);
		}

		private function tryEnableHeartRateByIQ(){
			heartRateField.enabledByIQ = true;
			enableHeartRate(false);
		}

		private function tryEnableSpeedByIQ(){
			speedField.enabledByIQ = true;
			enableSpeed(false);
		}
		
		private function tryEnableTemperatureByIQ(){
			temperatureField.enabledByIQ = true;
			enableTemperature(false);
		}
		
		/**
		*	Enable sensors by User
		**/
		private function tryEnablePowerByUser(c){
			powerField.enabledByUser = true;
			powerField.callback = c;
			enablePower(false);
		}
		
		private function tryEnableCadenceByUser(c){
			cadenceField.enabledByUser = true;
			cadenceField.callback = c;
			enableCadence(false);
		}

		private function tryEnableHeartRateByUser(c){
			heartRateField.enabledByUser = true;
			heartRateField.callback = c;
			enableHeartRate(false);
		}

		private function tryEnableSpeedByUser(c){
			speedField.enabledByUser = true;
			speedField.callback = c;
			enableSpeed(false);
		}
		
		private function enableTemperatureByUser(c){
			temperatureField.enabledByUser = true;
			temperatureField.callback = c;
			enableTemperature(false);
		}
		
		
		/**
		*	Sensors callbacks
		**/
		private function onPower(info){
			if(powerField.enabledByUser == true){
				cadenceField.callback.invoke(info);
			}
			powerInfo = info.power;
			if(power.enabledByIQ == true){
				sendData();
			}
		}
		
		private function onCadence(info){
			if(cadenceField.enabledByUser == true){
				cadenceField.callback.invoke(info);
			}
			cadenceInfo = info.cadence;
			if(cadenceField.enabledByIQ == true){
				sendData();
			}
		}
		
		private function onHeartRate(info){
			if(heartRateField.enabledByUser == true){
				heartRateField.callback.invoke(info);
			}
			heartRateInfo = info.heartRate;
			if(heartRateField.enabledByIQ == true){
				sendData();
			}
		}
		
		private function onSpeed(info){
			if(speedField.enabledByUser == true){
				speedField.callback.invoke(info);
			}
			speedInfo = info.speed;
			if(speedField.enabledByIQ == true){
				sendData();
			}
		}

		private function onTemperature(info){
			if(temperatureField.enabledByUser == true){
				temperatureField.callback.invoke(info);
			}
			temperature = info.temperature;
			if(temperatureField.enabledByIQ == true){
				sendData();
			}
		}

		/**
		*	Main disable sensors
		**/
		private function checkFieldInDisablingSensor(data){
			return data.working == true
			&& data.enabledByIQ == false
			&& data.enabledByUser == false;
		}
		
		private function refreshSensors(){
			if(temperatureField.working == true){
				enableTemperature(true);
			}
			if(speedField.working == true){
				enableSpeed(true);
			}
			if(heartRateField.working == true){
				enableHeartRate(true);
			}			
			if(cadenceField.working == true){
				enableCadence(true);
			}			
			if(powerField.working == true){
				enablePower(true);
			}			
		}
		
		private function disableTemperature(){
			if(checkFieldInDisablingSensor(temperatureField)){
				temperatureField.working = false;
				refreshSensors();
			}
		}
		
		private function disableSpeed(){
			if(checkFieldInDisablingSensor(speedField)){
				speedField.working = false;
				refreshSensors();
			}
		}

		private function disableHeartRate(){
			if(checkFieldInDisablingSensor(heartRateField)){
				heartRateField.working = false;
				refreshSensors();
			}
		}

		private function disableCadence(){
			if(checkFieldInDisablingSensor(cadenceField)){
				cadenceField.working = false;
				refreshSensors();
			}
		}

		private function disablePower(){
			if(checkFieldInDisablingSensor(powerField)){
				powerField.working = false;
				refreshSensors();
			}
		}

		/**
		*	Disable sensors by IQ
		**/
		private function disableTemperatureByIQ(){
			temperatureField.enabledByIQ = false;
			disableTemperature();			
		}
		
		private function disableSpeedByIQ(){
			speedField.enabledByIQ = false;
			disableSpeed();
		}

		private function disableHeartRateByIQ(){
			heartRateField.enabledByIQ = false;
			disableHeartRate();
		}

		private function disableCadenceByIQ(){
			cadenceField.enabledByIQ = false;
			disableCadence();
		}

		private function disablePowerByIQ(){
			powerField.enabledByIQ = false;
			disablePower();
		}
		
		/**
		*	Disable sensors by User
		**/
		private function tryDisablePowerByUser(){
			powerField.enabledByUser = false;
			powerField.callback = null;
			disablePower();
		}
		
		private function tryDisableCadenceByUser(){
			cadenceField.enabledByUser = false;
			cadenceField.callback = null;
			disableCadence();
		}

		private function tryDisableHeartRateByUser(){
			heartRateField.enabledByUser = false;
			heartRateField.callback = null;
			disableHeartRate();
		}

		private function tryDisableSpeedByUser(){
			speedField.enabledByUser = false;
			speedField.callback = null;
			disableSpeed();
		}
		
		private function tryDisableTemperatureByUser(){
			temperatureField.enabledByUser = false;
			temperatureField.callback = null;
			disableTemperature();
		}
		
		/**
		*	check to disable
		**/		
		
		private function checkIsAnyToDisable(){
			if(gps==false){
				disableGPSByIQ();
			}
			if(temperature == false){
				disableTemperatureByIQ();
			}
			if(speed==false){
				disableSpeedByIQ();
			}
			if(heartRate==false){
				disableHeartRateByIQ();
			}
			if(cadence==false){
				disableCadenceByIQ();
			}
			if(power==false){
				disablePowerByIQ();
			}			
		}
		
		/**
		*	GPS
		**/		
		private var gpsField = new FieldHolder();
	
		/**
		*	Main function to enable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS... )
		**/
		private function enableGPS(){
			log("function enableGPS(), gpsWorking ="+gpsField.working);
			if(gpsField.working == false){
				gpsField.working = true;
				log("function enableGPS(), enableLocationEvents");				
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS, Toybox.Lang.Object.method(:onPositionIQ));
			}
		}
		
		/**
		*	Main function to disable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE... )
		**/
		private function disableGPS(){
			log("function disableGPS()");
			if(gpsField.working ==true && (gpsField.enabledByUser ==true || gpsField.enabledByIQ == true)){				
				gpsField.working = false;
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE, Toybox.Lang.Object.method(:onPositionIQ));		
			}
		}	

		/**
		*	function for enabling gps by IQDroid.
		**/ 							
		private function tryEnableGPSbyIQ(){
			gpsField.enabledByIQ = true;
			enableGPS();
		}
		
		/**
		*	function for disabling gps by IQDroid.
		**/ 					
		private function disableGPSByIQ(){
			log("function disableGPSByIQ()");				
			gpsField.enabledByIQ = false;
			disableGPS();			
		}

		/**
		*	function for enabling gps by user.
		**/ 			
		function tryEnableGpsWithCallback(gpsC){
			log("function tryEnableGpsWithCallback()");	
			gpsField.callback = gpsC;
			gpsField.enabledByUser = true;	
			enableGPS();
		}

		/**
		*	function for disabling gps by user.
		**/ 					
		function disableGpsWithCallback(){
			log("function disableGpsWithCallback()");	
			gpsField.callback = null;
			gpsField.enabledByUser = false;
			disableGPS();
		}
		
		/**
		*	Callback function for handling gps position.
		**/ 
		private function onPositionIQ(info){
			log("function onPositionIQ("+info+"), gpsEnabledByUser="+gpsField.enabledByUser);
			if(gpsField.enabledByUser == true){
				gpsField.callback.invoke(info);
			}
			log("function onPositionIQ("+info+"), gpsEnabledByUser="+gpsField.enabledByIQ);			
			gpsInfo = convertInfo(info);
			if(gpsField.enabledByIQ == true){
				sendData();
			}
		}
		
		/**
		*	Send managment
		**/
		private var sendingTimer;
		
		private var sendingInProgress=false;
		private var gpsInfo;
		private var batteryInfo;	
		
		private var accelInfo;
		private var altitudeInfo;
		private var cadenceInfo;
		private var headingInfo;
		private var heartRateInfo;
		private var magInfo;
		private var powerInfo;
		private var pressureInfo;
		private var speedInfo;
		private var temperatureInfo;
	
		private function clearData(){
			batteryInfo = null;
		}
	
		private function getDataToSend(){
			log("function getDataToSend()");
			clearData();
			var responseDictionary = {};
			if(battery == true){
				batteryInfo = Toybox.System.getSystemStats().battery;
				responseDictionary.put("BATTERY", batteryInfo);
			}
			if(gps == true){
				responseDictionary.put("GPS", gpsInfo);
			}
			if(heartRate == true){
				responseDictionary.put("HEART_RATE", heartRateInfo);
			}
			if(cadence == true){
				responseDictionary.put("CADENCE", cadenceInfo);
			}
			if(accel ==true){
				accelInfo = Toybox.Sensor.getInfo().accel;
				responseDictionary.put("ACCEL", cadenceInfo);
			}
			if(altitude ==true){
				altitudeInfo = Toybox.Sensor.getInfo().altitude;
				responseDictionary.put("ALTITUDE", altitudeInfo);
			}
			if(heading ==true){
				headingInfo = Toybox.Sensor.getInfo().heading;
				responseDictionary.put("HEADING", headingInfo);
			}			
			if(mag ==true){
				magInfo = Toybox.Sensor.getInfo().mag;
				responseDictionary.put("MAG", magInfo);
			}			
			if(pressure ==true){
				pressureInfo = Toybox.Sensor.getInfo().pressure;
				responseDictionary.put("MAG", pressureInfo);
			}			
			if(power == true){
				responseDictionary.put("POWER", powerInfo);
			}
			if(speed == true){
				responseDictionary.put("SPEED", speedInfo);
			}
			if(temperature == true){
				responseDictionary.put("TEMPERATURE", temperatureInfo);
			}
			return responseDictionary;
		}
		
		private function setSendingTimer(){
			log("function setSendingTimer()");
				if(sendingTimer == null){
				sendingTimer = new Toybox.Timer.Timer();
				sendingTimer.start(Toybox.Lang.Object.method(:sendData), SENDING_INTERVAL , false);	
			}
		}
		
		private function sendData(){
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
	}
}