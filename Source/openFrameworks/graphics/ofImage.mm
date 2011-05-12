#include "ofImage.h"

#import <UIKit/UIKit.h>

//----------------------------------------------------------
ofImage::ofImage()
{
	myPixels.width = 0;
	myPixels.height = 0;
	myPixels.bitsPerPixel = 0;
	myPixels.bytesPerPixel = 0;
	myPixels.glDataType = GL_LUMINANCE;
	myPixels.ofImageType = OF_IMAGE_UNDEFINED;
	myPixels.bAllocated = false;

	width = 0;
	height = 0;
	bpp = 0;
	type = OF_IMAGE_UNDEFINED;
	bUseTexture = true;     // the default is, yes, use a texture
}

//----------------------------------------------------------
ofImage& ofImage::operator = (const ofImage &mom) {
	clone(mom);
	update();
	return *this;
}

//----------------------------------------------------------
ofImage::ofImage(const ofImage& mom)
{
	myPixels.bAllocated = false;

	clear();
	clone(mom);
	update();
};

//----------------------------------------------------------
ofImage::~ofImage()
{
	clear();
}

//----------------------------------------------------------
bool ofImage::loadImage(string fileName)
{
	bool bLoadedOk = false;
	bLoadedOk = loadImageIntoPixels(fileName, myPixels);

	if (bLoadedOk == true)
	{
		if (myPixels.bAllocated == true && bUseTexture == true)
		{
			tex.allocate(myPixels.width, myPixels.height, myPixels.glDataType);
		}
		update();
	}

	return bLoadedOk;
}

//----------------------------------------------------------
void ofImage::saveImage(string fileName)
{
	saveImageFromPixels(fileName, myPixels);
}

//we could cap these values - but it might be more useful
//to be able to set anchor points outside the image

//----------------------------------------------------------
void ofImage::setAnchorPercent(float xPct, float yPct)
{
	if (bUseTexture) tex.setAnchorPercent(xPct, yPct);
}

//----------------------------------------------------------
void ofImage::setAnchorPoint(float x, float y)
{
	if (bUseTexture) tex.setAnchorPoint(x, y);
}

//----------------------------------------------------------
void ofImage::resetAnchor()
{
	if (bUseTexture) tex.resetAnchor();
}

//------------------------------------
void ofImage::draw(float _x, float _y, float _w, float _h)
{
	if (bUseTexture)
	{
		tex.draw(_x, _y, _w, _h);
	}
}

//------------------------------------
void ofImage::draw(float x, float y)
{
	draw(x, y, myPixels.width, myPixels.height);
}

//------------------------------------
void ofImage::allocate(int w, int h, int type)
{
	int newBpp = 0;

	switch (type)
	{
	case OF_IMAGE_GRAYSCALE:
		newBpp = 8;
		break;
	case OF_IMAGE_COLOR:
		newBpp = 24;
		break;
	case OF_IMAGE_COLOR_ALPHA:
		newBpp = 32;
		break;
	default:
		ofLog(OF_LOG_ERROR, "error = bad imageType in ofImage::allocate");
		return;
	}

	allocatePixels(myPixels, w, h, newBpp);

	// take care of texture allocation --
	if (myPixels.bAllocated == true && bUseTexture == true)
	{
		tex.allocate(myPixels.width, myPixels.height, myPixels.glDataType);
	}

	update();
}


//------------------------------------
void ofImage::clear()
{
	if (myPixels.bAllocated == true)
	{
		delete[] myPixels.pixels;
	}
	
	if (bUseTexture) tex.clear();

	myPixels.width = 0;
	myPixels.height = 0;
	myPixels.bitsPerPixel = 0;
	myPixels.bytesPerPixel = 0;
	myPixels.glDataType = GL_LUMINANCE;
	myPixels.ofImageType = OF_IMAGE_UNDEFINED;
	myPixels.bAllocated = false;

	width = 0;
	height = 0;
	bpp = 0;
	type = OF_IMAGE_UNDEFINED;
	bUseTexture = true;     // the default is, yes, use a texture
}

//------------------------------------
unsigned char * ofImage::getPixels()
{
	return myPixels.pixels;
}

//------------------------------------
//for getting a reference to the texture
ofTexture & ofImage::getTextureReference()
{
	if (!tex.bAllocated())
	{
		ofLog(OF_LOG_WARNING, "ofImage - getTextureReference - texture is not allocated");
	}
	return tex;
}

//------------------------------------
void ofImage::setFromPixels(unsigned char * newPixels, int w, int h, int newType, bool bOrderIsRGB)
{
	if (!myPixels.bAllocated)
	{
		allocate(w, h, newType);
	}

	if (!((width == w) && (height == h) && (type == newType)))
	{
		bool bCacheBUseTexture = bUseTexture;
		clear();
		bUseTexture = bCacheBUseTexture;
		allocate(w, h, newType);
	}

	int newBpp = 0;
	switch (type)
	{
	case OF_IMAGE_GRAYSCALE:
		newBpp = 8;
		break;
	case OF_IMAGE_COLOR:
		newBpp = 24;
		break;
	case OF_IMAGE_COLOR_ALPHA:
		newBpp = 32;
		break;
	default:
		ofLog(OF_LOG_ERROR, "error = bad imageType in ofImage::setFromPixels");
		return;
	}

	allocatePixels(myPixels, w, h, newBpp);

	int bytesPerPixel = myPixels.bitsPerPixel / 8;
	memcpy(myPixels.pixels, newPixels, w * h * bytesPerPixel);

	if (myPixels.bytesPerPixel > 1)
	{
		if (!bOrderIsRGB)
		{
			swapRgb(myPixels);
		}
	}

	update();
}

//------------------------------------
void ofImage::update()
{
	if (myPixels.bAllocated == true && bUseTexture == true)
	{
		tex.loadData(myPixels.pixels, myPixels.width, myPixels.height, myPixels.glDataType);
	}

	width = myPixels.width;
	height = myPixels.height;
	bpp = myPixels.bitsPerPixel;
	type = myPixels.ofImageType;
}

//------------------------------------
void ofImage::setUseTexture(bool bUse)
{
	bUseTexture = bUse;
}


//------------------------------------
void ofImage::grabScreen(int _x, int _y, int _w, int _h)
{
	if (!myPixels.bAllocated)
	{
		allocate(_w, _h, OF_IMAGE_COLOR);
	}

	int screenHeight = ofGetHeight();
	_y = screenHeight - _y;
	_y -= _h; // top, bottom issues

	if (!((width == _w) && (height == _h)))
	{
		resize(_w, _h);
	}

	#ifndef TARGET_OF_IPHONE
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);                                                  // be nice to anyone else who might use pixelStore
	#endif
	glPixelStorei(GL_PACK_ALIGNMENT, 1);                                                            // set read non block aligned...
	glReadPixels(_x, _y, _w, _h, myPixels.glDataType, GL_UNSIGNED_BYTE, myPixels.pixels);           // read the memory....
	#ifndef TARGET_OF_IPHONE
	glPopClientAttrib();
	#endif

	int sizeOfOneLineOfPixels = myPixels.width * myPixels.bytesPerPixel;
	unsigned char * tempLineOfPix = new unsigned char[sizeOfOneLineOfPixels];
	unsigned char * linea;
	unsigned char * lineb;
	for (int i = 0; i < myPixels.height / 2; i++)
	{
		linea = myPixels.pixels + i * sizeOfOneLineOfPixels;
		lineb = myPixels.pixels + (myPixels.height - i - 1) * sizeOfOneLineOfPixels;
		memcpy(tempLineOfPix, linea, sizeOfOneLineOfPixels);
		memcpy(linea, lineb, sizeOfOneLineOfPixels);
		memcpy(lineb, tempLineOfPix, sizeOfOneLineOfPixels);
	}
	delete [] tempLineOfPix;
	update();
}


//------------------------------------
void ofImage::clone(const ofImage &mom)
{
	allocatePixels(myPixels, mom.width, mom.height, mom.bpp);
	memcpy(myPixels.pixels, mom.myPixels.pixels, myPixels.width * myPixels.height * myPixels.bytesPerPixel);

	tex.clear();
	bUseTexture = mom.bUseTexture;
	if (bUseTexture == true)
	{
		tex.allocate(myPixels.width, myPixels.height, myPixels.glDataType);
	}

	update();
}

//------------------------------------
void ofImage::setImageType(int newType)
{
	changeTypeOfPixels(myPixels, newType);
	update();
}

//------------------------------------
void ofImage::resize(int newWidth, int newHeight)
{
	resizePixels(myPixels, newWidth, newHeight);

	if (bUseTexture == true)
	{
		tex.clear();
		tex.allocate(myPixels.width, myPixels.height, myPixels.glDataType);
	}

	update();
}


//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
// freeImage based code & utilities:

//----------------------------------------------------
inline void ofImage::swapRgb(ofPixels &pix)
{
	if (pix.bitsPerPixel != 8)
	{
		int sizePixels = pix.width * pix.height;
		int cnt = 0;
		unsigned char temp;
		int byteCount = pix.bitsPerPixel / 8;

		while (cnt < sizePixels)
		{
			temp = pix.pixels[cnt * byteCount];
			pix.pixels[cnt * byteCount] = pix.pixels[cnt * byteCount + 2];
			pix.pixels[cnt * byteCount + 2] = temp;
			cnt++;
		}
	}
}


//----------------------------------------------------
inline void ofImage::allocatePixels(ofPixels &pix, int width, int height, int bpp)
{
	bool bNeedToAllocate = false;
	if (pix.bAllocated == true)
	{
		if ((pix.width == width) && (pix.height == height) && (pix.bitsPerPixel == bpp))
		{
			//ofLog(OF_LOG_NOTICE,"we are good, no reallocation needed");
			bNeedToAllocate = false;
		}
		else
		{
			delete[] pix.pixels;
			bNeedToAllocate = true;
		}
	}
	else
	{
		bNeedToAllocate = true;
	}

	int byteCount = bpp / 8;

	if (bNeedToAllocate == true)
	{
		pix.width = width;
		pix.height = height;
		pix.bitsPerPixel = bpp;
		pix.bytesPerPixel = bpp / 8;

		switch (pix.bitsPerPixel)
		{
		case 8:
			pix.glDataType = GL_LUMINANCE;
			pix.ofImageType = OF_IMAGE_GRAYSCALE;
			break;
		case 24:
			pix.glDataType = GL_RGB;
			pix.ofImageType = OF_IMAGE_COLOR;
			break;
		case 32:
			pix.glDataType = GL_RGBA;
			pix.ofImageType = OF_IMAGE_COLOR_ALPHA;
			break;
		}

		pix.pixels = new unsigned char[pix.width * pix.height * byteCount];
		pix.bAllocated = true;
	}
}

//----------------------------------------------------
void* ofImage::getBmpFromPixels(ofPixels &pix)
{
	int width = pix.width;
	int height = pix.height;
	int bytesPerPixel = pix.bytesPerPixel;

	CGColorSpaceRef colorSpace;
	CGImageAlphaInfo alphaInfo;
	CGDataProviderRef provider;
	CGImageRef result;

	if (bytesPerPixel == 1)
	{
		colorSpace = CGColorSpaceCreateDeviceGray();
		alphaInfo = kCGImageAlphaNone;

		provider = CGDataProviderCreateWithData(NULL, pix.pixels, width * height, NULL);

		result = CGImageCreate(width, height, 8, 8, width, colorSpace,
							   alphaInfo, provider, NULL, 0,
							   kCGRenderingIntentDefault);
	}
	else if (bytesPerPixel == 3)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		alphaInfo = kCGImageAlphaNoneSkipLast;

		uint8_t *bitmap = new unsigned char[width * height * 4];

		uint8_t *src = pix.pixels;
		uint8_t *dst = bitmap;

		for (int i = 0; i < width * height; i++)
		{
			dst [0] = src[0];
			dst [1] = src[1];
			dst [2] = src[2];
			dst [3] = 0;

			src += 3;
			dst += 4;
		}

		provider = CGDataProviderCreateWithData(NULL, bitmap, width * height * 4, NULL);

		result = CGImageCreate(width, height, 8, 32, width * 4, colorSpace,
							   alphaInfo, provider, NULL, 0,
							   kCGRenderingIntentDefault);

		delete [] bitmap;
	}
	else if (bytesPerPixel == 4)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		alphaInfo = kCGImageAlphaPremultipliedLast;

		provider = CGDataProviderCreateWithData(NULL, pix.pixels, width * height * 4, NULL);

		result = CGImageCreate(width, height, 8, 32, width * 4, colorSpace,
							   alphaInfo, provider, NULL, 0,
							   kCGRenderingIntentDefault);
	}

	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);

	UIImage *newImage = [UIImage imageWithCGImage:result];
	CGImageRelease(result);

	return newImage;
}

//----------------------------------------------------
void ofImage::putBmpIntoPixels(void *bmp, ofPixels &pix)
{
	CGImageRef img = ((UIImage*)bmp).CGImage;

	int width = CGImageGetWidth(img);
	int height = CGImageGetHeight(img);
	int bpp = CGImageGetBitsPerPixel(img);
	int bytesPerPixel = CGImageGetBitsPerPixel(img) / 8;

	allocatePixels(pix, width, height, bpp);
	uint8_t *tempBuffer = NULL;

	CGContextRef context;
	CGColorSpaceRef colorSpace;
	CGImageAlphaInfo alphaInfo;

	if (bytesPerPixel == 1)
	{
		colorSpace = CGColorSpaceCreateDeviceGray();
		alphaInfo = kCGImageAlphaNone;

		tempBuffer = new uint8_t[width * height];

		context = CGBitmapContextCreate(tempBuffer,
										width, height, 8, width,
										colorSpace, alphaInfo);

		CGContextDrawImage(context, CGRectMake(0, 0, width, height), img);

		uint8_t *src = tempBuffer;
		uint8_t *dst = pix.pixels;

		for (int i = 0; i < width * height; i++)
		{
			*src++ = *dst++;
		}
	}
	else if (bytesPerPixel == 3)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		alphaInfo = kCGImageAlphaNoneSkipLast;

		tempBuffer = new uint8_t[width * height * 4];

		context = CGBitmapContextCreate(tempBuffer,
										width, height, 8, width * 4,
										colorSpace, alphaInfo);

		CGContextDrawImage(context, CGRectMake(0, 0, width, height), img);

		uint8_t *src = tempBuffer;
		uint8_t *dst = pix.pixels;

		for (int i = 0; i < width * height; i++)
		{
			dst[0] = src[0];
			dst[1] = src[1];
			dst[2] = src[2];

			src += 4;
			dst += 3;
		}
	}
	else if (bytesPerPixel == 4)
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
		alphaInfo = kCGImageAlphaPremultipliedLast;

		tempBuffer = new uint8_t[width * height * 4];

		context = CGBitmapContextCreate(tempBuffer,
										width, height, 8, width * 4,
										colorSpace, alphaInfo);

		CGContextDrawImage(context, CGRectMake(0, 0, width, height), img);

		uint8_t *src = tempBuffer;
		uint8_t *dst = pix.pixels;

		for (int i = 0; i < width * height; i++)
		{
			dst[0] = src[0];
			dst[1] = src[1];
			dst[2] = src[2];
			dst[3] = src[3];

			src += 4;
			dst += 4;
		}
	}

	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);

	if (tempBuffer)
	{
		delete [] tempBuffer;
	}
}

//----------------------------------------------------
void ofImage::resizePixels(ofPixels &pix, int newWidth, int newHeight)
{
	UIImage *bmp = (UIImage*)getBmpFromPixels(pix);
	UIImage *convertedBmp = NULL;

	CGSize newSize = CGSizeMake(newWidth, newHeight);
	UIGraphicsBeginImageContext(newSize);
	[bmp drawInRect : CGRectMake(0, 0, newSize.width, newSize.height)];
	convertedBmp = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	putBmpIntoPixels(convertedBmp, pix);
}

//----------------------------------------------------
void ofImage::changeTypeOfPixels(ofPixels &pix, int newType)
{
	if (pix.ofImageType == newType) return;

	// check if we need to reallocate the texture.
	bool bNeedNewTexture = false;
	int oldType = pix.ofImageType;
	if (newType > oldType)
	{
		bNeedNewTexture = true;
	}

	CGColorSpaceRef colorSpace;
	CGImageAlphaInfo alphaInfo = kCGImageAlphaNone;

	// new type !
	switch (newType)
	{

	//------------------------------------
	case OF_IMAGE_GRAYSCALE:
		colorSpace = CGColorSpaceCreateDeviceGray();
		break;

	//------------------------------------
	case OF_IMAGE_COLOR:
		colorSpace = CGColorSpaceCreateDeviceRGB();
		break;

	//------------------------------------
	case OF_IMAGE_COLOR_ALPHA:
		colorSpace = CGColorSpaceCreateDeviceRGB();
		alphaInfo = kCGImageAlphaPremultipliedLast;
		break;
	}

	UIImage *bmp = (UIImage*)getBmpFromPixels(pix);
	UIImage *convertedBmp = NULL;

	CGContextRef context = CGBitmapContextCreate(nil, bmp.size.width, bmp.size.height, 8, 0,
												 colorSpace, alphaInfo);
	CGRect rect = CGRectMake(0.0, 0.0, bmp.size.width, bmp.size.height);
	CGColorSpaceRelease(colorSpace);
	CGContextDrawImage(context, rect, [bmp CGImage]);
	CGImageRef grayscale = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	convertedBmp = [UIImage imageWithCGImage:grayscale];
	CFRelease(grayscale);

	putBmpIntoPixels(convertedBmp, pix);

	CGColorSpaceRelease(colorSpace);

	switch (newType)
	{
	case OF_IMAGE_GRAYSCALE:
		break;
	case OF_IMAGE_COLOR:
		if (bNeedNewTexture)
		{
			tex.clear();
			tex.allocate(myPixels.width, myPixels.height, GL_RGB);
		}
		break;
	case OF_IMAGE_COLOR_ALPHA:
		if (bNeedNewTexture)
		{
			tex.clear();
			tex.allocate(myPixels.width, myPixels.height, GL_RGBA);
		}
		break;
	}
}

//----------------------------------------------------
bool ofImage::loadImageIntoPixels(string fileName, ofPixels &pix)
{
	fileName = ofToDataPath(fileName);

	NSString *path = [NSString stringWithUTF8String:fileName.c_str()];
	UIImage *bmp = [UIImage imageWithContentsOfFile:path];
	CGImageRef img = bmp.CGImage;

	int width = CGImageGetWidth(img);
	int height = CGImageGetHeight(img);
	int bpp = CGImageGetBitsPerPixel(img);

	allocatePixels(pix, width, height, bpp);
	putBmpIntoPixels(bmp, pix);

	return true;
}

//----------------------------------------------------------------
void ofImage::saveImageFromPixels(string fileName, ofPixels &pix)
{
	if (pix.bAllocated == false)
	{
		ofLog(OF_LOG_ERROR, "error saving image - pixels aren't allocated");
		return;
	}

	#ifdef TARGET_LITTLE_ENDIAN
	if (pix.bytesPerPixel != 1) swapRgb(pix);
	#endif

	UIImage *bmp = (UIImage*)getBmpFromPixels(pix);
	NSData *data = UIImagePNGRepresentation(bmp);

	NSString *path = [NSString stringWithUTF8String:fileName.c_str()];
	[data writeToFile : path atomically : YES];
}

//----------------------------------------------------------
float ofImage::getHeight()
{
	return height;
}

//----------------------------------------------------------
float ofImage::getWidth()
{
	return width;
}

//----------------------------------------------------------
// Sosolimited: texture compression
// call this function before you call loadImage()
void ofImage::setCompression(ofTexCompression compression)
{
	tex.setCompression(compression);
}
