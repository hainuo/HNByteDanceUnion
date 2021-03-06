//
//  HNByteDanceUnion.m
//  HNByteDanceUnion
//
//  Created by hainuo on 2021/4/2.
//

#import "HNByteDanceUnion.h"
#import "UZEngine/NSDictionaryUtils.h"
#import <BUAdSDK/BUAdSDK.h>
#import <objc/runtime.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@interface BUNativeExpressBannerView (HNByteDanceUnion)
@property (nonatomic, assign) NSString *adId;
@end

@implementation BUNativeExpressBannerView (HNByteDanceUnion)
static void *nl_sqlite_adId_key = &nl_sqlite_adId_key;
- (void)setAdId:(NSString *)adId {
	objc_setAssociatedObject(self, nl_sqlite_adId_key, adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)adId {
	return [objc_getAssociatedObject(self,nl_sqlite_adId_key) stringValue];
}
@end

@interface BUNativeExpressAdView (HNByteDanceUnion)
@property (nonatomic, assign) NSString *adId;
@end
@implementation BUNativeExpressAdView (HNByteDanceUnion)
static void *n2_sqlite_adId_key = &n2_sqlite_adId_key;
- (void)setAdId:(NSString *)adId {
	objc_setAssociatedObject(self, n2_sqlite_adId_key, adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)adId {
	return [objc_getAssociatedObject(self,n2_sqlite_adId_key) stringValue];
}
@end
@interface HNByteDanceUnion ()<BUSplashAdDelegate,BUSplashZoomOutViewDelegate,BUNativeExpressBannerViewDelegate,BUNativeExpressFullscreenVideoAdDelegate,BUNativeExpressAdViewDelegate>
@property (nonatomic, strong) BUSplashAdView *splashAdView;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) NSObject *splashAdObserver;

//bannerAd

@property (nonatomic, strong) NSObject *bannerAdObserver;
@property (nonatomic,strong) BUNativeExpressBannerView *bannerAdView;

//chaping
@property (nonatomic, strong) NSObject *quanpingAdObserver;
@property (nonatomic, strong) BUNativeExpressFullscreenVideoAd *fullScreenAd;
@property (nonatomic) BOOL showFullAd;


//xinxiliu

@property (nonatomic, strong) NSObject *expressAdObserver;
@property (nonatomic, strong) BUNativeExpressAdManager *nativeExpressAdManager;
@property (nonatomic,strong) BUNativeExpressAdView *expressAdView;
@end



@implementation HNByteDanceUnion

#pragma mark - Override UZEngine
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
	// ?????????????????????????????????
	NSLog(@"HNBytedanceUnion ????????????");


}

- (id)initWithUZWebView:(UZWebView *)webView {
	if (self = [super initWithUZWebView:webView]) {
		// ???????????????
		NSLog(@"HNBytedanceUnionUZWebView  ????????????");
	}
	return self;
}

- (void)dispose {
	// ????????????????????????????????????
	NSLog(@"HNBytedanceUnion  ????????????");
	[self removeQuanpingAdNotification];
    
	[self removeBannerAdNotification];
	self.bannerAdView = nil;
	[self removeSplashADNotification];
	self.splashAdView = nil;

	[self removeExpressAdNotification];
	_expressAdView = nil;

}
-(UIViewController *) rootViewController{
    UIWindow *window = [self getKeyWindow];
    return window?window.rootViewController:(self.viewController.navigationController?:self.viewController);
}
- (UIWindow *)getKeyWindow
{
	if (@available(iOS 13.0, *))
	{
        return  [UIApplication sharedApplication].windows[0];
	}
	else
	{
		return [UIApplication sharedApplication].keyWindow;
	}
	return nil;
}

#pragma mark - BytedanceUnion init

JS_METHOD(init:(UZModuleMethodContext *)context){

	NSDictionary *params = context.param;
	NSString *appId  = [params stringValueForKey:@"appId" defaultValue:nil];
	if(!appId) {
		[context callbackWithRet:@{@"code":@0,@"msg":@"??????appId?????????"} err:nil delete:YES];
		return;
	}
	BUAdSDKConfiguration *configuration = [BUAdSDKConfiguration configuration];
	configuration.territory = BUAdSDKTerritory_CN;
	configuration.GDPR = @(0);
	configuration.coppa = @(0);
	configuration.CCPA = @(1);
	configuration.appID = appId;
//    configuration.logLevel = BUAdSDKLogLevelDebug;
    [BUAdSDKManager startWithAsyncCompletionHandler:^(BOOL success, NSError *error) {

        if (success) {
			 //shezhi keyi
			 [context callbackWithRet:@{@"code":@1,@"msg":@"??????????????????",@"version":[BUAdSDKManager SDKVersion]} err:nil delete:NO];
		 }else{
			 //shezhi bukeyi
			 NSDictionary *errorInfo  = @{};
			 if(error && error.userInfo) {
				 errorInfo = error.userInfo;
			 }
			 [context callbackWithRet:@{@"code":@0,@"msg":@"??????????????????",@"userInfo":errorInfo,@"version":[BUAdSDKManager SDKVersion]} err:nil delete:NO];
		 }
	 }];

}

#pragma mark - ?????? IDFA
JS_METHOD(requestATT:(UZModuleMethodContext *)context){
    if (@available(iOS 14, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
    //            ATTrackingManagerAuthorizationStatusNotDetermined = 0,
    //            ATTrackingManagerAuthorizationStatusRestricted,
    //            ATTrackingManagerAuthorizationStatusDenied,
    //            ATTrackingManagerAuthorizationStatusAuthorized
               
                [context callbackWithRet:@{@"code":@1,@"status":@(status),@"msg":@"??????????????????????????????status",@"IDFA": [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]} err:nil delete:YES];
            }];
        });
    } else {
        // Fallback on earlier versions
        [context callbackWithRet:@{@"code":@2,@"msg":@"????????????iOS14.0 ???????????????????????????"} err:nil delete:YES];
    }
    
}

#pragma mark - SplashAd ??????????????????
JS_METHOD(addSplashAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	NSDictionary *ret = [params dictValueForKey:@"ret" defaultValue:@{}];
	NSString *x = [ret stringValueForKey:@"x" defaultValue:nil];
	NSString *y = [ret stringValueForKey:@"y" defaultValue:nil];
	NSString *width = [ret stringValueForKey:@"width" defaultValue:nil];
	NSString *height = [ret stringValueForKey:@"height" defaultValue:nil];

//	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];
//	bool fixed = [params boolValueForKey:@"fixed" defaultValue:NO];


    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect frame = CGRectMake([x floatValue], [y floatValue], [width floatValue], [height floatValue]);
        self.splashAdView = [[BUSplashAdView alloc] initWithSlotID:adId frame:frame];
        // tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
        self.splashAdView.tolerateTimeout = 3;
        //??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
        self.splashAdView.delegate = self;
        
        self.startTime = CACurrentMediaTime();
        [self.splashAdView loadAdData];
        UIWindow *window = [UIApplication sharedApplication].windows[0];
        UIViewController *parentVC = window.rootViewController;
        [parentVC.view addSubview:self.splashAdView];
        self.splashAdView.rootViewController=parentVC;
        
	[context callbackWithRet:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"doLoad",@"msg":@"??????????????????????????????"} err:nil delete:NO];
        
    });
    //    return @{@"code":@1,@"msg":@"??????!"};
        __weak typeof(self) _self = self;
    //    __weak typeof(context) _context=context;
        if(!self.splashAdObserver) {
            self.splashAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadSplashAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

                                             NSLog(@"?????????loadSplashAdObserver?????????%@",note.object);
                                             __strong typeof(_self) self = _self;
                                             if(!self) return;
    //        __strong typeof(_context) context = _context;
                                             [context callbackWithRet:note.object err:nil delete:NO];
                         }];
        }
}

- (void)removeSplashAdView {
	if (self.splashAdView) {
		[self.splashAdView removeFromSuperview];
		self.splashAdView = nil;
	}

	[self removeSplashADNotification];
}

-(void) removeSplashADNotification {
	//??????????????????
	if(self.splashAdObserver) {
		NSLog(@"??????????????????");
		[[NSNotificationCenter defaultCenter] removeObserver:self.splashAdObserver name:@"loadSplashAdObserver" object:nil];
		self.splashAdObserver = nil;
	}
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"onAdRemove",@"adeventType":@"onAdRemoved",@"msg":@"?????????????????????",@"code":@1}];
}

- (void)splashAdDidLoad:(BUSplashAdView *)splashAd {

	NSLog(@"splashAD has loaded");
	if (splashAd.zoomOutView) {
		NSLog(@"splashAD zoomoutview has loaded");
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *parentVC = [self rootViewController];
            [parentVC.view addSubview:splashAd.zoomOutView];
            [parentVC.view bringSubviewToFront:splashAd];
            //Add this view to your container
            [parentVC.view insertSubview:splashAd.zoomOutView belowSubview:splashAd];
            splashAd.zoomOutView.rootViewController = parentVC;
            splashAd.zoomOutView.delegate = self;
        });
		
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adLoaded",@"msg":@"?????????????????????????????????"}];
}

- (void)splashAdDidClose:(BUSplashAdView *)splashAd {

	// Be careful not to say 'self.splashadview = nil' here.
	// Subsequent agent callbacks will not be triggered after the 'splashAdView' is released early.

	[self pbu_logWithSEL:_cmd msg:@"splashAd has been closed"];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adClosed",@"msg":@"?????????????????????"}];

	[self removeSplashAdView];
}

- (void)splashAdDidClick:(BUSplashAdView *)splashAd {
	if (splashAd.zoomOutView) {
		[splashAd.zoomOutView removeFromSuperview];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adClicked",@"msg":@"????????????????????????"}];
	// Be careful not to say 'self.splashadview = nil' here.
	// Subsequent agent callbacks will not be triggered after the 'splashAdView' is released early.
	[splashAd removeFromSuperview];
	[self pbu_logWithSEL:_cmd msg:@"spashAd has been clicked"];

}

- (void)splashAdDidClickSkip:(BUSplashAdView *)splashAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adSkipClicked",@"msg":@"??????????????????????????????"}];
	// Click Skip, there is no subsequent operation, completely remove 'splashAdView', avoid memory leak

	[self pbu_logWithSEL:_cmd msg:@"splashAd has been skipped"];
//	[self removeSplashAdView];
}

- (void)splashAd:(BUSplashAdView *)splashAd didFailWithError:(NSError *)error {
	// Display fails, completely remove 'splashAdView', avoid memory leak
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[self pbu_logWithSEL:_cmd msg:@"splashAd has been removed"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adloadFail",@"splashAdType":@"loadSplashAd",@"msg":@"??????????????????",@"userInfo":errorInfo,@"code":@0}];


	[self removeSplashAdView];
}



- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adCloseOtherController",@"splashAdType":@"loadSplashAd",@"msg":@"?????????????????????????????????",@"interactionType":@(interactionType),@"code":@1}];
}

- (void)splashAdCountdownToZero:(BUSplashAdView *)splashAd {
	// When the countdown is over, it is equivalent to clicking Skip to completely remove 'splashAdView' and avoid memory leak
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adTimeOver",@"splashAdType":@"loadSplashAd",@"msg":@"??????????????????",@"code":@1}];
	[self pbu_logWithSEL:_cmd msg:@"splashAd countdown to 0"];
}

#pragma mark - BUSplashZoomOutViewDelegate
- (void)splashZoomOutViewAdDidClick:(BUSplashZoomOutView *)splashAd {
	[self pbu_logWithSEL:_cmd msg:@"splashAdZoomOut has been clicked"];
}

- (void)splashZoomOutViewAdDidClose:(BUSplashZoomOutView *)splashAd {
	// Click close, completely remove 'splashAdView', avoid memory leak
	[self removeSplashAdView];
	[self pbu_logWithSEL:_cmd msg:@"splashAdZoomOut has been closed"];
}

- (void)splashZoomOutViewAdDidAutoDimiss:(BUSplashZoomOutView *)splashAd {
	// Back down at the end of the countdown to completely remove the 'splashAdView' to avoid memory leaks
	[self pbu_logWithSEL:_cmd msg:@"splashAdZoomOut has been aoto dimiss"];
}

- (void)splashZoomOutViewAdDidCloseOtherController:(BUSplashZoomOutView *)splashAd interactionType:(BUInteractionType)interactionType {
	// No further action after closing the other Controllers, completely remove the 'splashAdView' and avoid memory leaks
	[self pbu_logWithSEL:_cmd msg:@"splashAdZoomOut has been closed by other controller"];
}


- (void)pbu_logWithSEL:(SEL)sel msg:(NSString *)msg {
	CFTimeInterval endTime = CACurrentMediaTime();
	NSLog(@"SplashAdView In AppDelegate (%@) total run time: %gs, extraMsg:%@", NSStringFromSelector(sel), endTime - self.startTime, msg);
}

#pragma mark banner??????
JS_METHOD(addBannerAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	NSDictionary *ret = [params dictValueForKey:@"ret" defaultValue:@{}];
	float x = [ret floatValueForKey:@"x" defaultValue:0.0];
	float y = [ret floatValueForKey:@"y" defaultValue:0.0];
	float width = [ret floatValueForKey:@"width" defaultValue:415];
	float height = [ret floatValueForKey:@"height" defaultValue:50];

	bool fixed = [params boolValueForKey:@"fixed" defaultValue:NO];
	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];

	int refreshInterval = [params intValueForKey:@"refreshInterval" defaultValue:30];
	if(refreshInterval>=30 && refreshInterval <=120) {
		self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self rootViewController] adSize:CGSizeMake(width, height) interval:refreshInterval];
	}else{
		self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self rootViewController] adSize:CGSizeMake(width, height)];
	}
	if(self.bannerAdView.superview) {
		[self.bannerAdView removeFromSuperview];
	}

	self.bannerAdView.frame = CGRectMake(x,y,width,height);
	self.bannerAdView.adId = adId;
	self.bannerAdView.delegate = self;
	[self.bannerAdView loadAdData];

//    return @{@"code":@1,@"msg":@"??????!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.bannerAdObserver) {
		self.bannerAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadBannerAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                 NSLog(@"????????? loadBannerAdObserver ?????????%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
		                                 NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                 if([placeId isEqualToString:adId]) {
							 NSString *bannerAdType = [note.object stringValueForKey:@"bannerAdType" defaultValue:nil];
							 NSString *eventType = [note.object stringValueForKey:@"eventType" defaultValue:nil];

							 NSLog(@" bannerAdType %@ eventType %@",bannerAdType,eventType);

							 if([bannerAdType isEqualToString:@"loadBannerAd"] && [eventType isEqualToString:@"adRendered"]) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     //??????????????? ?????????????????????????????????view
                                     [self addSubview:self.bannerAdView fixedOn:fixedOn fixed:fixed];
                                     
                                     [[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"addViewToMainView",@"bannerAdType":@"loadBannerAd",@"adId":adId,@"msg":@"????????????????????????",@"height":@(self.bannerAdView.bounds.size.height),@"width":@(self.bannerAdView.bounds.size.width),@"code":@1}];
                                 });
							 }

							 [context callbackWithRet:note.object err:nil delete:NO];
						 }
					 }];
	}
	[context callbackWithRet:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"doLoad",@"msg":@"??????????????????????????????"} err:nil delete:NO];
}
JS_METHOD_SYNC(closeBannerAd:(UZModuleMethodContext *)context){
	[self removeBannerAdView];
	return @{@"code":@1,@"bannerAdType":@"closeBannerAd",@"eventType":@"doClose",@"msg":@"??????????????????????????????"};
}
-(void) removeBannerAdView {
	// ??????????????????
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self.bannerAdView.superview) {
			[self.bannerAdView removeFromSuperview];
		}
		self.bannerAdView = nil;
	});
	[self removeBannerAdNotification];
}

-(void) removeBannerAdNotification {
	//??????????????????
	if(self.bannerAdObserver) {
		NSLog(@"??????????????????");
		[[NSNotificationCenter defaultCenter] removeObserver:self.bannerAdObserver name:@"loadBannerAdObserver" object:nil];
		self.bannerAdObserver = nil;
	}
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoaded",@"bannerAdType":@"loadBannerAd",@"msg":@"??????????????????",@"code":@1}];
}
#pragma mark banner delegate BUNativeExpressBannerViewDelegate
/**
   This method is called when bannerAdView ad slot loaded successfully.  ??????????????????
   @param bannerAdView : view for bannerAdView
 */
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoaded",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"??????????????????",@"code":@1}];

}

/**
   This method is called when bannerAdView ad slot failed to load.
   @param error : the reason of error
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoadFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"userInfo":errorInfo,@"msg":@"??????????????????",@"code":@0}];

	[self removeBannerAdView];
}

/**
        ??????????????????
   This method is called when rendering a nativeExpressAdView successed.
 */
- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adRendered",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when a nativeExpressAdView failed to render.
    ??????????????????
   @param error : the reason of error
 */
- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError *)error {

	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adRenderFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"??????????????????",@"userInfo":errorInfo,@"code":@0}];
	[self removeBannerAdView];
}

/**
   This method is called when bannerAdView ad slot showed new ad.
 */
- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adWillShow",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when bannerAdView is clicked.
 */
- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adClicked",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when the user clicked dislike button and chose dislike reasons.
   @param filterwords : the array of reasons for dislike.
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterwords {
	NSMutableArray<NSDictionary *> *words = @[].mutableCopy;
	if(filterwords.count>0) {
		for (BUDislikeWords *filterword in filterwords) {
			[words addObject:@{@"name":filterword.name,@"dislikeId":filterword.dislikeID,@"isSelected":@(filterword.isSelected)}];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adDislikCliecked",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"???????????????dislike??????",@"words":words,@"code":@1}];
}

/**
   This method is called when another controller has been closed.
   @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressBannerAdViewDidCloseOtherController:(BUNativeExpressBannerView *)bannerAdView interactionType:(BUInteractionType)interactionType {
//    typedef NS_ENUM(NSInteger, BUInteractionType) {
//        BUInteractionTypeCustorm = 0,
//        BUInteractionTypeNO_INTERACTION = 1,  // pure ad display
//        BUInteractionTypeURL = 2,             // open the webpage using a browser
//        BUInteractionTypePage = 3,            // open the webpage within the app
//        BUInteractionTypeDownload = 4,        // download the app
//        BUInteractionTypePhone = 5,           // make a call
//        BUInteractionTypeMessage = 6,         // send messages
//        BUInteractionTypeEmail = 7,           // send email
//        BUInteractionTypeVideoAdDetail = 8    // video ad details page
//    };

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"AdCloseOtherController",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"banner??????????????????????????????",@"interactionType":@(interactionType),@"code":@1}];
}

/**
   This method is called when the Ad view container is forced to be removed.
   @param bannerAdView : Express Banner Ad view container
 */
- (void)nativeExpressBannerAdViewDidRemoved:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"AdCloseOtherController",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"banner??????????????????????????????",@"code":@1}];
	[UIView animateWithDuration:0.25 animations:^{
	         self.bannerAdView.alpha = 0;
	 } completion:^(BOOL finished) {
	         [self removeBannerAdView];
	 }];
}

#pragma mark ???????????????
JS_METHOD(addQuanpingAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
    BOOL showFullAd = [params boolValueForKey:@"showFullAd" defaultValue:NO];
    
    self.showFullAd = showFullAd;
	
    self.fullScreenAd = [[BUNativeExpressFullscreenVideoAd alloc] initWithSlotID:adId];
	// ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
	self.fullScreenAd.delegate = self;


//    return @{@"code":@1,@"msg":@"??????!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.quanpingAdObserver) {
		self.quanpingAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadQuanpingAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                   NSLog(@"????????? loadQuanpingAdObserver ?????????%@",note.object);
		                                   __strong typeof(_self) self = _self;
		                                   if(!self) return;
		                                   [context callbackWithRet:note.object err:nil delete:NO];
					   }];
	}
    [self.fullScreenAd loadAdData];
	[context callbackWithRet:@{@"code":@1,@"quanpingAdType":@"loadQuanpingAd",@"eventType":@"doLoad",@"msg":@"??????????????????????????????"} err:nil delete:NO];
}
JS_METHOD_SYNC(showQuanpingAd:(UZModuleMethodContext *)context){
	if (self.fullScreenAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fullScreenAd showAdFromRootViewController:self.viewController];
        });
		
//        [self.fullScreenAd showAdFromRootViewController:self.viewController ritSceneDescribe:nil];
		return @{@"code":@1,@"quanpingAdType":@"showQuanpingAd",@"eventType":@"doShow",@"msg":@"???????????????????????????????????????"};
	}else{
		return @{@"code":@0,@"quanpingAdType":@"showQuanpingAd",@"eventType":@"doShowFail",@"msg":@"????????????????????????????????? "};
	}

}

-(void) removeQuanpingAdNotification {
	//??????????????????
	if(self.quanpingAdObserver) {
		NSLog(@"??????????????????");
		[[NSNotificationCenter defaultCenter] removeObserver:self.quanpingAdObserver name:@"loadQuanpingAdObserver" object:nil];
		self.quanpingAdObserver = nil;
	}
	self.fullScreenAd = nil;
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"??????????????????",@"code":@1}];
}
#pragma mark  ???????????????delegate BUNativeExpressFullscreenVideoAdDelegate
/**
   This method is called when video ad material loaded successfully.
   ??????????????????????????? ???
 */
- (void)nativeExpressFullscreenVideoAdDidLoad:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when video ad materia failed to load.
   @param error : the reason of error
   ????????????
 */
- (void)nativeExpressFullscreenVideoAd:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoadFail",@"quanpingAdType":@"loadQuanpingAd",@"userInfo":errorInfo,@"msg":@"??????????????????",@"code":@0}];
	[self removeQuanpingAdNotification];
}

/**
   This method is called when rendering a nativeExpressAdView successed.
   It will happen when ad is show.
   ????????????
 */
- (void)nativeExpressFullscreenVideoAdViewRenderSuccess:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adRendered",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when a nativeExpressAdView failed to render.
   @param error : the reason of error
   ????????????
 */
- (void)nativeExpressFullscreenVideoAdViewRenderFail:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adRenderFail",@"quanpingAdType":@"loadQuanpingAd",@"userInfo":errorInfo,@"msg":@"??????????????????",@"code":@0}];
	[self removeQuanpingAdNotification];
}

/**
   ??????????????????
   This method is called when video cached successfully.
   For a better user experience, it is recommended to display video ads at this time.
   And you can call [BUNativeExpressFullscreenVideoAd showAdFromRootViewController:].
 */
- (void)nativeExpressFullscreenVideoAdDidDownLoadVideo:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adVideoDownloaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"????????????????????????????????????????????????",@"code":@1}];
    self.fullScreenAd = fullscreenVideoAd;
    if(self.showFullAd){
        [fullscreenVideoAd showAdFromRootViewController:self.viewController];
    }
}

/**
   This method is called when video ad slot will be showing.
   ??????????????????
 */
- (void)nativeExpressFullscreenVideoAdWillVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adWillShow",@"quanpingAdType":@"showQuanpingAd",@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when video ad slot has been shown.
   ??????????????????
 */
- (void)nativeExpressFullscreenVideoAdDidVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adShowed",@"quanpingAdType":@"showQuanpingAd",@"msg":@"???????????????",@"code":@1}];
}

/**
   This method is called when video ad is clicked.
 */
- (void)nativeExpressFullscreenVideoAdDidClick:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adClicked",@"quanpingAdType":@"showQuanpingAd",@"msg":@"??????????????????",@"code":@1}];
}

/**
   This method is called when the user clicked skip button.
 */
- (void)nativeExpressFullscreenVideoAdDidClickSkip:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adSkipClicked",@"quanpingAdType":@"showQuanpingAd",@"msg":@"????????????????????????",@"code":@1}];
}

/**
   This method is called when video ad is about to close.
 */
- (void)nativeExpressFullscreenVideoAdWillClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adWillClose",@"quanpingAdType":@"showQuanpingAd",@"msg":@"???????????????",@"code":@1}];
}

/**
   This method is called when video ad is closed.
 */
- (void)nativeExpressFullscreenVideoAdDidClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adClosed",@"quanpingAdType":@"showQuanpingAd",@"msg":@"???????????????",@"code":@1}];
    [self removeQuanpingAdNotification];
}

/**
   This method is called when video ad play completed or an error occurred.
   @param error : the reason of error
 */
- (void)nativeExpressFullscreenVideoAdDidPlayFinish:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adPlayFinished",@"quanpingAdType":@"showQuanpingAd",@"msg":@"?????????????????????",@"userInfo":errorInfo,@"code":@1}];
}

/**
   This method is used to get the type of nativeExpressFullScreenVideo ad
 */
- (void)nativeExpressFullscreenVideoAdCallback:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd withType:(BUNativeExpressFullScreenAdType) nativeExpressVideoAdType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adVideoType",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"??????????????????",@"videoAdType":@(nativeExpressVideoAdType),@"code":@1}];
}

/**
   This method is called when another controller has been closed.
   @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressFullscreenVideoAdDidCloseOtherController:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adCloseOtherController",@"quanpingAdType":@"showQuanpingAd",@"msg":@"???????????????????????????",@"interactionType":@(interactionType),@"code":@1}];
}
#pragma mark ???????????????
JS_METHOD(addExpressAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	NSDictionary *ret = [params dictValueForKey:@"ret" defaultValue:@{}];
	float x = [ret floatValueForKey:@"x" defaultValue:0.0];
	float y = [ret floatValueForKey:@"y" defaultValue:0.0];
	float width = [ret floatValueForKey:@"width" defaultValue:415];
//	float height = [ret floatValueForKey:@"height" defaultValue:50];
    
    float height = 0;
	bool fixed = [params boolValueForKey:@"fixed" defaultValue:NO];
	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];

	BUAdSlot *slot1 = [[BUAdSlot alloc] init];
	slot1.ID = adId;
	slot1.AdType = BUAdSlotAdTypeFeed;
	NSLog(@" BUProposalSize_Feed228_150 is %ld ",(long)BUProposalSize_Feed228_150);
	BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed690_388];
	slot1.imgSize = imgSize;
	slot1.position = BUAdSlotPositionFeed;
	// self.nativeExpressAdManager????????????
	if (!self.nativeExpressAdManager) {
		self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(width,height)];
	}
	self.nativeExpressAdManager.adSize = CGSizeMake(width,height);
	self.nativeExpressAdManager.delegate = self;
	[self.nativeExpressAdManager loadAdDataWithCount:1];


//    return @{@"code":@1,@"msg":@"??????!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.expressAdObserver) {
		self.expressAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadExpressAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                  NSLog(@"????????? loadExpressAdObserver ?????????%@",note.object);
		                                  __strong typeof(_self) self = _self;
		                                  if(!self) return;
		                                  NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                  if([placeId isEqualToString:adId]) {
							  NSString *expressAdType = [note.object stringValueForKey:@"expressAdType" defaultValue:nil];
							  NSString *eventType = [note.object stringValueForKey:@"eventType" defaultValue:nil];

							  NSLog(@" expressAdType %@ eventType %@",expressAdType,eventType);

							  NSLog(@" expresss  ini  mammm");
							  if([expressAdType isEqualToString:@"showExpressAd"] && [eventType isEqualToString:@"adRendered"]) {
								  if(self->_expressAdView) {
									  float width = self->_expressAdView.bounds.size.width;
									  float height =  self->_expressAdView.bounds.size.height;
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          //??????????????? ?????????????????????????????????view
                                          self->_expressAdView.frame = CGRectMake(x, y,width,height);
                                          NSLog(@" log expresss  ini  mammm");
                                          [self addSubview:self->_expressAdView fixedOn:fixedOn fixed:fixed];
                                      });
									  [[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"addViewToMainView",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"????????????????????????",@"width":@(width),@"height":@(height),@"code":@1}];
								  }else{
									  [[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"addViewToMainView",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"????????????????????????",@"code":@0}];
									  [self removeExpressAdView];
								  }
							  }

							  [context callbackWithRet:note.object err:nil delete:NO];
						  }
					  }];
	}
	[context callbackWithRet:@{@"code":@1,@"expressAdType":@"loadExpressAd",@"eventType":@"doLoad",@"msg":@"??????????????????????????????"} err:nil delete:NO];
}
JS_METHOD_SYNC(closeExpressAd:(UZModuleMethodContext *)context){
	[self removeExpressAdView];
	return @{@"code":@1,@"expressAdType":@"closeExpressAd",@"eventType":@"doClose",@"msg":@"??????????????????????????????"};
}
-(void) removeExpressAdView {
	NSLog(@"log expressAdView will remove");
	// ??????????????????
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self->_expressAdView.superview) {
			[self->_expressAdView removeFromSuperview];
		}
		self->_expressAdView = nil;

		self->_nativeExpressAdManager = nil;
	});
	[self removeExpressAdNotification];

}

-(void) removeExpressAdNotification {
	//??????????????????
	if(self.bannerAdObserver) {
		NSLog(@"??????????????????");
		[[NSNotificationCenter defaultCenter] removeObserver:self.expressAdObserver name:@"loadExpressAdObserver" object:nil];
		self.expressAdObserver = nil;
	}
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoaded",@"expressAdType":@"loadExpressAd",@"msg":@"??????????????????",@"code":@1}];
}

#pragma mark ??????????????? delegate
/**
 * Sent when views successfully load ad
 * ??????????????????
 */
- (void)nativeExpressAdSuccessToLoad:(BUNativeExpressAdManager *)nativeExpressAdManager views:(NSArray<__kindof BUNativeExpressAdView *> *)views {
	NSString *adId = nativeExpressAdManager.adslot.ID;
	if(views.count>0) {
		_expressAdView = (BUNativeExpressAdView *)[views firstObject];
		_expressAdView.adId =adId;
		_expressAdView.rootViewController = [self rootViewController];
		[_expressAdView render];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoaded",@"expressAdType":@"loadExpressAd",@"adId":adId,@"msg":@"??????????????????",@"code":@1}];
	}else{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoadedError",@"expressAdType":@"loadExpressAd",@"adId":adId,@"msg":@"????????????????????????",@"code":@0}];
		[self removeExpressAdView];
	}
}

/**
 * Sent when views fail to load ad
 * ??????????????????
 */
- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAdManager error:(NSError *_Nullable)error {
	NSString *adId = nativeExpressAdManager.adslot.ID;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoadFail",@"expressAdType":@"loadExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"??????????????????",@"code":@0}];
	[self removeExpressAdView];
}

/**
 * This method is called when rendering a nativeExpressAdView successed, and nativeExpressAdView.size.height has been updated
 * ?????????????????? ????????????width???height
 */
- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {

	NSString  *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adRendered",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
 * This method is called when a nativeExpressAdView failed to render
 * ??????????????????
 */
- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *_Nullable)error {
	NSString *adId = nativeExpressAdView.adId;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adRenderFail",@"expressAdType":@"showExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"??????????????????",@"code":@0}];
	[self removeExpressAdView];
}

/**
 * Sent when an ad view is about to present modal content
 *  ??????????????????
 */
- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adWillShow",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
 * Sent when an ad view is clicked
 */
- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adClicked",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"??????????????????",@"code":@1}];
}

/**
   Sent when a playerw playback status changed.
   @param playerState : player state after changed
   ??????????????????
 */
- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView stateDidChanged:(BUPlayerPlayState)playerState {
	NSString *adId = nativeExpressAdView.adId;
//    typedef NS_ENUM(NSInteger, BUPlayerPlayState) {
//        BUPlayerStateFailed    = 0,  ??????
//        BUPlayerStateBuffering = 1,  ??????
//        BUPlayerStatePlaying   = 2,  ??????
//        BUPlayerStateStopped   = 3,  ??????
//        BUPlayerStatePause     = 4,  ??????
//        BUPlayerStateDefalt    = 5   ??????
//    };

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"videoStatusChange",@"expressAdType":@"showExpressAd",@"adId":adId,@"playerState":@(playerState),@"msg":@"?????????????????????????????????",@"code":@1}];

}

/**
 * Sent when a player finished
 * @param error : error of player
 * ??????????????????
 */
- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
	NSString *adId = nativeExpressAdView.adId;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adVideoPlayyFinished",@"expressAdType":@"showExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"???????????????????????????",@"code":@1}];
}

/**
 * Sent when a user clicked dislike reasons.
 * @param filterWords : the array of reasons why the user dislikes the ad
 */
- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterWords {
	NSMutableArray<NSDictionary *> *words = @[].mutableCopy;
	if(filterWords.count>0) {
		for (BUDislikeWords *filterword in filterWords) {
			[words addObject:@{@"name":filterword.name,@"dislikeId":filterword.dislikeID,@"isSelected":@(filterword.isSelected)}];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adDislikCliecked",@"expressAdType":@"showExpressAd",@"adId":nativeExpressAdView.adId,@"msg":@"???????????????dislike??????",@"words":words,@"code":@1}];
}

/**
 * Sent after an ad view is clicked, a ad landscape view will present modal content
 */
- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adPageWillShow",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"???????????????????????????",@"code":@1}];
}

/**
   This method is called when another controller has been closed.
   @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressAdViewDidCloseOtherController:(BUNativeExpressAdView *)nativeExpressAdView interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adCloseOtherController",@"adId":nativeExpressAdView.adId,@"expressAdType":@"showExpressAd",@"msg":@"?????????????????????????????????",@"interactionType":@(interactionType),@"code":@1}];
}


/**
   This method is called when the Ad view container is forced to be removed.
   @param nativeExpressAdView : Ad view container
 */
- (void)nativeExpressAdViewDidRemoved:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adClose",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"???????????????",@"code":@1}];
    [self removeExpressAdView];
}


@end
