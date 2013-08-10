//
//  ARWAppDelegate.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//


#import "ARWAppDelegate.h"
#import "ARWLib.h"

static CVReturn
ARWAppDelegateDisplayLinkOutputCallback(CVDisplayLinkRef displayLink,
										const CVTimeStamp* now,
										const CVTimeStamp* outputTime,
										CVOptionFlags flagsIn,
										CVOptionFlags* flagsOut,
										void* displayLinkContext){
	@autoreleasepool {
		ARWAppDelegate * this = (__bridge ARWAppDelegate *)displayLinkContext;
		return [this displayLinkOutputHandler:displayLink
										  now:now
								   outputTime:outputTime flagsIn:flagsIn flagsOut:flagsOut];
	}
}

@interface ARWAppDelegate()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic,strong)IBOutlet NSWindow *window;
@property(nonatomic,strong)NSView * rootView;
@property(nonatomic,strong)NSOpenGLView * glView;

@property(nonatomic,strong)NSOpenGLPixelFormat * glPixelFormat;
@property(nonatomic,strong)NSOpenGLContext * glContext;

@property(nonatomic,assign)CVDisplayLinkRef displayLink;
@property(nonatomic,assign)int displayLinkCounter;
@property(nonatomic,assign)int displayLinkInterval;

@property(nonatomic,assign)uint64_t frameCount;
@property(nonatomic,strong)NSDate * fpsCountStartTime;
@property(nonatomic,assign)int fpsFrameCount;
@property(nonatomic,assign)int actualFps;
@property(nonatomic,strong)NSDate * prevUpdateTime;
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)int fpsPrintCounter;
@property(nonatomic,assign)int fpsPrintInterval;



@property(nonatomic,strong)AVCaptureSession * captureSession;
@property(nonatomic,strong)AVCaptureDevice * camera;
@property(nonatomic,strong)AVCaptureVideoDataOutput * videoOutput;
@property(nonatomic,strong)dispatch_queue_t captureQueue;

@property(nonatomic,strong)ARWGLTexture * cameraYTexture;
@property(nonatomic,strong)ARWGLTexture * cameraUVTexture;

@property(nonatomic,strong)ARWTripleBuffering * cameraBuffering;
@property(nonatomic,strong)ARWGLCameraRenderer * cameraRenderer;

@end

@implementation ARWAppDelegate

-(void)awakeFromNib{
	NSExceptionHandler *exceptionHandler = [NSExceptionHandler defaultExceptionHandler];
    unsigned int handlingMask = NSLogAndHandleEveryExceptionMask;
    [exceptionHandler setExceptionHandlingMask:handlingMask];
    [exceptionHandler setDelegate:self];
}

-(BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask{
	return NO;
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception
					mask:(unsigned int)aMask{

	NSLog(@"Exception: %@",exception);
	NSLog(@"%@",[NSThread callStackSymbols]);
	[NSApp terminate:self];
    return NO;
}

-(void)windowWillClose:(NSNotification *)notification{
	[[NSApplication sharedApplication]terminate:self];
}

-(void)initOpenGL{
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize,24,
		NSOpenGLPFAAlphaSize,8,
		NSOpenGLPFADepthSize,32,
		0
	};
	self.glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	if(!self.glPixelFormat)@throw ARWGenericExceptionMake(@"OpenGLPixelFormat init failed");
	
	self.glContext = [[NSOpenGLContext alloc]initWithFormat:self.glPixelFormat shareContext:nil];
	if(!self.glContext)@throw ARWGenericExceptionMake(@"OpenGLContext init failed");
	
	int value = 1;
	[self.glContext setValues:&value forParameter:NSOpenGLCPSwapInterval];
	
	[self.glContext makeCurrentContext];
	
	const char *glVer = (const char *)ARWGLCallRet(const GLubyte *,glGetString,GL_VERSION);
	
	const char *slVer = (const char *)ARWGLCallRet(const GLubyte *,glGetString,GL_SHADING_LANGUAGE_VERSION);
	ARWLogInfo(@"GL: %s, GLSL: %s",glVer,slVer);
}

-(NSString *)selectCameraUniqueID{
	NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	ARWLogInfo(@"[Camera List]");
	for(AVCaptureDevice * device in devices){
		ARWLogInfo(@"%@/%@/%@",device.localizedName,device.modelID,device.uniqueID);
	}
	if(devices.count == 0)return nil;
	return [(AVCaptureDevice *)devices[0] uniqueID];
}

-(AVCaptureDevice *)selectCamera{
	NSString * cameraID = [self selectCameraUniqueID];
	if(!cameraID)return nil;
	return [AVCaptureDevice deviceWithUniqueID:cameraID];
}

//キャプチャスレッドからメインスレにポストされる
-(void)initCameraCaptureWithWidth:(uint32_t)width height:(uint32_t)height{
	if(!self.cameraBuffering){
		//二重初期化防止
		
		ARWLogInfo(@"capture init %d x %d",width,height);
		self.cameraBuffering = [[ARWTripleBuffering alloc]initWithBufferCreator:^id{
			ARWImage * image = [[ARWImage alloc]init];
			image.format = ARWImageFormatYUV420;
			image.width = width;
			image.height = height;
			image.data = [NSMutableData dataWithLength:width*height*1.5];
			return image;
		}];
	}

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{

	NSError * error;
	if(!^(NSError ** error){
		self.rootView = self.window.contentView;
		
		//メインループ
		CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
		CVDisplayLinkSetOutputCallback(_displayLink,
									   &ARWAppDelegateDisplayLinkOutputCallback,
									   (__bridge void *)(self));
		
		
		self.frameCount = 0;
		self.fpsCountStartTime = [NSDate date];
		self.fpsFrameCount = 0;
		self.actualFps = 0;
		self.prevUpdateTime = [NSDate date];
		self.updating = NO;
		self.displayLinkCounter = 0;
		self.displayLinkInterval = 2;
		self.fpsPrintCounter = 0;
		self.fpsPrintInterval = 10;
		
		//GL
		[self initOpenGL];
		[self.glContext makeCurrentContext];
		self.glView = [[NSOpenGLView alloc]initWithFrame:self.rootView.bounds
											 pixelFormat:self.glPixelFormat];
		[self.glView setOpenGLContext:self.glContext];
		[self.rootView addSubview:self.glView];
		self.glView.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

		
		//カメラ
		self.camera = [self selectCamera];
		if(!self.camera){
			if(error)*error = ARWErrorMake(ARWErrorNotFoundCamera,nil,nil);
			return NO;
		}
		
		//ARWLogInfo(@"formats = \n%@",[self.camera formats]);
		//ARWLogInfo(@"format = %@",[self.camera activeFormat]);
		
//		AVCaptureDeviceFormat * selectedFormat = self.camera.activeFormat;
//		for(AVCaptureDeviceFormat * format in self.camera.formats){
//			CMVideoFormatDescriptionRef desc = format.formatDescription;
//			CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(desc);
//			FourCharCode fcc = CMFormatDescriptionGetMediaSubType(desc);
//			ARWLogInfo(@"%@ dim %d x %d %@",
//					   ARWFourCharCodeToString(fcc),
//					   dims.width,dims.height,[format videoSupportedFrameRateRanges]);
//			if(dims.width >= 800 && dims.height >= 600){
//				selectedFormat= format;
//				break;
//			}
//		}
//		
//		[self.camera lockForConfiguration:error];
//		[self.camera setActiveFormat:selectedFormat];
//		[self.camera unlockForConfiguration];
		
		
		
		AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.camera error:error];
		if(!input)return NO;
		
		AVCaptureVideoDataOutput * output = [[AVCaptureVideoDataOutput alloc]init];
		output.alwaysDiscardsLateVideoFrames = NO;

		NSMutableDictionary * videoSettings = [NSMutableDictionary dictionary];
		videoSettings[(__bridge id)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
		output.videoSettings = videoSettings;

		self.captureQueue = dispatch_queue_create("camera queue", DISPATCH_QUEUE_SERIAL);
		[output setSampleBufferDelegate:self queue:self.captureQueue];

		//AVCaptureConnection * captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
		//captureConnection.videoMinFrameDuration = CMTimeMake(1, 60);
		
		self.captureSession = [[AVCaptureSession alloc]init];

		self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
		[self.captureSession addInput:input];
		[self.captureSession addOutput:output];
		
		self.cameraRenderer = [[ARWGLCameraRenderer alloc]init];
		
		//開始
		CVDisplayLinkStart(_displayLink);
		[self.captureSession startRunning];
		
		return YES;
	}(&error)){
		ARWLogError(@"%@",ARWErrorDump(error));
	}	
}

-(void)applicationWillTerminate:(NSNotification *)notification{

	[self.captureSession stopRunning];
	CVDisplayLinkRelease(_displayLink);
	
	self.glContext = nil;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if(CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferLockBaseAddress failed");
		return;
	}
	
	int w = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer,0);
	int h = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer,0);
	
	if(!self.cameraBuffering){
		
		dispatch_async(dispatch_get_main_queue(), ^{
			//二重防止されてる
			[self initCameraCaptureWithWidth:w height:h];
		});
		
	}else{
		
		ARWImage * backBuffer = [self.cameraBuffering lock];
		
		uint8_t * d = (uint8_t *)[backBuffer.data mutableBytes];
		{
			uint8_t * s = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,0);
			int stride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
			for(int yi = 0;yi<h;yi++){
				memcpy(d,s,w);
				d += w;
				s += stride;
			}
		}
		
		{
			uint8_t * s = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer,1);
			int stride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
			for(int yi=0;yi<h/2;yi++){
				memcpy(d,s,w);
				d += w;
				s += stride;
			}
		}
		
		//ARWLogInfo(@"write %@ %d x %d",backBuffer,w,h);
		
		[self.cameraBuffering unlock];
	}
		
	if(CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferUnlockBaseAddress failed");
		return;
	}
}

-(void)updateWithDeltaTime:(double)deltaTime{
	[self.glContext makeCurrentContext];
	
	if(self.cameraBuffering){
		[self.cameraBuffering swap];
		ARWImage * cameraImage = [self.cameraBuffering front];
		
		if(!self.cameraYTexture){
			self.cameraYTexture = [[ARWGLTexture alloc]init];
			[self.cameraYTexture setImageWithWidth:cameraImage.width
										   height:cameraImage.height
								   internalFormat:GL_LUMINANCE];
			
			self.cameraUVTexture = [[ARWGLTexture alloc]init];
			[self.cameraUVTexture setImageWithWidth:cameraImage.width/2
											 height:cameraImage.height/2
									 internalFormat:GL_LUMINANCE_ALPHA];
		}

		[self.cameraYTexture setSubImageWithFormat:GL_LUMINANCE type:GL_UNSIGNED_BYTE data:cameraImage.data.bytes];
		int yLen = cameraImage.width * cameraImage.height;
		[self.cameraUVTexture setSubImageWithFormat:GL_LUMINANCE_ALPHA type:GL_UNSIGNED_BYTE
											   data:(uint8_t *)cameraImage.data.bytes + yLen];
	}
	
	[NSOpenGLContext clearCurrentContext];
}
-(void)render{
	[self.glContext makeCurrentContext];
	
	ARWGLCall(glClearColor,0.f,0.f,0.2f,1.f);
	ARWGLCall(glClear,GL_COLOR_BUFFER_BIT);

	CGRect bounds = self.glView.bounds;
	ARWGLCall(glViewport,0, 0,CGRectGetWidth(bounds), CGRectGetHeight(bounds));
	
	ARWGLCall(glMatrixMode,GL_PROJECTION);
	glLoadIdentity();
	
	ARWGLCall(glMatrixMode,GL_MODELVIEW);
	glLoadIdentity();
	
	if(self.cameraYTexture){
		[self.cameraRenderer renderWithYTexture:self.cameraYTexture
									  uvTexture:self.cameraUVTexture];
	}
	
	[self.glContext flushBuffer];
	
	[NSOpenGLContext clearCurrentContext];
}

-(void)updateFrameHandler{
	self.frameCount++;
	self.fpsFrameCount++;
	
	NSDate * now = [NSDate date];
	if([now timeIntervalSinceDate:self.fpsCountStartTime] >= 1.0){
		self.fpsCountStartTime = now;
		self.actualFps = self.fpsFrameCount;
		self.fpsFrameCount = 0;
		self.fpsPrintCounter ++;
		if(self.fpsPrintCounter >= self.fpsPrintInterval){
			self.fpsPrintCounter = 0;
			ARWLogInfo(@"fps %d",self.actualFps);
		}
	}
	double deltaTime = [now timeIntervalSinceDate:self.prevUpdateTime];
	self.prevUpdateTime = now;
	
	[self updateWithDeltaTime:deltaTime];
	[self render];
}

-(CVReturn)displayLinkOutputHandler:(CVDisplayLinkRef)displayLink
								now:(const CVTimeStamp*) now
						 outputTime:(const CVTimeStamp*) outputTime
							flagsIn:(CVOptionFlags)flagsIn
						   flagsOut:(CVOptionFlags*)flagsOut{
	
	self.displayLinkCounter++;
	if(self.displayLinkCounter >= self.displayLinkInterval){
		self.displayLinkCounter = 0;
		if(!self.updating){
			self.updating = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateFrameHandler];
				self.updating = NO;
			});
		}
		
	}
	return kCVReturnSuccess;
}

@end


