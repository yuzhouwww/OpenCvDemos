//
//  ViewController.m
//  OpenCvDemos
//
//  Created by yuzhou on 13-7-23.
//  Copyright (c) 2013年 wzyk. All rights reserved.
//
using namespace std;
using namespace cv;

#import "ViewController.h"
#import <CoreGraphics/CoreGraphics.h>

@interface ViewController ()

@end

@implementation ViewController

//void detectWithFlann(Mat img0, int width0, int height0, Mat img, int width, int height);

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Mat img0 = [self cvMatFromUIImage:[UIImage imageNamed:@"f1.jpg"]];
    Mat img = [self cvMatFromUIImage:[UIImage imageNamed:@"f13.jpg"]];
    for (int i = 0; i < 20; i++) {
        detectWithFlann(img, 398, 589, img0, 500, 667);
    }
}

- (void)detect
{
    [super viewDidLoad];
    
    //灰度图
    UIImage *originImg = [UIImage imageNamed:@"rock.jpg"];
    NSLog(@"%@",originImg);
    Mat inputMat = [self cvMatFromUIImage:originImg];
    Mat outputMat;
    cvtColor(inputMat, outputMat, CV_BGR2GRAY);
    UIImage *outputImg = [self UIImageFromCVMat:outputMat];
    imageView.image = outputImg;
    
    //监测特征点
    Mat target = [self cvMatFromUIImage:originImg];//imread("rock.jpg",CV_LOAD_IMAGE_COLOR);
    
    Ptr<FeatureDetector> detector = FeatureDetector::create("ORB");
    Ptr<DescriptorExtractor> extractor = DescriptorExtractor::create("ORB");
    
    vector<KeyPoint> keypoints;
    
    Mat descriptors = Mat();
    
    NSDate *date = [NSDate date];
    
    detector->detect(target, keypoints);
    extractor->compute(target, keypoints, descriptors);
    
    NSLog(@"%f",[[NSDate date] timeIntervalSinceDate:date]);
    
    for (int i=0;i<keypoints.size();i++) {
        KeyPoint point = keypoints[i];
        circle(target, point.pt, 5, Scalar(0, 255, 0));
    }
    UIImage *finalImg = [self UIImageFromCVMat:target];
    imageView.image = finalImg;
}

void detectWithFlann(Mat img0, int width0, int height0, Mat img, int width, int height)
{
    NSDate *date = [NSDate date];
    
    Ptr<flann::IndexParams> indexParams = new flann::KDTreeIndexParams();
    Ptr<flann::SearchParams> searchParams = new flann::SearchParams();
    
    indexParams->setAlgorithm(cvflann::FLANN_INDEX_LSH);
    indexParams->setInt("table_number",6);
    indexParams->setInt("key_size",12);
    indexParams->setInt("multi_probe_level",1);
    searchParams->setAlgorithm(cvflann::FLANN_INDEX_LSH);
    
    FlannBasedMatcher matcher(indexParams, searchParams);
    OrbFeatureDetector detector(1000);
    OrbDescriptorExtractor extractor(1000);
    
    vector<KeyPoint> keyPoints0;
    Mat descriptor0;
    detector.detect(img0, keyPoints0, descriptor0);
    extractor.compute(img0, keyPoints0, descriptor0);
    vector<vector<DMatch> > matches;
    vector<Mat> descriptors;
    descriptors.push_back(descriptor0);
    matcher.add(descriptors);
    
    NSDate *date2 = [NSDate date];
    vector<KeyPoint> keyPoints;
    Mat descriptor;
    detector.detect(img, keyPoints, descriptor);
    extractor.compute(img, keyPoints, descriptor);
    matcher.knnMatch(descriptor, matches, 2);
    NSLog(@"%.0f ms",[[NSDate date] timeIntervalSinceDate:date2] * 1000);
//    int size = width * height;
//    int result[size];
//    memccpy(result, image, 0, size);  //    env->SetIntArrayRegion(result, 0, size, cbuf);
//    free(image);                      //    env->ReleaseIntArrayElements(image, cbuf, 0);
//    return result;//返回格式不对？？？
    
//    NSLog(@"%.0f ms",[[NSDate date] timeIntervalSinceDate:date] * 1000);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

- (Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    // Creating CGImage from Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (void)dealloc {
    [imageView release];
    [super dealloc];
}
@end
