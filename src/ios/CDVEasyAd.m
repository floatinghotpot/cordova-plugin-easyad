//
//  CDVEasyAd.m
//  Ad Plugin for PhoneGap
//
//  Created by Liming Xie, 2014-7-28.
//
//  Copyright 2014 Liming Xie. All rights reserved.

#import "CDVEasyAd.h"
#import <Cordova/CDVDebug.h>
#import "MainViewController.h"

@interface CDVEasyAd()

- (void) __createBanner;
- (void) __showAd:(BOOL)show;
- (bool) __isLandscape;
- (void) __showInterstitial:(BOOL)show;

@end

@implementation CDVEasyAd

@synthesize bannerAtTop, bannerOverlap, offsetTopBar, isTesting;

@synthesize bannerView, interstitialAd, interstitialView;
@synthesize bannerIsVisible, bannerIsInitialized;

@synthesize bannerShow, interstitialAutoShow;

#pragma mark -
#pragma mark Public Methods

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView {
  self = (CDVEasyAd *)[super initWithWebView:theWebView];
  if (self) {
    // These notifications are required for re-placing the ad on orientation
    // changes. Start listening for notifications here since we need to
    // translate the Smart Banner constants according to the orientation.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(deviceOrientationChange:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];

      
      bannerShow = false;
      
      bannerAtTop = false;
      bannerOverlap = false;
      offsetTopBar = false;
      isTesting = false;
      
      interstitialAutoShow = false;
      
      bannerIsInitialized = false;
      bannerIsVisible = false;
  }
  return self;
}

- (void) showBanner:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

	NSUInteger argc = [args count];
	if (argc >= 2) {
        bannerShow = [[args objectAtIndex:0] boolValue];
        
        NSDictionary* options = [command.arguments objectAtIndex:1 withDefault:[NSNull null]];
        if ((NSNull *)options != [NSNull null]) {
            NSString* str = [options objectForKey:@"bannerAtTop"];
            bannerAtTop = str ? [str boolValue] : NO;
            
            str = [options objectForKey:@"overlap"];
            bannerOverlap = str ? [str boolValue] : NO;
            
            str = [options objectForKey:@"offsetTopBar"];
            offsetTopBar = str ? [str boolValue] : NO;

            str = [options objectForKey:@"isTesting"];
            isTesting = str ? [str boolValue] : NO;
        }
    }
    
    if(bannerView != nil) {
        [self __showAd:bannerShow];
        
    } else {
        [self __createBanner];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showAd:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;

	NSUInteger argc = [arguments count];
	if (argc >= 1) {
        NSString* showValue = [arguments objectAtIndex:0];
        BOOL show = showValue ? [showValue boolValue] : YES;
        [self __showAd:show];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) removeBanner:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    
    if(bannerView != nil) {
        [bannerView removeFromSuperview];
        bannerView = nil;
        
        [self resizeViews];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) requestInterstitial:(CDVInvokedUrlCommand *)command
{
    NSLog(@"requestInterstitial");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    BOOL is_iPad = ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad );
    if(is_iPad) {
        NSUInteger argc = [args count];
        if (argc >= 1) {
            NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
            if ((NSNull *)options != [NSNull null]) {
                NSString* str = [options objectForKey:@"isTesting"];
                isTesting = str ? [str boolValue] : NO;
                
                str = [options objectForKey:@"autoShow"];
                interstitialAutoShow = str ? [str boolValue] : NO;
            }
        }
        
        [self __cycleInterstitial];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"ADInterstitialAd is available on iPad only"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) showInterstitial:(CDVInvokedUrlCommand *)command
{
    NSLog(@"showInterstitial");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    [self __showInterstitial:YES];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass && self.bannerView) {
        
        CGRect superViewFrame = self.webView.superview.frame;
        if([self __isLandscape]) {
            superViewFrame.size.width = self.webView.superview.frame.size.height;
            superViewFrame.size.height = self.webView.superview.frame.size.width;
        }
        
        CGRect adViewFrameNew = self.bannerView.frame;
        adViewFrameNew.size = [self.bannerView sizeThatFits:superViewFrame.size];
        self.bannerView.frame = adViewFrameNew;
        
        [self resizeViews];
    }
}

- (void) resizeViews
{
    // Frame of the main container view that holds the Cordova webview.
    CGRect superViewFrame = self.webView.superview.frame;
    // Frame of the main Cordova webview.
    CGRect webViewFrame = self.webView.frame;

    // Let's calculate the new position and size
    CGRect superViewFrameNew = superViewFrame;
    CGRect webViewFrameNew = webViewFrame;

    // Handle changing Smart Banner constants for the user.
    bool isLandscape = [self __isLandscape];
    if( isLandscape ) {
        superViewFrameNew.size.width = superViewFrame.size.height;
        superViewFrameNew.size.height = superViewFrame.size.width;
    }
    
    // strange, superViewFrameNew.origin.y is not 0 in IOS6 ?
    superViewFrameNew.origin.y = 0;
    
    Class adBannerViewClass = NSClassFromString(@"ADBannerView");
	if (adBannerViewClass && self.bannerView) {
        CGRect bannerViewFrame = self.bannerView.frame;
        CGRect bannerViewFrameNew = bannerViewFrame;
        
        // If the ad is not showing or the ad is hidden, we don't want to resize anything.
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        BOOL adIsShowing = [parentView.subviews containsObject:self.bannerView] && (! self.bannerView.hidden);
        if(adIsShowing) {
            if(self.bannerAtTop) {
                // iOS7 Hack, handle the Statusbar
                MainViewController *mainView = (MainViewController*) self.webView.superview.window.rootViewController;
                BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
                CGFloat top = isIOS7 ? mainView.topLayoutGuide.length : 0.0;
                
                if(! self.offsetTopBar) top = 0.0;
                
                if(bannerOverlap) {
                    webViewFrameNew.origin.y = top;
                    
                    // banner view is subview of webview
                    bannerViewFrameNew.origin.y = 0;
                } else {
                    // move banner view to top
                    bannerViewFrameNew.origin.y = top;
                    
                    // banner view is brother view of web view
                    // move the web view to below
                    webViewFrameNew.origin.y = bannerViewFrameNew.origin.y + bannerViewFrame.size.height;
                }
                webViewFrameNew.size.height = superViewFrameNew.size.height - webViewFrameNew.origin.y;
            } else {
                // move webview to top
                webViewFrameNew.origin.y = 0;
                
                if(bannerOverlap) {
                    // banner view is subview of webview
                    bannerViewFrameNew.origin.y = webViewFrameNew.size.height - bannerViewFrame.size.height;
                    
                } else {
                    // banner view is brother view of webview
                    bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrame.size.height;
                    webViewFrameNew.size.height = superViewFrameNew.size.height - bannerViewFrame.size.height;
                }
            }
            
            webViewFrameNew.size.width = superViewFrameNew.size.width;
            bannerViewFrameNew.origin.x = (superViewFrameNew.size.width - bannerViewFrameNew.size.width) * 0.5f;
            
            self.bannerView.frame = bannerViewFrameNew;
            
            NSLog(@"x,y,w,h = %d,%d,%d,%d",
                  (int) bannerViewFrameNew.origin.x, (int) bannerViewFrameNew.origin.y,
                  (int) bannerViewFrameNew.size.width, (int) bannerViewFrameNew.size.height );
            
            
        } else {
            NSLog(@"banner hidden");
            webViewFrameNew = superViewFrameNew;
        }
        
        self.webView.frame = webViewFrameNew;
        
    } else {
        NSLog(@"banner not exists");
        self.webView.frame = superViewFrameNew;
    }

    NSLog(@"superview: %d x %d, webview: %d x %d",
          (int) superViewFrameNew.size.width, (int) superViewFrameNew.size.height,
          (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height );
}

#pragma mark -
#pragma mark Private Methods

- (void) __createBanner
{
	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
	if (adBannerViewClass && !self.bannerView) {
        CGRect superViewFrame = self.webView.superview.frame;
        if([self __isLandscape]) {
            superViewFrame.size.width = self.webView.superview.frame.size.height;
            superViewFrame.size.height = self.webView.superview.frame.size.width;
        }
        
        // set background color to black
        //self.webView.superview.backgroundColor = [UIColor blackColor];
        //self.webView.superview.tintColor = [UIColor whiteColor];

		self.bannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
		self.bannerView.delegate = self;
		self.bannerIsInitialized = YES;
		self.bannerIsVisible = NO;
        
        CGRect adViewFrameNew = self.bannerView.frame;
        adViewFrameNew.size = [self.bannerView sizeThatFits:superViewFrame.size];
        self.bannerView.frame = adViewFrameNew;
        
        NSLog(@"x,y,w,h = %d,%d,%d,%d",
              (int) adViewFrameNew.origin.x, (int) adViewFrameNew.origin.y,
              (int) adViewFrameNew.size.width, (int) adViewFrameNew.size.height );

        [self resizeViews];
	}
}

- (void) __showAd:(BOOL)show
{
	NSLog(@"CDViAd Show Ad: %d", show);
	
	if (!self.bannerIsInitialized){
		[self __createBanner];
	}
	
	if (!(NSClassFromString(@"ADBannerView") && self.bannerView)) { // ad classes not available
		return;
	}
	
	if (show == self.bannerIsVisible) { // same state, nothing to do
        if( self.bannerIsVisible) {
            [self resizeViews];
        }
	} else if (show) {
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        [parentView addSubview:self.bannerView];
        [parentView bringSubviewToFront:self.bannerView];
        [self resizeViews];
		
		self.bannerIsVisible = YES;
	} else {
		[self.bannerView removeFromSuperview];
        [self resizeViews];
		
		self.bannerIsVisible = NO;
	}
	
}

- (bool)__isLandscape {
    bool landscape = NO;
    
    //UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    //if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
    //    landscape = YES;
    //}
    // the above code cannot detect correctly if pad/phone lying flat, so we check the status bar orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            landscape = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            landscape = YES;
            break;
        default:
            landscape = YES;
            break;
    }
    
    return landscape;
}

- (void) __cycleInterstitial
{
    NSLog(@"__cycleInterstitial");

    // Clean up the old interstitial...
    interstitialAd.delegate = nil;
    interstitialAd = nil;
    
    // and create a new interstitial. We set the delegate so that we can be notified of when
    interstitialAd = [[ADInterstitialAd alloc] init];
    interstitialAd.delegate = self;
}

- (void) __showInterstitial:(BOOL)show
{
    NSLog(@"__showInterstitial");

	if (! self.interstitialAd){
		[self __cycleInterstitial];
	}
    
    if(interstitialAd && interstitialAd.loaded) {
        
        CGRect interstitialFrame = self.webView.superview.bounds;
        interstitialFrame.origin = CGPointMake(0, 0);
        self.interstitialView = [[UIView alloc] initWithFrame:interstitialFrame];
        [self.webView.superview addSubview:self.interstitialView];
        [interstitialAd presentInView:self.interstitialView];
        
    } else {
        
    }
}

#pragma mark -
#pragma ADBannerViewDelegate

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"Banner view begining action");

    [self writeJavascript:@"cordova.fireDocumentEvent('onClickAd');"];
    if (!willLeave) {
        
    }
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    NSLog(@"Banner view finished action");
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"Banner Ad loaded");
    
	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass) {
		if (! self.bannerIsVisible) {
			[self __showAd:YES];
		}

		[self writeJavascript:@"cordova.fireDocumentEvent('onReceiveAd');"];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Banner failed to load Ad");

	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass) {
		if ( self.bannerIsVisible ) {
			[self __showAd:NO];
		}
			;
		[self writeJavascript:[NSString
                               stringWithFormat:@"cordova.fireDocumentEvent('onFailedToReceiveAd', { 'error': '%@' });",
                               [error description]]];
    }
}

#pragma mark -
#pragma ADInterstitialAdDelegate

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd
{
    NSLog(@"Receive Interstitial Ad");
    
    if(self.interstitialAutoShow) {
        [self __showInterstitial:YES];
    }

    [self writeJavascript:@"cordova.fireDocumentEvent('onReceiveInterstitialAd');"];
}

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error
{
    NSLog(@"Failed To Receive Interstitial Ad");
    
    [self writeJavascript:[NSString
                           stringWithFormat:@"cordova.fireDocumentEvent('onFailedToReceiveInterstitialAd', { 'error': '%@' });",
                           [error description]]];
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
    NSLog(@"onDismissInterstitialAd");
    
    if(self.interstitialView) {
        [self.interstitialView removeFromSuperview];
        self.interstitialView = nil;
    }
    
    [self writeJavascript:@"cordova.fireDocumentEvent('onDismissInterstitialAd');"];
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd
{
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
}

- (void)deviceOrientationChange:(NSNotification *)notification{
    CGRect superViewFrame = self.webView.superview.frame;
    if([self __isLandscape]) {
        superViewFrame.size.width = self.webView.superview.frame.size.height;
        superViewFrame.size.height = self.webView.superview.frame.size.width;
    }
    
    Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass && self.bannerView) {
        CGRect adViewFrameNew = self.bannerView.frame;
        adViewFrameNew.size = [self.bannerView sizeThatFits:superViewFrame.size];
        self.bannerView.frame = adViewFrameNew;

        [self resizeViews];
    }
}

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:UIDeviceOrientationDidChangeNotification
		object:nil];

	self.bannerView.delegate = nil;
	self.bannerView = nil;
    
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
}

@end
