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

@property(nonatomic,strong)ARWTripleBuffering * cameraBuffering;
@property(nonatomic,strong)ARWGLCameraRenderer * cameraRenderer;

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
		
		self.cameraBuffering = [[ARWTripleBuffering alloc]initWithBufferCreator:^id{
			float w = 1280;
			float h = 960;
			ARWImage * image = [[ARWImage alloc]init];
			image.format = ARWImageFormatYUV420;
			image.width = w;
			image.height = h;
			image.data = [NSMutableData dataWithLength:w*h*2];
			return image;
		}];
		
		self.cameraTexture = [[ARWGLTexture alloc]init];
		
		self.cameraRenderer = [[ARWGLCameraRenderer alloc]init];
		
		return YES;
	}(&error)){
		ARWLogError(@"%@",ARWErrorDump(error));
	}	
}

-(void)applicationWillTerminate:(NSNotification *)notification{

	[self.captureSession stopRunning];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if(CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferLockBaseAddress failed");
		return;
	}
	
	ARWImage * backBuffer = [self.cameraBuffering lock];
	
	uint8_t * d = (uint8_t *)[backBuffer.data mutableBytes];

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

	ARWLogInfo(@"write %@",backBuffer);
	
//	d = (uint8_t *)[backBuffer.data mutableBytes];
//	for(int yi = 0;yi<h;yi++){
//		for(int xi = 0;xi<w;xi++){
//			d[0] = 255;
//			d[1] = 128;
//			d[2] = 0;
//			d[3] = 255;
//			d+=4;
//		}
//	}
//	
	
	[self.cameraBuffering unlock];
	
	if(CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)){
		ARWLogError(@"CVPixelBufferUnlockBaseAddress failed");
		return;
	}
}



-(void)glView:(ARWGLView *)glView updateWithDeltaTime:(double)deltaTime{
	//ARWLogInfo(@"%f",deltaTime);
	[self updateWithDeltaTime:deltaTime];
	[self render];
}

-(void)updateWithDeltaTime:(double)deltaTime{
	[self.cameraBuffering swap];
	ARWImage * cameraImage = [self.cameraBuffering front];
	
		ARWLogInfo(@"read %@",cameraImage);

	[self.cameraTexture setImageWithWidth:cameraImage.width height:cameraImage.height
						   internalFormat:GL_LUMINANCE format:GL_LUMINANCE
									 type:GL_UNSIGNED_BYTE data:cameraImage.data.bytes];
	
	
}
-(void)render{

	ARWGLCall(glClearColor,0.f,0.f,0.2f,1.f);
	ARWGLCall(glClear,GL_COLOR_BUFFER_BIT);

	CGRect bounds = self.glView.bounds;
	ARWGLCall(glViewport,0, 0,CGRectGetWidth(bounds), CGRectGetHeight(bounds));
	
	ARWGLCall(glMatrixMode,GL_PROJECTION);
	glLoadIdentity();
	
	ARWGLCall(glMatrixMode,GL_MODELVIEW);
	glLoadIdentity();
	
	[self.cameraRenderer render:self.cameraTexture];
	
	ARWGLCall(glFlush);
}

@end
