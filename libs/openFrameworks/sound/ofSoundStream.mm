#import "ofSoundStream.h"

#import "ofMain.h"

#import "iOSSoundStream.h"

static iOSSoundStream *stream = NULL;

//---------------------------------------------------------
void ofSoundStreamSetup(int nOutputs, int nInputs, id OFSA)
{
	ofSoundStreamClose();
	
	stream = new iOSSoundStream();
	stream->open(nOutputs, nInputs, 44100);
	
	ofSoundStreamStart();
}

//---------------------------------------------------------
void ofSoundStreamStart()
{
	if (stream)
	{
		stream->start();
	}
}

//---------------------------------------------------------
void ofSoundStreamStop()
{
	if (stream)
	{
		stream->stop();
	}
}

//---------------------------------------------------------
void ofSoundStreamClose()
{
	ofSoundStreamStop();
	
	if (stream)
	{
		stream->close();
	}
	
	delete stream;
	stream = NULL;
}
