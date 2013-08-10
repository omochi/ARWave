//
//  ARWAppDelegate.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//


#import "ARWAppDelegate.h"
#import "ARWLib.h"

#import "ARWGLView.h"

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

@interface ARWAppDelegate()<ARWGLViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
//ビュー
@property(nonatomic,strong)IBOutlet NSWindow *window;
@property(nonatomic,strong)NSView * rootView;
@property(nonatomic,strong)ARWGLView * glView;

//GL
@property(nonatomic,strong)NSOpenGLPixelFormat * glPixelFormat;
@property(nonatomic,strong)NSOpenGLContext * glContext;

//ディスプレイリンク
@property(nonatomic,assign)CVDisplayLinkRef displayLink;
@property(nonatomic,assign)int displayLinkCounter;
@property(nonatomic,assign)int displayLinkInterval;

//メインループ
@property(nonatomic,assign)uint64_t frameCount;
@property(nonatomic,strong)NSDate * fpsCountStartTime;
@property(nonatomic,assign)int fpsFrameCount;
@property(nonatomic,assign)int actualFps;
@property(nonatomic,strong)NSDate * prevUpdateTime;
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)int fpsPrintCounter;
@property(nonatomic,assign)int fpsPrintInterval;

//カメラ
@property(nonatomic,strong)AVCaptureSession * videoCaptureSession;
@property(nonatomic,strong)AVCaptureDevice * captureCamera;
@property(nonatomic,strong)AVCaptureVideoDataOutput * videoCaptureOutput;
@property(nonatomic,strong)ARWGLTexture * cameraYTexture;
@property(nonatomic,strong)ARWGLTexture * cameraUVTexture;
@property(nonatomic,strong)ARWTripleBuffering * cameraBuffering;
@property(nonatomic,strong)ARWGLCameraRenderer * cameraRenderer;

//サウンド
@property(nonatomic,strong)AVCaptureSession * audioCaptureSession;
@property(nonatomic,strong)AVCaptureDevice * captureMic;
@property(nonatomic,assign)AudioStreamBasicDescription audioCaptureFormat;
@property(nonatomic,strong)AVCaptureAudioDataOutput * audioCaptureOutput;
@property(nonatomic,strong)NSMutableData * capturedAudioStream;

//表示分
@property(nonatomic,strong)NSMutableData * waveAudioStream;
@property(nonatomic,assign)float waveAudioSampleInterval;
@property(nonatomic,assign)float waveAudioMaxTimeLen;

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
		ARWLogInfo(@"[%@]/[%@]/[%@]",device.localizedName,device.modelID,device.uniqueID);
	}
	if(devices.count == 0)return nil;
	return [(AVCaptureDevice *)devices[0] uniqueID];
}

-(AVCaptureDevice *)selectCamera{
	NSString * cameraID = [self selectCameraUniqueID];
	if(!cameraID)return nil;
	return [AVCaptureDevice deviceWithUniqueID:cameraID];
}

-(NSString *)selectMicUniqueID{
	NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
	ARWLogInfo(@"[Mic List]");
	for(AVCaptureDevice * device in devices){
		ARWLogInfo(@"[%@]/[%@]/[%@]",device.localizedName,device.modelID,device.uniqueID);
	}
	if(devices.count == 0)return nil;
	return [(AVCaptureDevice *)devices[0] uniqueID];
}

-(AVCaptureDevice *)selectMic{
	NSString * micID = [self selectMicUniqueID];
	if(!micID)return nil;
	return [AVCaptureDevice deviceWithUniqueID:micID];
}

-(BOOL)initVideoCaptureWithError:(NSError **)error{
	//カメラ
	self.captureCamera = [self selectCamera];
	if(!self.captureCamera){
		if(error)*error = ARWErrorMake(ARWErrorNoCamera,nil,nil);
		return NO;
	}
	
	AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureCamera error:error];
	if(!input)return NO;
	
	self.videoCaptureOutput = [[AVCaptureVideoDataOutput alloc]init];
	self.videoCaptureOutput.alwaysDiscardsLateVideoFrames = NO;
	
	NSMutableDictionary * videoSettings = [NSMutableDictionary dictionary];
	videoSettings[(__bridge id)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
	self.videoCaptureOutput.videoSettings = videoSettings;
	
	[self.videoCaptureOutput setSampleBufferDelegate:self
											   queue:dispatch_queue_create("video queue", DISPATCH_QUEUE_SERIAL)];
	
	self.videoCaptureSession = [[AVCaptureSession alloc]init];
	self.videoCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
	[self.videoCaptureSession addInput:input];
	[self.videoCaptureSession addOutput:self.videoCaptureOutput];
	
	self.cameraRenderer = [[ARWGLCameraRenderer alloc]init];
	
	return YES;
}

-(BOOL)initAudioCaptureWithError:(NSError **)error{
	self.captureMic = [self selectMic];
	if(!self.captureMic){
		if(error)*error = ARWErrorMake(ARWErrorNoMic,nil,nil);
		return NO;
	}
	
	if(!self.captureMic.connected){
		if(error)*error = ARWErrorMake(ARWErrorNotConnected,nil,@"%@",self.captureMic.localizedName);
		return NO;
	}
	
	
	//モノラルfloat
	_audioCaptureFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(self.captureMic.activeFormat.formatDescription);
	_audioCaptureFormat.mFormatID = kAudioFormatLinearPCM;
	//ここだけ元の値を考慮
	_audioCaptureFormat.mSampleRate = MIN(48000,self.audioCaptureFormat.mSampleRate);
	_audioCaptureFormat.mChannelsPerFrame = 1;
	_audioCaptureFormat.mBitsPerChannel = sizeof(float) * 8;
	_audioCaptureFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
	
	AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureMic error:error];
	if(!input)return NO;
	
	self.audioCaptureOutput = [[AVCaptureAudioDataOutput alloc]init];
	NSMutableDictionary * audioSettings = [NSMutableDictionary dictionary];
	audioSettings[AVFormatIDKey] = @(kAudioFormatLinearPCM);
	audioSettings[AVSampleRateKey] = @(_audioCaptureFormat.mSampleRate);
	audioSettings[AVLinearPCMIsFloatKey] = @((_audioCaptureFormat.mFormatFlags & kLinearPCMFormatFlagIsFloat) != 0);
	audioSettings[AVNumberOfChannelsKey] = @(_audioCaptureFormat.mChannelsPerFrame);
	audioSettings[AVLinearPCMBitDepthKey] = @(_audioCaptureFormat.mBitsPerChannel);
	self.audioCaptureOutput.audioSettings = audioSettings;
		
	[self.audioCaptureOutput setSampleBufferDelegate:self
											   queue:dispatch_queue_create("audio queue", DISPATCH_QUEUE_SERIAL)];
	
	self.audioCaptureSession = [[AVCaptureSession alloc]init];
	[self.audioCaptureSession addInput:input];
	[self.audioCaptureSession addOutput:self.audioCaptureOutput];
	
	self.capturedAudioStream = [[NSMutableData alloc]init];
	
	return YES;
}

//キャプチャスレッドからメインスレにポストされる
-(void)initCameraBufferingWithWidth:(uint32_t)width height:(uint32_t)height{
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
		self.displayLinkInterval = 1;
		self.fpsPrintCounter = 0;
		self.fpsPrintInterval = 10;
		
		//GL
		[self initOpenGL];
		[self.glContext makeCurrentContext];
		self.glView = [[ARWGLView alloc]initWithFrame:self.rootView.bounds
										  pixelFormat:self.glPixelFormat];
		[self.glView setOpenGLContext:self.glContext];
		[self.rootView addSubview:self.glView];
		self.glView.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
		self.glView.delegate = self;

		if(![self initVideoCaptureWithError:error])return NO;
		
		if(![self initAudioCaptureWithError:error])return NO;
	
		//開始
		CVDisplayLinkStart(_displayLink);
		[self.videoCaptureSession startRunning];
		[self.audioCaptureSession startRunning];
		
		self.waveAudioStream = [[NSMutableData alloc]init];
		self.waveAudioSampleInterval = 0.001;
		self.waveAudioMaxTimeLen = 1.f;
		
		return YES;
	}(&error)){
		ARWLogError(@"%@",ARWErrorDump(error));
	}	
}

-(void)applicationWillTerminate:(NSNotification *)notification{

	[self.audioCaptureSession stopRunning];
	[self.videoCaptureSession stopRunning];
	CVDisplayLinkRelease(_displayLink);
	
	self.glContext = nil;
}

-(void)videoCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	
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
			[self initCameraBufferingWithWidth:w height:h];
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

-(void)audioCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	
	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    //const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

	int64_t numSample = CMSampleBufferGetNumSamples(sampleBuffer);
	
	//
//	if(asbd->mFormatID != kAudioFormatLinearPCM ||
//	   asbd->mSampleRate != self.audioCaptureFormat.mSampleRate){
//		ARWLogError(@"audio capture error: format: %@, sampleRate: %f",ARWFourCharCodeToString(asbd->mFormatID),asbd->mSampleRate);
//		return;
//	}
	
	CMBlockBufferRef blockBuffer;
	AudioBufferList audioBufferList;
	
	if(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList,sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer)){
		ARWLogError(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
		return;
	}
	
	uint64_t dataLen = CMBlockBufferGetDataLength(blockBuffer);
	
	@synchronized(self){
		uint64_t oldLen = self.capturedAudioStream.length;
		[self.capturedAudioStream setLength:oldLen + dataLen];
		if(CMBlockBufferCopyDataBytes(blockBuffer,0,dataLen,
									  (uint8_t *)self.capturedAudioStream.mutableBytes + oldLen)){
			ARWLogError(@"CMBlockBufferCopyDataBytes failed");
			CFRelease(blockBuffer);
			return;
		}
		
		//0.1秒分までしか溜め込まない
		uint64_t maxSampleNum = self.audioCaptureFormat.mSampleRate * 0.1;
		uint64_t sampleNum = self.capturedAudioStream.length / sizeof(float);
		
		if(sampleNum > maxSampleNum){
			uint64_t deleteLen = (sampleNum - maxSampleNum) * sizeof(float);
			[self.capturedAudioStream replaceBytesInRange:NSMakeRange(0,deleteLen) withBytes:NULL length:0];
		}
		
		//ARWLogInfo(@"capture sample %ld",self.capturedAudioStream.length / sizeof(float));
		
		//ARWLogInfo(@"captured audio %ld bytes",self.capturedAudioStream.length);
	}
		
	CFRelease(blockBuffer);
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

	if(captureOutput == self.videoCaptureOutput){
		[self videoCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
	}else if(captureOutput == self.audioCaptureOutput){
		[self audioCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
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
	
	//このフレームの分を吸着
	@synchronized(self){
		float sampleRate = self.audioCaptureFormat.mSampleRate;
		int numSample = MIN(deltaTime * sampleRate,self.capturedAudioStream.length / sizeof(float));
							
		float * pSample = (float *)self.capturedAudioStream.bytes;
		float sampleTime = 0.f;
		float sampleSum = 0.f;
		int sampleSumCount = 0;
		//ミリ秒単位にする
		for(int si = 0;si < numSample;si++){
			sampleTime += 1.f / sampleRate;
			sampleSum += *pSample;
			sampleSumCount++;
			pSample++;
			if(sampleTime >= self.waveAudioSampleInterval){
				
				sampleTime -= self.waveAudioSampleInterval;
				float waveValue = sampleSum / (float)sampleSumCount;
				sampleSum = 0;
				sampleSumCount = 0;
				[self.waveAudioStream appendBytes:&waveValue length:sizeof(float)];
			}
		}
		
		//ARWLogInfo(@"wave sample %ld",self.waveAudioStream.length / sizeof(float));
	}
	
	//1秒分をキープ
	
	int keepSampleNum = self.waveAudioMaxTimeLen / self.waveAudioSampleInterval; //1kHzで1Sec
	
	int64_t waveNum = self.waveAudioStream.length / sizeof(float);
	if(waveNum > keepSampleNum){
		uint64_t deleteLen = (waveNum-keepSampleNum)*sizeof(float);
		[self.waveAudioStream replaceBytesInRange:NSMakeRange(0,deleteLen) withBytes:NULL length:0];
	}
	
	[NSOpenGLContext clearCurrentContext];
}
-(void)render{
	[self.glContext makeCurrentContext];
	
	ARWGLCall(glClearColor,0.f,0.f,0.2f,1.f);
	ARWGLCall(glClear,GL_COLOR_BUFFER_BIT);

	float w = CGRectGetWidth(self.glView.bounds);
	float h = CGRectGetHeight(self.glView.bounds);
	CGRect bounds = self.glView.bounds;
	ARWGLCall(glViewport,0, 0,w,h);
	
	ARWGLCall(glMatrixMode,GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, w,h,0, -1.0,1.0);
	
	ARWGLCall(glMatrixMode,GL_MODELVIEW);
	glLoadIdentity();
	
	if(self.cameraYTexture){
		glPushMatrix();
		
		CGRect cameraFrame = ARWRectAspectFill(CGRectMake(0, 0, w, h),
											   CGSizeMake(self.cameraYTexture.width, self.cameraYTexture.height),
											   ARWLayoutGravityCenter);
		glTranslatef(CGRectGetMinX(cameraFrame),CGRectGetMinY(cameraFrame), 0.f);
		glScalef(CGRectGetWidth(cameraFrame)/2.f, CGRectGetHeight(cameraFrame)/2.f, 1.f);
		
		glTranslatef(1.f, 1.f, 0.f);
		[self.cameraRenderer renderWithYTexture:self.cameraYTexture
									  uvTexture:self.cameraUVTexture vFlip:NO];
		
		glPopMatrix();
	}
	
	{
		int maxNum = (int)(self.waveAudioMaxTimeLen/self.waveAudioSampleInterval);
		float vertices[maxNum*3];
		float * v = vertices + 0;
		float * waveValue = (float *)self.waveAudioStream.bytes;
		int num = (int)(self.waveAudioStream.length / sizeof(float));
		for(int i=0;i<maxNum;i++){
			v[0] = i/(float)(maxNum-1);
			if(i < num){
				v[1] = waveValue[i];
				if(i+1 == num){
					//ARWLogInfo(@"[%d] = %f",i,waveValue[i]);
				}
			}else{
				v[1] = 0.f;
			}
			v[2] = 0.f;
			v+=3;
		}
		
		glPushMatrix();
		
		glTranslatef(0, h/2.f, 0.f);
		glScalef(w, h/2.f, 1.f);
		ARWGLCall(glColor3f,0.1, 0.9, 0.1);
		
		ARWGLCall(glEnableClientState,GL_VERTEX_ARRAY);
		ARWGLCall(glVertexPointer,3,GL_FLOAT,sizeof(float)*3,vertices);
		
		ARWGLCall(glDrawArrays,GL_LINE_STRIP, 0, maxNum);
		
		ARWGLCall(glDisableClientState,GL_VERTEX_ARRAY);
		
		glPopMatrix();
	}
	[self.glContext flushBuffer];
	
	[NSOpenGLContext clearCurrentContext];
}

-(void)glViewDidUpdate:(ARWGLView *)glView{
	//これでチラつかない
	[self render];
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


