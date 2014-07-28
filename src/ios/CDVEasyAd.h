//
//  CDViAd.h
//  iAd Plugin for PhoneGap/Cordova
//
//  Created by shazron on 10-07-12.
//  Copyright 2010 Shazron Abdullah. All rights reserved.
//  Cordova v1.5.0 Support added 2012 @RandyMcMillan
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <iAd/iAd.h>

@interface CDVEasyAd : CDVPlugin <ADBannerViewDelegate, ADInterstitialAdDelegate> {

}

@property (assign) BOOL bannerAtTop;
@property (assign) BOOL bannerOverlap;
@property (assign) BOOL offsetTopBar;
@property (assign) BOOL isTesting;

@property (nonatomic, retain) ADBannerView* bannerView;
@property (nonatomic, retain) ADInterstitialAd* interstitialAd;
@property (nonatomic, retain) UIView * interstitialView;

@property (assign) BOOL bannerIsVisible;
@property (assign) BOOL bannerIsInitialized;
@property (assign) BOOL bannerShow;
@property (assign) BOOL interstitialAutoShow;

- (void) showBanner:(CDVInvokedUrlCommand *)command;
- (void) removeBanner:(CDVInvokedUrlCommand *)command;

- (void) requestInterstitial:(CDVInvokedUrlCommand *)command;
- (void) showInterstitial:(CDVInvokedUrlCommand *)command;

@end
