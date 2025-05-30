#include "ofxCvHaarFinder.h"


//--------------------------------------------------------------------------------
static bool sort_carea_compare( const ofxCvBlob & a, const ofxCvBlob & b) {
	// use opencv to calc size, then sort based on size
	float areaa = fabs(a.area);
	float areab = fabs(b.area);

    //return 0;
	return (areaa > areab);
}

ofxCvHaarFinder::ofxCvHaarFinder() {
#ifdef USE_OLD_CV
	cascade = NULL;
#endif
	scaleHaar = 1.08;
	neighbors = 2;
	img.setUseTexture(false);
}

ofxCvHaarFinder::ofxCvHaarFinder(const ofxCvHaarFinder& finder) {
#ifdef USE_OLD_CV
	cascade = NULL;
#endif
	scaleHaar = finder.scaleHaar;
	neighbors = finder.neighbors;
	img.setUseTexture(false);
	setup(finder.haarFile);
}

ofxCvHaarFinder::~ofxCvHaarFinder() {
#ifdef USE_OLD_CV
	if(cascade != NULL)
		cvReleaseHaarClassifierCascade(&cascade);
#endif
}

// low values	- more accurate - eg: 1.01
// high values	- faster - eg: 1.06 or 1.09
void ofxCvHaarFinder::setScaleHaar(float scaleHaar) {
	this->scaleHaar = scaleHaar;
}

//low values	= more false postives
//high values	= less faces,  but more reliable
void ofxCvHaarFinder::setNeighbors(unsigned neighbors) {
	this->neighbors = neighbors;
}

void ofxCvHaarFinder::setup(const of::filesystem::path & fileName) {
	haarFile = ofToDataPath(fileName);
#ifdef USE_OLD_CV
	if(cascade != NULL)
		cvReleaseHaarClassifierCascade(&cascade);
	cascade = (CvHaarClassifierCascade*) cvLoad(haarFile.c_str(), 0, 0, 0);

	#ifdef HAAR_HACK
		// http://thread.gmane.org/gmane.comp.lib.opencv/16540/focus=17400
		// http://www.openframeworks.cc/forum/viewtopic.php?f=10&t=1853&hilit=haar
		ofxCvGrayscaleImage hack;
		hack.setUseTexture(false);
		hack.allocate(8, 8);
		CvMemStorage* storage = cvCreateMemStorage();
		cvHaarDetectObjects(hack.getCvImage(), cascade, storage, scaleHaar, 2, CV_HAAR_DO_CANNY_PRUNING);
		cvReleaseMemStorage(&storage);
	#endif

	if (!cascade)
        ofLogError("ofxCvHaarFinder") << "setup(): couldn't load Haar cascade file: " << haarFile;
#else
	cascade.load( ofPathToString(haarFile) );
	if( cascade.empty() )
		ofLogError("ofxCvHaarFinder") << "setup(): couldn't load Haar cascade file: " << haarFile ;
#endif //USE_OLD_CV
}


float ofxCvHaarFinder::getWidth() {
	return img.width;
}

float ofxCvHaarFinder::getHeight() {
	return img.height;
}

int ofxCvHaarFinder::findHaarObjects(ofImage& input, int minWidth, int minHeight) {

	ofxCvGrayscaleImage gray;
	gray.setUseTexture(false);
	gray.allocate(input.getWidth(), input.getHeight());

	if( input.getImageType() == OF_IMAGE_COLOR ){
		ofxCvColorImage color;
		color.setUseTexture(false);
		color.allocate(input.getWidth(), input.getHeight());
		color = input.getPixels();
		gray = color;
	}else if( input.getImageType() == OF_IMAGE_GRAYSCALE ){
		gray = input.getPixels();
	}else{
		ofLogError("ofxCvHaarFinder") << "findHaarObjects(): OF_IMAGE_RGBA image type not supported";
		return 0;
	}

	return findHaarObjects(gray, minWidth, minHeight);

}

int ofxCvHaarFinder::findHaarObjects(ofPixels& input, int minWidth, int minHeight){
	ofxCvGrayscaleImage gray;
	gray.setUseTexture(false);
	gray.allocate(input.getWidth(), input.getHeight());

	if( input.getImageType() == OF_IMAGE_COLOR ){
		ofxCvColorImage color;
		color.setUseTexture(false);
		color.allocate(input.getWidth(), input.getHeight());
		color.setFromPixels(input);
		gray = color;
	}else if( input.getImageType() == OF_IMAGE_GRAYSCALE ){
		gray.setFromPixels(input);
	}else{
		ofLogError("ofxCvHaarFinder") << "findHaarObjects(): OF_IMAGE_RGBA image type not supported";
		return 0;
	}

	return findHaarObjects(gray, minWidth, minHeight);
}

int ofxCvHaarFinder::findHaarObjects(const ofxCvGrayscaleImage&  input,
	int minWidth, int minHeight) {
	return findHaarObjects(
		input, 0, 0, input.width, input.height,
		minWidth, minHeight);
}

int ofxCvHaarFinder::findHaarObjects(const ofxCvGrayscaleImage&  input,
	ofRectangle& roi,
	int minWidth, int minHeight) {
	return findHaarObjects(
		input, (int) roi.x, (int) roi.y, (int) roi.width, (int) roi.height,
		minWidth, minHeight);
}


void ofxCvHaarFinder::draw( float x, float y ) {
	ofPushStyle();
	ofEnableAlphaBlending();
	ofSetColor( 255,0,200,100 );
	ofPushMatrix();

	ofTranslate( x, y, 0.0 );

	ofNoFill();
	for(unsigned int i=0; i<blobs.size(); i++ ) {
		ofDrawRectangle(blobs[i].boundingRect.x, blobs[i].boundingRect.y,
                        blobs[i].boundingRect.width, blobs[i].boundingRect.height );
	}

	ofPopMatrix();
	ofPopStyle();
}


int ofxCvHaarFinder::findHaarObjects(const ofxCvGrayscaleImage& input,
	int x, int y, int w, int h,
	int minWidth, int minHeight) {

	int nHaarResults = 0;

#ifdef USE_OLD_CV
	if (cascade) {
		if (!blobs.empty())
			blobs.clear();

		// we make a copy of the input image here
		// because we need to equalize it.

		if (img.width == input.width && img.height == input.height) {
                img.resetROI();
				img = input;
		} else {
				img.clear();
				img.allocate(input.width, input.height);
				img = input;
		}

		img.setROI(x, y, w, h);
		cvEqualizeHist(img.getCvImage(), img.getCvImage());
		CvMemStorage* storage = cvCreateMemStorage();

		/*
		Alternative modes:

		CV_HAAR_DO_CANNY_PRUNING
		Regions without edges are ignored.

		CV_HAAR_SCALE_IMAGE
		Scale the image rather than the detector
		(sometimes yields speed increases).

		CV_HAAR_FIND_BIGGEST_OBJECT
		Only return the largest result.

		CV_HAAR_DO_ROUGH_SEARCH
		When BIGGEST_OBJECT is enabled, stop at
		the first scale for which multiple results
		are found.
		*/

		CvSeq* haarResults = cvHaarDetectObjects(
				img.getCvImage(), cascade, storage, scaleHaar, neighbors, CV_HAAR_DO_CANNY_PRUNING,
				cvSize(minWidth, minHeight));

		nHaarResults = haarResults->total;

		for (int i = 0; i < nHaarResults; i++ ) {
			//ofLogNotice("ofxCvHaarFinder") << "findHaarObjects(): " << i << " objects";

			ofxCvBlob blob;

			CvRect* r = (CvRect*) cvGetSeqElem(haarResults, i);

			float area = r->width * r->height;
			float length = (r->width * 2) + (r->height * 2);
			float centerx	= (r->x) + (r->width / 2.0);
			float centery	= (r->y) + (r->height / 2.0);

			blob.area = fabs(area);
			blob.hole = area < 0 ? true : false;
			blob.length	= length;
			blob.boundingRect.x = r->x + x;
			blob.boundingRect.y = r->y + y;
			blob.boundingRect.width = r->width;
			blob.boundingRect.height = r->height;
			blob.centroid.x = centerx;
			blob.centroid.y = centery;
			blob.pts.push_back(ofPoint(r->x, r->y));
			blob.pts.push_back(ofPoint(r->x + r->width, r->y));
			blob.pts.push_back(ofPoint(r->x + r->width, r->y + r->height));
			blob.pts.push_back(ofPoint(r->x, r->y + r->height));

			blobs.push_back(blob);
		}

		// sort the pointers based on size
		if( blobs.size() > 1 ) {
			sort( blobs.begin(), blobs.end(), sort_carea_compare );
		}

		cvReleaseMemStorage(&storage);
	}

#else
    if (!blobs.empty()){
        blobs.clear();
    }
    
	if( cascade.empty() )
		return 0;
	
	// we make a copy of the input image here
	// because we need to equalize it.

	if (img.width == input.width && img.height == input.height) {
			img.resetROI();
			img = input;
	} else {
			img.clear();
			img.allocate(input.width, input.height);
			img = input;
	}

	img.setROI(x, y, w, h);
	cvEqualizeHist(img.getCvImage(), img.getCvImage());
	
	/*
	Alternative modes:

	cv::CASCADE_DO_CANNY_PRUNING
	Regions without edges are ignored.

	cv::CASCADE_SCALE_IMAGE
	Scale the image rather than the detector
	(sometimes yields speed increases).

	cv::CASCADE_FIND_BIGGEST_OBJECT
	Only return the largest result.

	cv::CASCADE_DO_ROUGH_SEARCH
	When BIGGEST_OBJECT is enabled, stop at
	the first scale for which multiple results
	are found.
	*/

	std::vector<cv::Rect> haarResults;
	cascade.detectMultiScale(cv::cvarrToMat(img.getCvImage()), haarResults, scaleHaar, neighbors, cv::CASCADE_DO_CANNY_PRUNING, 
		cv::Size(minWidth, minHeight) );
	
	nHaarResults = haarResults.size();

		for (int i = 0; i < nHaarResults; i++ ) {
			//ofLogNotice("ofxCvHaarFinder") << "findHaarObjects(): " << i << " objects";

			ofxCvBlob blob;

			cv::Rect r = haarResults[i];

			float area = r.width * r.height;
			float length = (r.width * 2) + (r.height * 2);
			float centerx	= (r.x) + (r.width / 2.0);
			float centery	= (r.y) + (r.height / 2.0);

			blob.area = fabs(area);
			blob.hole = area < 0 ? true : false;
			blob.length	= length;
			blob.boundingRect.x = r.x + x;
			blob.boundingRect.y = r.y + y;
			blob.boundingRect.width = r.width;
			blob.boundingRect.height = r.height;
			blob.centroid.x = centerx;
			blob.centroid.y = centery;
			blob.pts.push_back(ofPoint(r.x, r.y));
			blob.pts.push_back(ofPoint(r.x + r.width, r.y));
			blob.pts.push_back(ofPoint(r.x + r.width, r.y + r.height));
			blob.pts.push_back(ofPoint(r.x, r.y + r.height));

			blobs.push_back(blob);
		}

		// sort the pointers based on size
		if( blobs.size() > 1 ) {
			sort( blobs.begin(), blobs.end(), sort_carea_compare );
		}
#endif // USE_OLD_CV
	return nHaarResults;
}
