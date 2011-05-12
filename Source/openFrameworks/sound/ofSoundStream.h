#ifndef _OF_SOUND_STREAM
#define _OF_SOUND_STREAM

#include "ofConstants.h"
#include "ofEvents.h"
#include "ofMath.h"

void ofSoundStreamSetup(int nOutputChannels, int nInputChannels, id OFSA = NULL);
void ofSoundStreamStart();
void ofSoundStreamStop();
void ofSoundStreamClose();

#endif
