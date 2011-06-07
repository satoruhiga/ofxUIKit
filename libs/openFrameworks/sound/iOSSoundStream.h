#pragma once

#include <AudioToolbox/AudioToolbox.h>

class iOSSoundStream
{
	bool isRunning, isInited;
	
	int sampleRate;
	AudioStreamBasicDescription format, audioFormat;
	AudioUnit audioUnit;
	
	float *inputSampleBuffer;

	static OSStatus recordingCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);
	
	static OSStatus playbackCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);
	
public:

	iOSSoundStream();
	virtual ~iOSSoundStream();

	void open(int nOutputs, int nInputs, int samplerate);
	void start();
	void stop();
	void close();
	
	virtual void audioRequested(float *output, int bufferSize, int numChannels) {}
	virtual void audioReceived(const float *input, int bufferSize, int numChannels) {}
	
	const int getSampleRate() const { return sampleRate; }
};