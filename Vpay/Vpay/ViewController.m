//
//  ViewController.m
//  Vpay
//
//  Created by yangwei cui on 2018/2/28.
//  Copyright © 2018年 David. All rights reserved.
//

#define TINTCOLOR_ALPHA 0.2 //浅色透明度
#define DARKCOLOR_ALPHA 0.5 //深色透明度
#define VIEW_WIDTH [UIScreen mainScreen].bounds.size.width
#define VIEW_HEIGHT [UIScreen mainScreen].bounds.size.height
#define IPHONE5_SCALAE(f)  (VIEW_WIDTH/(320*2)*f)


#import "ViewController.h"
#import "SZKNetWorkUtils.h"
#import "JWCacheURLProtocol.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <AVFoundation/AVFoundation.h>
//测试链接
@interface ViewController ()<UIWebViewDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    UIView *AVCapView;//此 view 用来放置扫描框、取消按钮、说明 label
    AVCaptureSession * session;//输入输出的中间桥梁
}


@property (weak, nonatomic) IBOutlet UIWebView *vpayWebView;
@property(nonatomic, strong) JSContext *context;
@property(nonatomic,strong)UIView *QrCodeline;//上下移动绿色的线条
@property(nonatomic,strong)NSTimer *timer;//定时器对象
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [SZKNetWorkUtils netWorkState:^(NSInteger netState) {
        
        switch (netState) {
            case 1:{
            
                [self loadWebData];
                NSLog(@"手机流量上网");
            }
                break;
            case 2:{
               
                [self loadWebData];
                NSLog(@"WIFI上网");
            }
                break;
            default:{
               
            [self loadWebData];
               NSLog(@"没网");
            }
                break;
        }
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //捕捉异常回调
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
        context.exception = exceptionValue;
        NSLog(@"异常信息: %@",exceptionValue);
    };
    //通过block形式关联JavaScript中的函数
    __weak typeof(self) weakSelf = self;
    
    self.context[@"sendInfoToJava"] = ^() {
        
        NSLog(@"分享的url");
        [weakSelf scanImge];
       // __strong typeof(self) strongSelf = weakSelf;
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            
           
        });
        
        
    };
}

-(void)loadWebData{
    //[JWCacheURLProtocol startListeningNetWorking];
    NSURLRequest*req=[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.104/cmkj_066/index.php?a=home/index/index.html"]];
    self.vpayWebView.scrollView.bounces=NO;
    self.vpayWebView.delegate=self;
    [self.vpayWebView loadRequest:req];
}

#pragma mark==点击扫描二维码操作

- (void)scanImge {
    
    //创建一个 view 来放置扫描区域、说明 label、取消按钮
    UIView *tempView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,VIEW_WIDTH , [UIScreen mainScreen].bounds.size.height )];
    AVCapView = tempView;
    AVCapView.backgroundColor = [UIColor colorWithRed:54.f/255 green:53.f/255 blue:58.f/255 alpha:1];
    
    UIButton *cancelBtn = [[UIButton alloc]initWithFrame:CGRectMake(IPHONE5_SCALAE(30), [UIScreen mainScreen].bounds.size.height - IPHONE5_SCALAE(200), IPHONE5_SCALAE(100), IPHONE5_SCALAE(50))];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(IPHONE5_SCALAE(30), IPHONE5_SCALAE(268*2) , IPHONE5_SCALAE(580), IPHONE5_SCALAE(120))];
    label.numberOfLines = 0;
    label.text = @"小提示：将条形码或二维码对准上方区域中心即可";
    label.textColor = [UIColor grayColor];
    [cancelBtn setTitle:@"取消" forState: UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(touchAVCancelBtn) forControlEvents:UIControlEventTouchUpInside];
    [AVCapView addSubview:label];
    [AVCapView addSubview:cancelBtn];
    [self.view addSubview:AVCapView];
    
    
    //画上边框
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(IPHONE5_SCALAE(100), IPHONE5_SCALAE(80), VIEW_WIDTH- 2 * IPHONE5_SCALAE(100), 1)];
    topView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:topView];
    
    //画左边框
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(IPHONE5_SCALAE(100), IPHONE5_SCALAE(80) , 1,VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) )];
    leftView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:leftView];
    
    //画右边框
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(IPHONE5_SCALAE(100) + VIEW_WIDTH- 2 * IPHONE5_SCALAE(100), IPHONE5_SCALAE(80) , 1,VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) + 1)];
    rightView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:rightView];
    
    //画下边框
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(IPHONE5_SCALAE(100), IPHONE5_SCALAE(80) + VIEW_WIDTH- 2 * IPHONE5_SCALAE(100),VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) ,1 )];
    downView.backgroundColor = [UIColor whiteColor];
    [AVCapView addSubview:downView];
    
    
    //画中间的基准线
    _QrCodeline = [[UIView alloc] initWithFrame:CGRectMake(IPHONE5_SCALAE(100) + 1, IPHONE5_SCALAE(80), VIEW_WIDTH- 2 * IPHONE5_SCALAE(100) - 1, 2)];
    _QrCodeline.backgroundColor = [UIColor redColor];
    [AVCapView addSubview:_QrCodeline];
    
    // 先让基准线运动一次，避免定时器的时差
    [UIView animateWithDuration:1.2 animations:^{
        
        _QrCodeline.frame = CGRectMake(IPHONE5_SCALAE(100) + 1, VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) + IPHONE5_SCALAE(80) , VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) - 1, 2);
        
    }];
    
    [self performSelector:@selector(createTimer) withObject:nil afterDelay:0.4];
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [session addInput:input];
    [session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame = CGRectMake(IPHONE5_SCALAE(100), IPHONE5_SCALAE(80), VIEW_WIDTH- 2 * IPHONE5_SCALAE(100), IPHONE5_SCALAE(440));
    [AVCapView.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [session startRunning];
    
}
#pragma mark==实现基准线的滚来滚去的操作
- (void)createTimer
{
    _timer=[NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(moveUpAndDownLine) userInfo:nil repeats:YES];
}

- (void)stopTimer
{
    if ([_timer isValid] == YES) {
        [_timer invalidate];
        _timer = nil;
    }
}

// 滚来滚去 :D :D :D
- (void)moveUpAndDownLine
{
    CGFloat YY = _QrCodeline.frame.origin.y;
    
    if (YY != VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) + IPHONE5_SCALAE(80) ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIView animateWithDuration:1.2 animations:^{
                _QrCodeline.frame = CGRectMake(IPHONE5_SCALAE(100) + 1, VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) + IPHONE5_SCALAE(80) , VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) - 1,2);
            }];
            
        });
        
        
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [UIView animateWithDuration:1.2 animations:^{
                _QrCodeline.frame = CGRectMake(IPHONE5_SCALAE(100) + 1, IPHONE5_SCALAE(80), VIEW_WIDTH - 2 * IPHONE5_SCALAE(100) - 1,2);
            }];
            
        });
       
        
    }
}
#pragma mark==实现扫描成功后，想做的事情，就在这个代理方法里面实现就行了
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        //[session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        //输出扫描字符串
        NSLog(@"%@",metadataObject.stringValue);
        
        if ([metadataObject.stringValue hasPrefix:@"http:"]) {
            [_vpayWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:metadataObject.stringValue]]];
        }
        [session stopRunning];
        [self stopTimer];
        [AVCapView removeFromSuperview];
        //其它业务代码
    }
}
#pragma mark==取消扫描按钮
- (void)touchAVCancelBtn{
    [session stopRunning];//摄像也要停止
    [self stopTimer];//定时器要停止
    [AVCapView removeFromSuperview];//刚刚创建的 view 要移除
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
