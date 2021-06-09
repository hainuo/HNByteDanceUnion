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


@interface BUNativeExpressBannerView (HNTMob)
@property (nonatomic, assign) NSString *adId;
@end

@implementation BUNativeExpressBannerView (HNTMob)
static void *nl_sqlite_adId_key = &nl_sqlite_adId_key;
- (void)setAdId:(NSString *)adId {
	objc_setAssociatedObject(self, nl_sqlite_adId_key, adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)adId {
	return [objc_getAssociatedObject(self,nl_sqlite_adId_key) stringValue];
}
@end

@interface HNByteDanceUnion ()<BUSplashAdDelegate,BUSplashZoomOutViewDelegate,BUNativeExpressBannerViewDelegate>
@property (nonatomic, strong) BUSplashAdView *splashAdView;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) NSObject *splashAdObserver;

//bannerAd

@property (nonatomic, strong) NSObject *bannerAdObserver;
@property (nonatomic,strong) BUNativeExpressBannerView *bannerAdView;
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
	[[NSNotificationCenter defaultCenter] removeObserver:@"loadSplashAdObserver"];
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

JS_METHOD_SYNC(init:(UZModuleMethodContext *)context){

	NSDictionary *params = context.param;
	NSString *appId  = [params stringValueForKey:@"appId" defaultValue:nil];
	if(!appId) {
		return @{@"code":@0,@"msg":@"appId有误！"};
	}
	[BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
	NSInteger territory = [[NSUserDefaults standardUserDefaults]integerForKey:@"territory"];

	BOOL isNoCN = (territory>0&&territory!=BUAdSDKTerritory_CN);
	///optional
	///CN china, NO_CN is not china
	///you must set Territory first,  if you need to set them
	[BUAdSDKManager setTerritory:isNoCN?BUAdSDKTerritory_NO_CN:BUAdSDKTerritory_CN];
	//optional
	//GDPR 0 close privacy protection, 1 open privacy protection
	[BUAdSDKManager setGDPR:0];
	//optional
	//Coppa 0 adult, 1 child
	[BUAdSDKManager setCoppa:0];

	// Whether to open log. default is none.
	[BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
//    [BUAdSDKManager setDisableSKAdNetwork:YES];
	[BUAdSDKManager setAppID:appId];
	[BUAdSDKManager setCustomIDFA:@"12345678-1234-1234-1234-123456789012"];
	[BUAdSDKManager setIsPaidApp:NO];
	//shezhi keyi
	return @{@"code":@1,@"msg":@"初始化成功！",@"version":[BUAdSDKManager SDKVersion]};
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
	[self pbu_logWithSEL:_cmd msg:@"splashAd has been removed"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"eventType":@"adloadFail",@"splashAdType":@"loadSplashAd",@"msg":error.userInfo,@"code":@0}];


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
    if(refreshInterval>=30 && refreshInterval <=120){
        self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self getKeyWindow].rootViewController adSize:CGSizeMake(width, height) interval:refreshInterval];
    }else{
        self.bannerAdView = [[BUNativeExpressBannerView alloc] initWithSlotID:adId rootViewController:[self getKeyWindow].rootViewController adSize:CGSizeMake(width, height)];
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

}

-(void) removeBannerAdNotification {
	//同时移除监听
	if(self.splashAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.splashAdObserver name:@"loadBannerAdObserver" object:nil];
		self.splashAdObserver = nil;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adLoadFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告加载失败",@"code":@0}];

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

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"eventType":@"adRenderFail",@"bannerAdType":@"loadBannerAd",@"adId":bannerAdView.adId,@"msg":@"广告渲染失败",@"code":@0}];
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
    if(filterwords.count>0){
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
@end
