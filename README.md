# cordova-plugin-easyad #

This is the easiest way to add Ad to your cordova apps, less code and smaller package size. 

* How easy? 
Single line of js code.

* How small the package can be? 
Android APK, ~578KB. iOS IPA, ~228KB. (measured with single HTML page, without splash images)

Platform SDK supported (SDK included):
* Android, using AdMob, Google Play Service v4.4.
* iOS, using Apple iAd instead of AdMob (to minimize package size)

Required:
* Cordova >= 2.9.0

## See Also ##
Besides EasyAd plugin, there are some other options, all working on cordova:
* [cordova-plugin-admob](https://github.com/floatinghotpot/cordova-plugin-admob), Google AdMob service. 
* [cordova-plugin-iad](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [cordova-plugin-flurry](https://github.com/floatinghotpot/cordova-plugin-flurry), Flurry Ads service.

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-easyad.git 

Note: 
Ensure you have a proper AdMob account and create an Id for your android app. For iOS, admob key not needed, since it will link to your Apple Id.

## Quick start with cordova CLI ##
    cordova create testad com.rjfun.testad TestAd
    cd testad
    cordova platform add android
    cordova platform add ios
    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-easyad.git
    rm -r www/*
    cp plugins/com.rjfun.cordova.plugin.easyad/test/* www/
    cordova prepare; cordova run android; cordova run ios;
    // or import into Xcode / eclipse

## Javascript API ##

APIs:
- showBanner(true/false, options, success, fail);
- removeBanner(success, fail);
- requestInterstital(options, success, fail);
- showInterstitial(success, fail);

Events: 
- for banner: onReceiveAd, onFailedToReceiveAd, onPresentAd, onDismissAd, onLeaveToAd
- for interstitial: onReceiveInterstitialAd, onPresentInterstitialAd, onDismissInterstitialAd

## Example code ##
Call the following code inside onDeviceReady(), because only after device ready you will have the plugin working.
```javascript
// --- copy the code snippets to your js file --
function initAd(){
	if ( window.plugins && window.plugins.EasyAd ) {
		var ad = window.plugins.EasyAd;
		
		window.showBanner = ad.showBanner;
		window.requestInterstitial = ad.requestInterstitial;
		window.showInterstitial = ad.showInterstitial;
		
		registerAdEvents();
	} else {
		// avoid error when running your web app in PC broswer
		window.showBanner = function(){};
		window.requestInterstitial = function(){};
		window.showInterstitial = function(){};
	}
}

function registerAdEvents() {
	document.addEventListener('onReceiveAd', function(){
	});
	document.addEventListener('onFailedToReceiveAd', function(data){
	});
	document.addEventListener('onPresentAd', function(){
	});
	document.addEventListener('onDismissAd', function(){
	});
	document.addEventListener('onLeaveToAd', function(){
	});
	document.addEventListener('onReceiveInterstitialAd', function(){
    });
	document.addEventListener('onPresentInterstitialAd', function(){
    });
	document.addEventListener('onDismissInterstitialAd', function(){
    });
}
// --- end of snippets ---

var admob_ios_key = 'ca-app-pub-6869992474017983/4806197152';
var admob_android_key = 'ca-app-pub-6869992474017983/9375997553';
var admob_id = (/(android)/i.test(navigator.userAgent)) ? admob_android_key : admob_ios_key;

var adOptions = {
	    publisherId: admob_id,
            bannerAtTop: false, // by default, false. set to true, to make banner at top
            overlap: false,  // by default, false. set to true, to allow banner view overlap web content
            offsetTopBar: false, // by default, false. set to true, to avoid ios 7 status bar overlap
            isTesting: false, // by default, false. set to true, for testing purpose
	    autoShow: true // false by default, set to true to display interstitial ad once loaded.
        };

function inYourCode() {
	// some where after onDeviceReady
	initAd();
	
	// the most simple code to show Ad
	showBanner(true, adOptions);
	requestInterstitial(adOptions);
	showInterstitial();
}
	
```

See the working example code in [demo under test folder](test/index.html), and here are some screenshots.
 
## Donate ##
 To support this project, donation is welcome.  
* [Donate directly via Payoneer / PayPal / AliPay](http://floatinghotpot.github.io/#donate)

