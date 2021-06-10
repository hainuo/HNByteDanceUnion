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
@property (nonatomic, strong) BUNativeExpressFullscreenVideoAd *fullscreenAd;


//xinxiliu

@property (nonatomic, strong) NSObject *expressAdObserver;
@property (nonatomic, strong) BUNativeExpressAdManager *nativeExpressAdManager;
@property (nonatomic,strong) BUNativeExpressAdView *expressAdView;
@end



@implementation HNByteDanceUnion

#pragma mark - Override UZEngine
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
	// 方法在应用启动时被调用
	NSLog(@"HNBytedanceUnion 被调用了");


}

- (id)initWithUZWebView:(UZWebView *)webView {
	if (self = [super initWithUZWebView:webView]) {
		// 初始化方法
		NSLog(@"HNBytedanceUnionUZWebView  被调用了");
	}
	return self;
}

- (void)dispose {
	// 方法在模块销毁之前被调用
	NSLog(@"HNBytedanceUnion  被销毁了");
	[self removeQuanpingAdNotification];
	_fullscreenAd = nil;
	[self removeBannerAdNotification];
	_bannerAdView = nil;
	[self removeSplashADNotification];
	_splashAdView = nil;

	[self removeExpressAdNotification];
	_expressAdView = nil;
	_nativeExpressAdManager = nil;

}

- (UIWindow *)getKeyWindow
{
	if (@available(iOS 13.0, *))
	{
		for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
			if (windowScene.activationState == UISceneActivationStateForegroundActive)
			{
				for (UIWindow *window in windowScene.windows)
				{
					if (window.isKeyWindow)
					{
						return window;
						break;
					}
				}
			}
		}
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
		[context callbackWithRet:@{@"code":@0,@"msg":@"广告appId有误！"} err:nil delete:YES];
		return;
	}
	NSInteger territory = [[NSUserDefaults standardUserDefaults]integerForKey:@"territory"];
	BOOL isNoCN = (territory>0&&territory!=BUAdSDKTerritory_CN);

	BUAdSDKConfiguration *configuration = [BUAdSDKConfiguration configuration];
	configuration.territory = isNoCN?BUAdSDKTerritory_NO_CN:BUAdSDKTerritory_CN;
	configuration.GDPR = @(0);
	configuration.coppa = @(0);
	configuration.CCPA = @(1);
	configuration.appID = appId;
//    configuration.logLevel = BUAdSDKLogLevelDebug;
	[BUAdSDKManager startWithSyncCompletionHandler:^(BOOL success, NSError *error) {

	         if (success) {
			 //shezhi keyi
			 [context callbackWithRet:@{@"code":@1,@"msg":@"初始化成功！",@"version":[BUAdSDKManager SDKVersion]} err:nil delete:NO];
			 ;
		 }else{
			 //shezhi bukeyi
			 NSDictionary *errorInfo  = @{};
			 if(error && error.userInfo) {
				 errorInfo = error.userInfo;
			 }
			 [context callbackWithRet:@{@"code":@0,@"msg":@"初始化失败！",@"userInfo":errorInfo,@"version":[BUAdSDKManager SDKVersion]} err:nil delete:NO];
		 }
	 }];

}
#pragma mark - SplashAd 开屏广告展示
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

	CGRect frame = CGRectMake([x floatValue], [y floatValue], [width floatValue], [height floatValue]);
	self.splashAdView = [[BUSplashAdView alloc] initWithSlotID:adId frame:frame];
	// tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
	self.splashAdView.tolerateTimeout = 3;
	//不支持中途更改代理，中途更改代理会导致接收不到广告相关回调，如若存在中途更改代理场景，需自行处理相关逻辑，确保广告相关回调正常执行。
	self.splashAdView.delegate = self;

	self.startTime = CACurrentMediaTime();
	[self.splashAdView loadAdData];
	UIViewController *parentVC = [self getKeyWindow].rootViewController;
	[parentVC.view addSubview:self.splashAdView];
	self.splashAdView.rootViewController=parentVC;

//    return @{@"code":@1,@"msg":@"成功!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.splashAdObserver) {
		self.splashAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadSplashAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                 NSLog(@"接收到loadSplashAdObserver通知，%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
//        __strong typeof(_context) context = _context;
		                                 [context callbackWithRet:note.object err:nil delete:NO];
					 }];
	}
	[context callbackWithRet:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}

- (void)removeSplashAdView {
	if (self.splashAdView) {
		[self.splashAdView removeFromSuperview];
		self.splashAdView = nil;
	}

	[self removeSplashADNotification];
}

-(void) removeSplashADNotification {
	//同时移除监听
	if(self.splashAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.splashAdObserver name:@"loadSplashAdObserver" object:nil];
		self.splashAdObserver = nil;
	}
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"onAdRemove",@"adeventType":@"onAdRemoved",@"msg":@"广告移除成功！",@"code":@1}];
}

- (void)splashAdDidLoad:(BUSplashAdView *)splashAd {

	NSLog(@"splashAD has loaded");
	if (splashAd.zoomOutView) {
		NSLog(@"splashAD zoomoutview has loaded");
		UIViewController *parentVC = [self getKeyWindow].rootViewController;
		[parentVC.view addSubview:splashAd.zoomOutView];
		[parentVC.view bringSubviewToFront:splashAd];
		//Add this view to your container
		[parentVC.view insertSubview:splashAd.zoomOutView belowSubview:splashAd];
		splashAd.zoomOutView.rootViewController = parentVC;
		splashAd.zoomOutView.delegate = self;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adLoaded",@"msg":@"开屏广告素材加载成功！"}];
}

- (void)splashAdDidClose:(BUSplashAdView *)splashAd {

	// Be careful not to say 'self.splashadview = nil' here.
	// Subsequent agent callbacks will not be triggered after the 'splashAdView' is released early.

	[self pbu_logWithSEL:_cmd msg:@"splashAd has been closed"];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adClosed",@"msg":@"开屏广告关闭了"}];

	[self removeSplashAdView];
}

- (void)splashAdDidClick:(BUSplashAdView *)splashAd {
	if (splashAd.zoomOutView) {
		[splashAd.zoomOutView removeFromSuperview];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adClicked",@"msg":@"开屏广告被点击了"}];
	// Be careful not to say 'self.splashadview = nil' here.
	// Subsequent agent callbacks will not be triggered after the 'splashAdView' is released early.
	[splashAd removeFromSuperview];
	[self pbu_logWithSEL:_cmd msg:@"spashAd has been clicked"];

}

- (void)splashAdDidClickSkip:(BUSplashAdView *)splashAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":@"loadSplashAd",@"eventType":@"adSkipClicked",@"msg":@"开屏广告跳过被点击了"}];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adloadFail",@"splashAdType":@"loadSplashAd",@"msg":@"广告加载失败",@"userInfo":errorInfo,@"code":@0}];


	[self removeSplashAdView];
}



- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adCloseOtherController",@"splashAdType":@"loadSplashAd",@"msg":@"广告关闭了其他控制器！",@"interactionType":@(interactionType),@"code":@1}];
}

- (void)splashAdCountdownToZero:(BUSplashAdView *)splashAd {
	// When the countdown is over, it is equivalent to clicking Skip to completely remove 'splashAdView' and avoid memory leak
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adTimeOver",@"splashAdType":@"loadSplashAd",@"msg":@"倒计时结束！",@"code":@1}];
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

#pragma mark banner广告
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
		self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self getKeyWindow].rootViewController adSize:CGSizeMake(width, height) interval:refreshInterval];
	}else{
		self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self getKeyWindow].rootViewController adSize:CGSizeMake(width, height)];
	}
	if(self.bannerAdView.superview) {
		[self.bannerAdView removeFromSuperview];
	}

	self.bannerAdView.frame = CGRectMake(x,y,width,height);
	self.bannerAdView.adId = adId;
	self.bannerAdView.delegate = self;
	[self.bannerAdView loadAdData];

//    return @{@"code":@1,@"msg":@"成功!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.bannerAdObserver) {
		self.bannerAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadBannerAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                 NSLog(@"接收到 loadBannerAdObserver 通知，%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
		                                 NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                 if([placeId isEqualToString:adId]) {
							 NSString *bannerAdType = [note.object stringValueForKey:@"bannerAdType" defaultValue:nil];
							 NSString *eventType = [note.object stringValueForKey:@"eventType" defaultValue:nil];

							 NSLog(@" bannerAdType %@ eventType %@",bannerAdType,eventType);

							 if([bannerAdType isEqualToString:@"loadBannerAd"] && [eventType isEqualToString:@"adRendered"]) {
								 //接收到信号 渲染成功的时候方才加载view
								 [self addSubview:self->_bannerAdView fixedOn:fixedOn fixed:fixed];
								 [[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"addViewToMainView",@"bannerAdType":@"loadBannerAd",@"adId":adId,@"msg":@"广告加入界面成功",@"height":@(self->_bannerAdView.bounds.size.height),@"width":@(self->_bannerAdView.bounds.size.width),@"code":@1}];
							 }

							 [context callbackWithRet:note.object err:nil delete:NO];
						 }
					 }];
	}
	[context callbackWithRet:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
JS_METHOD_SYNC(closeBannerAd:(UZModuleMethodContext *)context){
	[self removeBannerAdView];
	return @{@"code":@1,@"bannerAdType":@"closeBannerAd",@"eventType":@"doClose",@"msg":@"广告关闭命令执行成功"};
}
-(void) removeBannerAdView {
	// 同步到主线程
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self->_bannerAdView.superview) {
			[self->_bannerAdView removeFromSuperview];
		}
		self->_bannerAdView = nil;
	});
	[self removeBannerAdNotification];
}

-(void) removeBannerAdNotification {
	//同时移除监听
	if(self.bannerAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.bannerAdObserver name:@"loadBannerAdObserver" object:nil];
		self.bannerAdObserver = nil;
	}
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoaded",@"bannerAdType":@"loadBannerAd",@"msg":@"广告加载成功",@"code":@1}];
}
#pragma mark banner delegate BUNativeExpressBannerViewDelegate
/**
   This method is called when bannerAdView ad slot loaded successfully.  广告加载成功
   @param bannerAdView : view for bannerAdView
 */
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoaded",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告加载成功",@"code":@1}];

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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoadFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"userInfo":errorInfo,@"msg":@"广告加载失败",@"code":@0}];

	[self removeBannerAdView];
}

/**
        广告渲染成功
   This method is called when rendering a nativeExpressAdView successed.
 */
- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adRendered",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告渲染成功",@"code":@1}];
}

/**
   This method is called when a nativeExpressAdView failed to render.
    广告渲染失败
   @param error : the reason of error
 */
- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError *)error {

	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adRenderFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告渲染失败",@"userInfo":errorInfo,@"code":@0}];
	[self removeBannerAdView];
}

/**
   This method is called when bannerAdView ad slot showed new ad.
 */
- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adWillShow",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告即将展示",@"code":@1}];
}

/**
   This method is called when bannerAdView is clicked.
 */
- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adClicked",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告被点击了",@"code":@1}];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adDislikCliecked",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"用户点击了dislike按钮",@"words":words,@"code":@1}];
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

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"AdCloseOtherController",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"banner广告关闭了其他控制器",@"interactionType":@(interactionType),@"code":@1}];
}

/**
   This method is called when the Ad view container is forced to be removed.
   @param bannerAdView : Express Banner Ad view container
 */
- (void)nativeExpressBannerAdViewDidRemoved:(BUNativeExpressBannerView *)bannerAdView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"AdCloseOtherController",@"bannerAdType":@"showBannerAd",@"adId":bannerAdView.adId,@"msg":@"banner广告被用户主动关闭了",@"code":@1}];
	[UIView animateWithDuration:0.25 animations:^{
	         self->_bannerAdView.alpha = 0;
	 } completion:^(BOOL finished) {
	         [self removeBannerAdView];
	 }];
}

#pragma mark 新插屏广告
JS_METHOD(addQuanpingAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];

	self.fullscreenAd = [[BUNativeExpressFullscreenVideoAd alloc] initWithSlotID:adId];
	// 不支持中途更改代理，中途更改代理会导致接收不到广告相关回调，如若存在中途更改代理场景，需自行处理相关逻辑，确保广告相关回调正常执行。
	self.fullscreenAd.delegate = self;
	[self.fullscreenAd loadAdData];

//    return @{@"code":@1,@"msg":@"成功!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.quanpingAdObserver) {
		self.quanpingAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadQuanpingAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                   NSLog(@"接收到 loadQuanpingAdObserver 通知，%@",note.object);
		                                   __strong typeof(_self) self = _self;
		                                   if(!self) return;
		                                   [context callbackWithRet:note.object err:nil delete:NO];
					   }];
	}
	[context callbackWithRet:@{@"code":@1,@"quanpingAdType":@"loadQuanpingAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
JS_METHOD_SYNC(showQuanpingAd:(UZModuleMethodContext *)context){
	if (self.fullscreenAd) {
		[self.fullscreenAd showAdFromRootViewController:[self getKeyWindow].rootViewController];
		return @{@"code":@1,@"quanpingAdType":@"showQuanpingAd",@"eventType":@"doShow",@"msg":@"新插屏广告显示命令执行成功"};
	}else{
		return @{@"code":@0,@"quanpingAdType":@"showQuanpingAd",@"eventType":@"doShowFail",@"msg":@"没有找到新插屏广告信息 "};
	}

}

-(void) removeQuanpingAdNotification {
	//同时移除监听
	if(self.quanpingAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.quanpingAdObserver name:@"loadQuanpingAdObserver" object:nil];
		self.splashAdObserver = nil;
	}
	_fullscreenAd = nil;
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"广告加载成功",@"code":@1}];
}
#pragma mark  新插屏广告delegate BUNativeExpressFullscreenVideoAdDelegate
/**
   This method is called when video ad material loaded successfully.
   新插屏广告加载成功 ！
 */
- (void)nativeExpressFullscreenVideoAdDidLoad:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"广告加载成功",@"code":@1}];
}

/**
   This method is called when video ad materia failed to load.
   @param error : the reason of error
   加载失败
 */
- (void)nativeExpressFullscreenVideoAd:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adLoadFail",@"quanpingAdType":@"loadQuanpingAd",@"userInfo":errorInfo,@"msg":@"广告加载失败",@"code":@0}];
	[self removeQuanpingAdNotification];
}

/**
   This method is called when rendering a nativeExpressAdView successed.
   It will happen when ad is show.
   渲染成功
 */
- (void)nativeExpressFullscreenVideoAdViewRenderSuccess:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adRendered",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"广告渲染成功",@"code":@1}];
}

/**
   This method is called when a nativeExpressAdView failed to render.
   @param error : the reason of error
   渲染失败
 */
- (void)nativeExpressFullscreenVideoAdViewRenderFail:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adRenderFail",@"quanpingAdType":@"loadQuanpingAd",@"userInfo":errorInfo,@"msg":@"广告渲染失败",@"code":@0}];
	[self removeQuanpingAdNotification];
}

/**
   视频缓存成功
   This method is called when video cached successfully.
   For a better user experience, it is recommended to display video ads at this time.
   And you can call [BUNativeExpressFullscreenVideoAd showAdFromRootViewController:].
 */
- (void)nativeExpressFullscreenVideoAdDidDownLoadVideo:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adVideoDownloaded",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"广告视频加载成功，可以显示广告了",@"code":@1}];
}

/**
   This method is called when video ad slot will be showing.
   广告即将显示
 */
- (void)nativeExpressFullscreenVideoAdWillVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adWillShow",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告即将展示",@"code":@1}];
}

/**
   This method is called when video ad slot has been shown.
   广告已经显示
 */
- (void)nativeExpressFullscreenVideoAdDidVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adShowed",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告展示了",@"code":@1}];
}

/**
   This method is called when video ad is clicked.
 */
- (void)nativeExpressFullscreenVideoAdDidClick:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adClicked",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告被点击了",@"code":@1}];
}

/**
   This method is called when the user clicked skip button.
 */
- (void)nativeExpressFullscreenVideoAdDidClickSkip:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adSkipClicked",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告跳过被点击了",@"code":@1}];
}

/**
   This method is called when video ad is about to close.
 */
- (void)nativeExpressFullscreenVideoAdWillClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adWillClose",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告将关闭",@"code":@1}];
}

/**
   This method is called when video ad is closed.
 */
- (void)nativeExpressFullscreenVideoAdDidClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adClosed",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告关闭了",@"code":@1}];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adPlayFinished",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告播放结束了",@"userInfo":errorInfo,@"code":@1}];
}

/**
   This method is used to get the type of nativeExpressFullScreenVideo ad
 */
- (void)nativeExpressFullscreenVideoAdCallback:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd withType:(BUNativeExpressFullScreenAdType) nativeExpressVideoAdType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adVideoType",@"quanpingAdType":@"loadQuanpingAd",@"msg":@"广告视频类型",@"videoAdType":@(nativeExpressVideoAdType),@"code":@1}];
}

/**
   This method is called when another controller has been closed.
   @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressFullscreenVideoAdDidCloseOtherController:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadQuanpingAdObserver" object:@{@"eventType":@"adCloseOtherController",@"quanpingAdType":@"showQuanpingAd",@"msg":@"广告关闭其他控制器",@"interactionType":@(interactionType),@"code":@1}];
}
#pragma mark 信息流广告
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
	// self.nativeExpressAdManager可以重用
	if (!self.nativeExpressAdManager) {
		self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(width,height)];
	}
	self.nativeExpressAdManager.adSize = CGSizeMake(width,height);
	self.nativeExpressAdManager.delegate = self;
	[self.nativeExpressAdManager loadAdDataWithCount:1];


//    return @{@"code":@1,@"msg":@"成功!"};
	__weak typeof(self) _self = self;
//    __weak typeof(context) _context=context;
	if(!self.expressAdObserver) {
		self.expressAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadExpressAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {

		                                  NSLog(@"接收到 loadExpressAdObserver 通知，%@",note.object);
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
									  //接收到信号 渲染成功的时候方才加载view
									  self->_expressAdView.frame = CGRectMake(x, y,width,height);
									  NSLog(@" log expresss  ini  mammm");
									  [self addSubview:self->_expressAdView fixedOn:fixedOn fixed:fixed];
									  [[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"addViewToMainView",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告加入界面成功",@"width":@(width),@"height":@(height),@"code":@1}];
								  }else{
									  [[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"addViewToMainView",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告加入界面失败",@"code":@0}];
									  [self removeExpressAdView];
								  }
							  }

							  [context callbackWithRet:note.object err:nil delete:NO];
						  }
					  }];
	}
	[context callbackWithRet:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
JS_METHOD_SYNC(closeExpressAd:(UZModuleMethodContext *)context){
	[self removeExpressAdView];
	return @{@"code":@1,@"bannerAdType":@"closeExpressAd",@"eventType":@"doClose",@"msg":@"广告关闭命令执行成功"};
}
-(void) removeExpressAdView {
	NSLog(@"log expressAdView will remove");
	// 同步到主线程
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
	//同时移除监听
	if(self.bannerAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.expressAdObserver name:@"loadExpressAdObserver" object:nil];
		self.expressAdObserver = nil;
	}
//[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoaded",@"expressAdType":@"loadExpressAd",@"msg":@"广告加载成功",@"code":@1}];
}

#pragma mark 信息流广告 delegate
/**
 * Sent when views successfully load ad
 * 广告加载成功
 */
- (void)nativeExpressAdSuccessToLoad:(BUNativeExpressAdManager *)nativeExpressAdManager views:(NSArray<__kindof BUNativeExpressAdView *> *)views {
	NSString *adId = nativeExpressAdManager.adslot.ID;
	if(views.count>0) {
		_expressAdView = (BUNativeExpressAdView *)[views firstObject];
		_expressAdView.adId =adId;
		_expressAdView.rootViewController = [self getKeyWindow].rootViewController;
		[_expressAdView render];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoaded",@"expressAdType":@"loadExpressAd",@"adId":adId,@"msg":@"广告加载成功",@"code":@1}];
	}else{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoadedError",@"expressAdType":@"loadExpressAd",@"adId":adId,@"msg":@"广告加载数据为空",@"code":@0}];
		[self removeExpressAdView];
	}
}

/**
 * Sent when views fail to load ad
 * 广告加载失败
 */
- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAdManager error:(NSError *_Nullable)error {
	NSString *adId = nativeExpressAdManager.adslot.ID;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adLoadNone",@"expressAdType":@"loadExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"广告加载失败",@"code":@0}];
	[self removeExpressAdView];
}

/**
 * This method is called when rendering a nativeExpressAdView successed, and nativeExpressAdView.size.height has been updated
 * 广告渲染成功 得到新的width和height
 */
- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {

	NSString  *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adRendered",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告渲染成功",@"code":@1}];
}

/**
 * This method is called when a nativeExpressAdView failed to render
 * 广告渲染失败
 */
- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *_Nullable)error {
	NSString *adId = nativeExpressAdView.adId;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adRenderFaild",@"expressAdType":@"showExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"广告渲染失败",@"code":@0}];
	[self removeExpressAdView];
}

/**
 * Sent when an ad view is about to present modal content
 *  广告即将展示
 */
- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adWillShow",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告即将展示",@"code":@1}];
}

/**
 * Sent when an ad view is clicked
 */
- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adClickerd",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告被点击了",@"code":@1}];
}

/**
   Sent when a playerw playback status changed.
   @param playerState : player state after changed
   播放状态变化
 */
- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView stateDidChanged:(BUPlayerPlayState)playerState {
	NSString *adId = nativeExpressAdView.adId;
//    typedef NS_ENUM(NSInteger, BUPlayerPlayState) {
//        BUPlayerStateFailed    = 0,  失败
//        BUPlayerStateBuffering = 1,  缓冲
//        BUPlayerStatePlaying   = 2,  播放
//        BUPlayerStateStopped   = 3,  停止
//        BUPlayerStatePause     = 4,  暂停
//        BUPlayerStateDefalt    = 5   未知
//    };

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"videoStatusChange",@"expressAdType":@"showExpressAd",@"adId":adId,@"playerState":@(playerState),@"msg":@"广告视频播放状态变化了",@"code":@1}];

}

/**
 * Sent when a player finished
 * @param error : error of player
 * 视频播放结束
 */
- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
	NSString *adId = nativeExpressAdView.adId;
	NSDictionary *errorInfo = @{};
	if(error && error.userInfo) {
		errorInfo = error.userInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adVideoPlayyFinished",@"expressAdType":@"showExpressAd",@"adId":adId,@"userInfo":errorInfo,@"msg":@"广告视频播放结束了",@"code":@1}];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adDislikCliecked",@"expressAdType":@"showExpressAd",@"adId":nativeExpressAdView.adId,@"msg":@"用户点击了dislike按钮",@"words":words,@"code":@1}];
}

/**
 * Sent after an ad view is clicked, a ad landscape view will present modal content
 */
- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adPageWillShow",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告详情页即将展示",@"code":@1}];
}

/**
   This method is called when another controller has been closed.
   @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressAdViewDidCloseOtherController:(BUNativeExpressAdView *)nativeExpressAdView interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adCloseOtherController",@"adId":nativeExpressAdView.adId,@"expressAdType":@"showExpressAd",@"msg":@"广告关闭了其他控制器！",@"interactionType":@(interactionType),@"code":@1}];
}


/**
   This method is called when the Ad view container is forced to be removed.
   @param nativeExpressAdView : Ad view container
 */
- (void)nativeExpressAdViewDidRemoved:(BUNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadExpressAdObserver" object:@{@"eventType":@"adClose",@"expressAdType":@"showExpressAd",@"adId":adId,@"msg":@"广告关闭了",@"code":@1}];
    [self removeExpressAdView];
}


@end
