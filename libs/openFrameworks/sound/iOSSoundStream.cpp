#include "iOSSoundStream.h"

#define kOutputBus  0
#define kInputBus   1
#define MAX_BUFFER_SIZE 4096

static void rioInterruptionListener(void *inClientData, UInt32 inInterruption) {}

iOSSoundStream::iOSSoundStream()
{
	isInited = false;
	isRunning = false;

	audioUnit = NULL;
	inputSampleBuffer = NULL;
}

iOSSoundStream::~iOSSoundStream()
{
	close();
}

void iOSSoundStream::open(int nOutputs, int nInputs, int sampleRate)
{
	if (isInited) return;

	this->sampleRate = sampleRate;

	OSStatus status;

	status = AudioSessionInitialize(NULL, NULL, rioInterruptionListener, NULL);
	assert(status == noErr);

	status = AudioSessionSetActive(true);
	assert(status == noErr);
	
	Float32 preferredBufferSize = (float)2048 / sampleRate;

	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	assert(status == noErr);

	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;

	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);

	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	assert(status == noErr);
	
	UInt32 flag = 1;
	UInt32 category = 1;
	AudioSessionSetProperty(kAudioSessionOverrideAudioRoute_Speaker, sizeof(category), &category);

	audioFormat.mSampleRate = (double)sampleRate;
	audioFormat.mFormatID = kAudioFormatLinearPCM;
	audioFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
	audioFormat.mFramesPerPacket = 1;
	audioFormat.mBitsPerChannel = 32;

	AURenderCallbackStruct callbackStruct;

	if (nOutputs > 0)
	{
		status = AudioUnitSetProperty(audioUnit,
									  kAudioOutputUnitProperty_EnableIO,
									  kAudioUnitScope_Output,
									  kOutputBus,
									  &flag,
									  sizeof(flag));
		assert(status == noErr);

		audioFormat.mChannelsPerFrame = nOutputs;
		audioFormat.mBytesPerPacket = nOutputs * sizeof(float);
		audioFormat.mBytesPerFrame = audioFormat.mBytesPerPacket * audioFormat.mFramesPerPacket;

		status = AudioUnitSetProperty(audioUnit,
									  kAudioUnitProperty_StreamFormat,
									  kAudioUnitScope_Input,
									  kOutputBus,
									  &audioFormat,
									  sizeof(audioFormat));
		assert(status == noErr);
		
		callbackStruct.inputProc = playbackCallback;
		callbackStruct.inputProcRefCon = this;
		status = AudioUnitSetProperty(audioUnit,
									  kAudioUnitProperty_SetRenderCallback,
									  kAudioUnitScope_Global,
									  kOutputBus,
									  &callbackStruct,
									  sizeof(callbackStruct));
		assert(status == noErr);
	}
	if (nInputs > 0)
	{
		inputSampleBuffer = new float [MAX_BUFFER_SIZE * sizeof(float)];

		status = AudioUnitSetProperty(audioUnit,
									  kAudioOutputUnitProperty_EnableIO,
									  kAudioUnitScope_Input,
									  kInputBus,
									  &flag,
									  sizeof(flag));

		audioFormat.mChannelsPerFrame = nInputs;
		audioFormat.mBytesPerPacket = nInputs * sizeof(float);
		audioFormat.mBytesPerFrame = audioFormat.mBytesPerPacket * audioFormat.mFramesPerPacket;

		status = AudioUnitSetProperty(audioUnit,
									  kAudioUnitProperty_StreamFormat,
									  kAudioUnitScope_Output,
									  kInputBus,
									  &audioFormat,
									  sizeof(audioFormat));
		assert(status == noErr);

		callbackStruct.inputProc = recordingCallback;
		callbackStruct.inputProcRefCon = this;
		status = AudioUnitSetProperty(audioUnit,
									  kAudioOutputUnitProperty_SetInputCallback,
									  kAudioUnitScope_Global,
									  kInputBus,
									  &callbackStruct,
									  sizeof(callbackStruct));
		assert(status == noErr);
	}

	UInt32 shouldAllocateBuffer = 1;
	AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Global, 1, &shouldAllocateBuffer, sizeof(shouldAllocateBuffer));

	status = AudioUnitInitialize(audioUnit);
	assert(status == noErr);

	isInited = true;
}

void iOSSoundStream::start()
{
	if (isRunning) stop();

	OSStatus status = AudioOutputUnitStart(audioUnit);
	assert(status == noErr);

	isRunning = true;
}

void iOSSoundStream::stop()
{
	if (isRunning)
	{
		OSStatus status = AudioOutputUnitStop(audioUnit);
		assert(status == noErr);
	}

	isRunning = false;
}

void iOSSoundStream::close()
{
	stop();

	if (isInited)
	{
		AudioUnitUninitialize(audioUnit);

		audioUnit = NULL;
		delete [] inputSampleBuffer;
		inputSampleBuffer = NULL;

		isInited = false;
	}
}

#pragma mark callback

OSStatus iOSSoundStream::playbackCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
	iOSSoundStream *self = (iOSSoundStream*)inRefCon;

	assert(ioData->mNumberBuffers == 1);

	AudioBuffer &buf = ioData->mBuffers[0];
	float *output = (float*)buf.mData;
	const int numChannels = buf.mNumberChannels;
	
	memset(output, 0, buf.mDataByteSize);

	self->audioRequested(output, inNumberFrames, numChannels);

	return noErr;
}

OSStatus iOSSoundStream::recordingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
	iOSSoundStream *self = (iOSSoundStream*)inRefCon;

	AudioBufferList list;

	list.mNumberBuffers = 1;
	list.mBuffers[0].mData = self->inputSampleBuffer;
	list.mBuffers[0].mDataByteSize = sizeof(float) * inNumberFrames;
	list.mBuffers[0].mNumberChannels = 1;

	ioData = &list;

	OSStatus status = AudioUnitRender(self->audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	assert(status == noErr);
	
	assert(ioData->mNumberBuffers == 1);

	const AudioBuffer &buf = ioData->mBuffers[0];
	const float *input = (const float*)buf.mData;
	const int numChannels = buf.mNumberChannels;
	const int numFrames = buf.mDataByteSize / sizeof(float) / numChannels;

	self->audioReceived(input, numFrames, numChannels);

	return noErr;
}