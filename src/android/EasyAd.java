package com.rjfun.cordova.plugin;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.mediation.admob.AdMobExtras;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;

import java.util.Iterator;
import java.util.Random;

import android.provider.Settings;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * This class represents the native implementation for the AdMob Cordova plugin.
 * This plugin can be used to request AdMob ads natively via the Google AdMob SDK.
 * The Google AdMob SDK is a dependency for this plugin.
 */
public class EasyAd extends CordovaPlugin {
    /** The adView to display to the user. */
    private AdView adView = null;
    /** if want banner view overlap webview, we will need this layout */
    private RelativeLayout adViewLayout = null;
    
    /** The interstitial ad to display to the user. */
    private InterstitialAd interstitialAd = null;
    
    private String publisherId = "";
    private AdSize adSize = null;
    
    /** Whether or not the ad should be positioned at top or bottom of screen. */
    private boolean bannerAtTop = false;
    /** Whether or not the banner will overlap the webview instead of push it up or down */
    private boolean bannerOverlap = false;
    private boolean offsetTopBar = false;
	private boolean isTesting = false;
	private boolean bannerShow = false;
	private JSONObject adExtras = null;

	private boolean autoShow = false;

    /** Common tag used for logging statements. */
    private static final String LOGTAG = "EasyAd";
    
    /** Cordova Actions. */
    private static final String ACTION_SHOW_BANNER = "showBanner";
    private static final String ACTION_REMOVE_BANNER = "removeBanner";
    private static final String ACTION_REQUEST_INTERSTITIAL = "requestInterstitial";
    private static final String ACTION_SHOW_INTERSTITIAL = "showInterstitial";
    
    @Override
    public boolean execute(String action, JSONArray inputs, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;
        if (ACTION_SHOW_BANNER.equals(action)) {
            boolean show = inputs.optBoolean(0);
            JSONObject options = inputs.optJSONObject(1);
            result = executeShowBanner(show, options, callbackContext);
            
        } else if (ACTION_REMOVE_BANNER.equals(action)) {
            result = removeBanner(callbackContext);
            
        } else if (ACTION_REQUEST_INTERSTITIAL.equals(action)) {
        	JSONObject options = inputs.optJSONObject(0);
            result = requestInterstitial(options, callbackContext);
            
        } else if (ACTION_SHOW_INTERSTITIAL.equals(action)) {
            result = showInterstitial(callbackContext);
            
        } else {
            Log.d(LOGTAG, String.format("Invalid action passed: %s", action));
            result = new PluginResult(Status.INVALID_ACTION);
        }
        
        if(result != null) callbackContext.sendPluginResult( result );
        
        return true;
    }
    
    private String loadPublisherId() {
    	String admobId = "";
    	
    	try {
    		PackageManager pm = cordova.getActivity().getPackageManager();
    	    ApplicationInfo ai = pm.getApplicationInfo(cordova.getActivity().getPackageName(), PackageManager.GET_META_DATA);
    	    Bundle bundle = ai.metaData;
    	    admobId = bundle.getString("admob_id");
            Log.w(LOGTAG, String.format("loading publisherId from Manifest: %s", this.publisherId));
    	    
    	} catch (NameNotFoundException e) {
    	    Log.e(LOGTAG, "Failed to load meta-data, NameNotFound: " + e.getMessage());
    	} catch (NullPointerException e) {
    	    Log.e(LOGTAG, "Failed to load meta-data, NullPointer: " + e.getMessage());  
    	    
    	}
    	
    	if(admobId == null || admobId.length() == 0) {
    		admobId = "ca-app-pub-6869992474017983/9375997553";	
            Log.w(LOGTAG, String.format("publisherId not found, using default: %s", admobId));
        }

    	return admobId;
    }
    
    private PluginResult executeShowBanner(boolean show, JSONObject options, CallbackContext callbackContext) {
    	Log.w(LOGTAG, "executeShowBanner");
    	
    	this.bannerShow  = show;
        this.publisherId = options.optString( "publisherId" );
        this.adSize = adSizeFromString( options.optString( "adSize" ) );
        this.bannerAtTop = options.optBoolean( "bannerAtTop" );
        this.bannerOverlap = options.optBoolean( "overlap" );
        this.offsetTopBar = options.optBoolean( "offsetTopBar" );
        this.isTesting  = options.optBoolean( "isTesting" );
        this.adExtras  = options.optJSONObject("adExtras");

        Log.w(LOGTAG, String.format("publisherId: '%s'", this.publisherId));
        
        if(this.publisherId.length() == 0) {
        	this.publisherId = loadPublisherId();
        }
        
        if(adView != null) {
        	if( show ) {
        		return requestBannerAd(options, callbackContext );
        	} else {
        		return showBannerAd(false, callbackContext);
        	}
        }
        
    	return createBannerAd(callbackContext);
	}

    private PluginResult createBannerAd(final CallbackContext callbackContext) {
    	Log.w(LOGTAG, "createBannerAd");
    	
        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
                if(adView == null) {
                    adView = new AdView(cordova.getActivity());
                    adView.setAdUnitId(publisherId);
                    adView.setAdSize(adSize);
                    adView.setAdListener(new BannerListener());
                }
                if (adView.getParent() != null) {
                    ((ViewGroup)adView.getParent()).removeView(adView);
                }
                if(bannerOverlap) {
                    ViewGroup parentView = (ViewGroup) webView;
                    
                    adViewLayout = new RelativeLayout(cordova.getActivity());
                    RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                            RelativeLayout.LayoutParams.MATCH_PARENT,
                            RelativeLayout.LayoutParams.MATCH_PARENT);
                    parentView.addView(adViewLayout, params);
                    
                    RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams(
                        RelativeLayout.LayoutParams.MATCH_PARENT,
                        RelativeLayout.LayoutParams.WRAP_CONTENT);
                    params2.addRule(bannerAtTop ? RelativeLayout.ALIGN_PARENT_TOP : RelativeLayout.ALIGN_PARENT_BOTTOM);
                    adViewLayout.addView(adView, params2);
                    
                } else {
                    ViewGroup parentView = (ViewGroup) webView.getParent();
                    if (bannerAtTop) {
                        parentView.addView(adView, 0);
                    } else {
                        parentView.addView(adView);
                    }
                }
                adView.loadAd( buildAdRequest() );
                callbackContext.success();
            }
        });
        
        return null;
    }

    private PluginResult requestBannerAd(JSONObject options, final CallbackContext callbackContext) {
    	Log.w(LOGTAG, "requestBannerAd");
    	
        this.isTesting  = options.optBoolean( "isTesting" );
        this.adExtras  = options.optJSONObject( "extras" );

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                adView.loadAd( buildAdRequest() );
                if(callbackContext != null) callbackContext.success();
            }
        });
        
        return null;
    }
    
    private PluginResult showBannerAd(final boolean show, final CallbackContext callbackContext) {
    	Log.w(LOGTAG, "showBannerAd");
    	
        if(adView == null) {
            return new PluginResult(Status.ERROR, "adView is null, call createBannerView first.");
        }

        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
                adView.setVisibility( show ? View.VISIBLE : View.GONE );
                if(callbackContext != null) callbackContext.success();
            }
        });
        
        return null;
    }
    
    private PluginResult removeBanner(final CallbackContext callbackContext) {
	  	Log.w(LOGTAG, "removeBanner");
	  	
	  	cordova.getActivity().runOnUiThread(new Runnable() {
		    @Override
		    public void run() {
				if (adView != null) {
					ViewGroup parentView = (ViewGroup)adView.getParent();
					if(parentView != null) {
						parentView.removeView(adView);
					}
					adView = null;
				}
				if (adViewLayout != null) {
					ViewGroup parentView = (ViewGroup)adViewLayout.getParent();
					if(parentView != null) {
						parentView.removeView(adViewLayout);
					}
					adViewLayout = null;
				}
				callbackContext.success();
		    }
	  	});
	  	
	  	return null;
    }
    
    private AdRequest buildAdRequest() {
        AdRequest.Builder request_builder = new AdRequest.Builder();
        if (isTesting) {
            // This will request test ads on the emulator and deviceby passing this hashed device ID.
        	String ANDROID_ID = Settings.Secure.getString(cordova.getActivity().getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
            String deviceId = md5(ANDROID_ID).toUpperCase();
            request_builder = request_builder.addTestDevice(deviceId).addTestDevice(AdRequest.DEVICE_ID_EMULATOR);
        }

        Bundle bundle = new Bundle();
        bundle.putInt("cordova", 1);
        if(adExtras != null) {
            Iterator<String> it = adExtras.keys();
            while (it.hasNext()) {
                String key = it.next();
                try {
                    bundle.putString(key, adExtras.get(key).toString());
                } catch (JSONException exception) {
                    Log.w(LOGTAG, String.format("Caught JSON Exception: %s", exception.getMessage()));
                }
            }
        }
        AdMobExtras adextras = new AdMobExtras(bundle);
        request_builder = request_builder.addNetworkExtras( adextras );
        AdRequest request = request_builder.build();
        
        return request;
    }
    
    private PluginResult requestInterstitial(JSONObject options, final CallbackContext callbackContext) {
        this.publisherId = options.optString( "publisherId" );
        this.isTesting  = options.optBoolean( "isTesting" );
        this.adExtras  = options.optJSONObject( "extras" );
        this.autoShow  = options.optBoolean( "autoShow" );

        if(this.publisherId.length() == 0) {
        	this.publisherId = loadPublisherId();
        }

        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
                interstitialAd = new InterstitialAd(cordova.getActivity());
                interstitialAd.setAdUnitId(publisherId);
                interstitialAd.setAdListener( new InterstitialListener() );
                
                interstitialAd.loadAd( buildAdRequest() );
                
                callbackContext.success();
            }
        });
        return null;
    }
    
	private PluginResult showInterstitial(CallbackContext callbackContext) {
        if(interstitialAd == null) {
            return new PluginResult(Status.ERROR, "call requestInterstitial first.");
        }
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
				if( interstitialAd.isLoaded() ) {
					interstitialAd.show();
				}
				if(delayCallback != null) delayCallback.success();
            }
        });
        
        return null;
    }

    public class BasicListener extends AdListener {
        @Override
        public void onAdFailedToLoad(int errorCode) {
            webView.loadUrl(String.format(
                    "javascript:cordova.fireDocumentEvent('onFailedToReceiveAd', { 'error': %d, 'reason':'%s' });",
                    errorCode, getErrorReason(errorCode)));
        }
        
        @Override
        public void onAdLeftApplication() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onLeaveToAd');");
        }
    }
    
    private class BannerListener extends BasicListener {
        @Override
        public void onAdLoaded() {
            Log.w("AdMob", "BannerAdLoaded");
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onReceiveAd');");
            
            if(bannerShow) {
            	showBannerAd(true, null);
            }
        }

        @Override
        public void onAdOpened() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onPresentAd');");
        }
        
        @Override
        public void onAdClosed() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onDismissAd');");
        }
        
    }
    
    private class InterstitialListener extends BasicListener {
        @Override
        public void onAdLoaded() {
            Log.w("AdMob", "InterstitialAdLoaded");
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onReceiveInterstitialAd');");
            
            if(autoShow) {
            	showInterstitial(null);
            }
        }

        @Override
        public void onAdOpened() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onPresentInterstitialAd');");
        }
        
        @Override
        public void onAdClosed() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onDismissInterstitialAd');");
        }
        
    }
    
    @Override
    public void onPause(boolean multitasking) {
        if (adView != null) {
            adView.pause();
        }
        super.onPause(multitasking);
    }
    
    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        if (adView != null) {
            adView.resume();
        }
    }
    
    @Override
    public void onDestroy() {
        if (adView != null) {
            adView.destroy();
        }
        super.onDestroy();
    }
    
    /**
     * Gets an AdSize object from the string size passed in from JavaScript.
     * Returns null if an improper string is provided.
     *
     * @param size The string size representing an ad format constant.
     * @return An AdSize object used to create a banner.
     */
    public static AdSize adSizeFromString(String size) {
        if ("BANNER".equals(size)) {
            return AdSize.BANNER;
        } else if ("IAB_MRECT".equals(size)) {
            return AdSize.MEDIUM_RECTANGLE;
        } else if ("IAB_BANNER".equals(size)) {
            return AdSize.FULL_BANNER;
        } else if ("IAB_LEADERBOARD".equals(size)) {
            return AdSize.LEADERBOARD;
        } else if ("SMART_BANNER".equals(size)) {
            return AdSize.SMART_BANNER;
        } else {
            return AdSize.SMART_BANNER;
        }
    }

    
    /** Gets a string error reason from an error code. */
    public String getErrorReason(int errorCode) {
      String errorReason = "";
      switch(errorCode) {
        case AdRequest.ERROR_CODE_INTERNAL_ERROR:
          errorReason = "Internal error";
          break;
        case AdRequest.ERROR_CODE_INVALID_REQUEST:
          errorReason = "Invalid request";
          break;
        case AdRequest.ERROR_CODE_NETWORK_ERROR:
          errorReason = "Network Error";
          break;
        case AdRequest.ERROR_CODE_NO_FILL:
          errorReason = "No fill";
          break;
      }
      return errorReason;
    }
    
    public static final String md5(final String s) {
        try {
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(s.getBytes());
            byte messageDigest[] = digest.digest();
            StringBuffer hexString = new StringBuffer();
            for (int i = 0; i < messageDigest.length; i++) {
                String h = Integer.toHexString(0xFF & messageDigest[i]);
                while (h.length() < 2)
                    h = "0" + h;
                hexString.append(h);
            }
            return hexString.toString();

        } catch (NoSuchAlgorithmException e) {
        }
        return "";
    }
}

