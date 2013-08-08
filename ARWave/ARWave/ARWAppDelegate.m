//
//  ARWAppDelegate.m
//  ARWave
//
//  Created by おもちメタル on 2013/08/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "ARWAppDelegate.h"
#import "ARWGLView.h"
#import "ARWLib.h"

@interface ARWAppDelegate()<ARWGLViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic,strong)IBOutlet NSWindow *window;
@property(nonatomic,strong)IBOutlet NSOpenGLView * glView;

@property(nonatomic,strong)AVCaptureSession * captureSession;
@property(nonatomic,strong)AVCaptureDevice * camera;
@property(nonatomic,strong)AVCaptureVideoDataOutput * videoOutput;
@property(nonatomic,strong)dispatch_queue_t captureQueue;

@property(nonatomic,strong)ARWGLTexture * cameraTexture;

@property(nonatomic,strong)NSArray * cameraBuffers;
@property(nonatomic,assign)int cameraBuffersFrontIndex;
@property(nonatomic,strong)NSRecursiveLock * cameraBuffersLock;
@end

@implementation ARWAppDelegate

-(void)windowWillClose:(NSNotification *)notification{
	[[NSApplication sharedApplication]terminate:self];
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSError * error;
	if(!^(NSError ** error){
		
		
		self.captureSession = [[AVCaptureSession alloc]init];
		self.camera = [self selectCamera];
		if(!self.camera){
			if(error)*error = ARWErrorMake(ARWErrorNotFoundCamera,nil,nil);
			return NO;
		}
		AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:self.camera error:error];
		if(!input)return NO;
		[self.captureSession addInput:input];
		
		AVCaptureVideoDataOutput * output = [[AVCaptureVideoDataOutput alloc]init];
		[self.captureSession addOutput:output];
		output.alwaysDiscardsLateVideoFrames = YES;
		NSMutableDictionary * videoSettings = [NSMutableDictionary dictionary];
		videoSettings[(__bridge id)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
		output.videoSettings = videoSettings;
		
		self.captureQueue = dispatch_queue_create("camera queue", DISPATCH_QUEUE_SERIAL);
		
		[output setSampleBufferDelegate:self queue:self.captureQueue];
		
		self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
		
		[self.captureSession startRunning];
		
		uint32_t bufferSize = 1280*720*2;
		
		NSMutableArray * cameraBuffers = [NSMutableArray array];
		[cameraBuffers addObject:[NSMutableData dataWithLength:bufferSize]];
		[cameraBuffers addObject:[NSMutableData dataWithLength:bufferSize]];
		self.cameraBuffers = cameraBuffers;
		self.cameraBuffersFrontIndex = 0;
		self.cameraBuffersLock = [[NSRecursiveLock alloc]init];
		
		
		self.cameraTexture = [[ARWGLTexture alloc]init];
		
		return YES;
	}(&error)){
		ARWLogError(@"%@",ARWErrorDump(error));
	}	
}

-(void)applicationWillTerminate:(NSNotification *)notification{

	[self.captureSession stopRunning];
}


-(void)cameraBuffersSwap{
	[self.cameraBuffersLock lock];
	self.cameraBuffersFrontIndex ++;
	self.cameraBuffersFrontIndex %= self.cameraBuffers.count;
	[self.cameraBuffersLock unlock];
}

-(NSMutableData *)cameraBuffersBackBuffer{
	return self.cameraBuffers[ (self.cameraBuffersFrontIndex+1) % self.cameraBuffers.count ];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if(CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferLockBaseAddress failed");
		return;
	}
	
	NSMutableData * backBuffer = [self cameraBuffersBackBuffer];
	uint8_t * d = (uint8_t *)[backBuffer mutableBytes];

	int w = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer,0);
	int h = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer,0);
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
	
	if(CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferUnlockBaseAddress failed");
		return;
	}
	
	[self cameraBuffersSwap];
}



-(void)glView:(ARWGLView *)glView updateWithDeltaTime:(double)deltaTime{
	//ARWLogInfo(@"%f",deltaTime);
	[self updateWithDeltaTime:deltaTime];
	[self render];
}

-(void)updateWithDeltaTime:(double)deltaTime{
	
}
-(void)render{
	glClearColor(0.f,0.f,0.2f,1.f);
	glClear(GL_COLOR_BUFFER_BIT);
	
	glFlush();
}

@end
