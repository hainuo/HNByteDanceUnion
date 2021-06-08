//
//  HNByteDanceUnion.m
//  HNByteDanceUnion
//
//  Created by hainuo on 2021/4/2.
//

#import "HNByteDanceUnion.h"
#import "UZEngine/NSDictionaryUtils.h"
#import <BUAdSDK/BUAdSDK.h>

@interface HNByteDanceUnion ()<BUSplashAdDelegate,BUSplashZoomOutViewDelegate>
@property (nonatomic, strong) BUSplashAdView *splashAdView;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, strong) NSObject *splashAdObserver;
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

	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];
	bool fixed = [params boolValueForKey:@"fixed" defaultValue:NO];

	CGRect frame = CGRectMake([x floatValue], [y floatValue], [width floatValue], [height floatValue]);
	self.splashAdView = [[BUSplashAdView alloc] initWithSlotID:adId frame:frame];
	// tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
	self.splashAdView.tolerateTimeout = 3;
	//不支持中途更改代理，中途更改代理会导致接收不到广告相关回调，如若存在中途更改代理场景，需自行处理相关逻辑，确保广告相关回调正常执行。
	self.splashAdView.delegate = self;

	self.startTime = CACurrentMediaTime();
	[self.splashAdView loadAdData];
    UIViewController *parentVC = [UIApplication sharedApplication].windows[0].rootViewController;
	[parentVC.view addSubview:self.splashAdView];
    
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
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"evenType":@"onAdRemove",@"adEvenType":@"onAdRemoved",@"msg":@"广告移除成功！",@"code":@1}];
}

- (void)splashAdDidLoad:(BUSplashAdView *)splashAd {

	NSLog(@"splashAD has loaded");
	if (splashAd.zoomOutView) {
		NSLog(@"splashAD zoomoutview has loaded");
		UIViewController *parentVC = [UIApplication sharedApplication].windows[0].rootViewController;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"evenType":@"onError",@"adEvenType":@"adloadFail",@"msg":error.userInfo,@"code":@0}];


	[self removeSplashAdView];
}



- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"evenType":@"onAdLoad",@"adEvenType":@"onAdCloseOtherController",@"msg":@"广告关闭了其他控制器！",@"code":@1}];
}

- (void)splashAdCountdownToZero:(BUSplashAdView *)splashAd {
	// When the countdown is over, it is equivalent to clicking Skip to completely remove 'splashAdView' and avoid memory leak
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"evenType":@"onAdLoad",@"adEvenType":@"adTimeOver",@"msg":@"倒计时结束！",@"code":@1}];
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

@end
