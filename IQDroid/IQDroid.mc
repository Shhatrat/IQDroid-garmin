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
//			  Toybox.Communications.makeWebRequest("http://192.168.8.103:8000", parameters, options, Toybox.Lang.Object.method(:downloadCallback));			
			}
		} 
		
		private function downloadCallback(code, data){
			isDownloading = false;
			if(code == 200){
				handleData(data);
			}else{
				errorCallback.invoke(code);
			}
		}
		
		/**
		*	handling data from Android device
		**/
		
		private var gps = false;
		private var battery = false;
		private var lastId = 0;
		
		private function disableAll(){
			gps = false;
			battery = false;
		}
		
		/**
		*	enable services
		*	GPS below
		**/
		
		private function enableBattery(){
			if(battery == false){
				battery = true;
			}
		}
		
		private function checkIsAnyToDisable(){
			if(gps==false){
				disableGPSByIQ();
			}
		}
		
		private function handleData(data){
			log("function handleData()");
			log(data);
			var id = data["id"];
			var requests = data["req"];
			var updatedData = new UpdatedData(id,requests);
			log("id="+id+" lastId="+lastId);
//			if(id>lastId){
			if(true){
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
					}
				}
				checkIsAnyToDisable();
				dataCallback.invoke(updatedData);
				setSendingTimer();
			}
		}
		
		/**
		*	GPS
		**/		
		private var gpsCallback;
		private var gpsEnabledByIQ = false;
		private var gpsEnabledByUser = false;
		private var gpsWorking = false;
	
		/**
		*	Main function to enable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS... )
		**/
		private function enableGPS(){
			log("function enableGPS(), gpsWorking ="+gpsWorking);
			if(gpsWorking == false){
				gpsWorking = true;
				log("function enableGPS(), enableLocationEvents");				
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_CONTINUOUS, Toybox.Lang.Object.method(:onPositionIQ));
			}
		}
		
		/**
		*	Main function to disable gps. Only this function can invoke Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE... )
		**/
		private function disableGPS(){
			log("function disableGPS()");
			if(gpsWorking ==true && (gpsEnabledByUser ==true || gpsEnabledByIQ == true)){				
				gpsWorking = false;
				Toybox.Position.enableLocationEvents(Toybox.Position.LOCATION_DISABLE, Toybox.Lang.Object.method(:onPositionIQ));		
			}
		}	

		/**
		*	function for enabling gps by IQDroid.
		**/ 							
		private function tryEnableGPSbyIQ(){
			gpsEnabledByIQ = true;
			enableGPS();
		}
		
		/**
		*	function for disabling gps by IQDroid.
		**/ 					
		private function disableGPSByIQ(){
			log("function disableGPSByIQ()");				
			gpsEnabledByIQ = false;
			disableGPS();			
		}

		/**
		*	function for enabling gps by user.
		**/ 			
		function tryEnableGpsWithCallback(gpsC){
			log("function tryEnableGpsWithCallback()");	
			gpsCallback = gpsC;
			gpsEnabledByUser = true;	
			enableGPS();
		}

		/**
		*	function for disabling gps by user.
		**/ 					
		function disableGpsWithCallback(){
			log("function disableGpsWithCallback()");	
			gpsCallback = null;
			gpsEnabledByUser = false;
			disableGPS();
		}
		
		/**
		*	Callback function for handling gps position.
		**/ 
		private function onPositionIQ(info){
			log("function onPositionIQ("+info+"), gpsEnabledByUser="+gpsEnabledByUser);
			if(gpsEnabledByUser == true){
				gpsCallback.invoke(info);
			}
			log("function onPositionIQ("+info+"), gpsEnabledByUser="+gpsEnabledByIQ);			
			gpsInfo = convertInfo(info);
			if(gpsEnabledByIQ == true){
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
	
		private function clearData(){
			batteryInfo = null;
		}
	
		private function getDataToSend(){
			log("function getDataToSend()");
			clearData();
			if(battery == true){
				batteryInfo = Toybox.System.getSystemStats().battery;
			}
			return {
			"BATTERY" => batteryInfo,
			"GPS" => gpsInfo
			};
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
			if(sendingInProgress ==false){
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