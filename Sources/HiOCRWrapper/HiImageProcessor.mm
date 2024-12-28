//
//  HiImageProcessor.m
//  feat_ocr
//
//  Created by netcanis on 12/23/24.
//

#define NO cv_NO
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#undef NO
#import "HiImageProcessor.h"


@implementation HiImageProcessor

+ (UIImage *)processCardImage:(UIImage *)uiImage {
    cv::Mat originalMat;
    UIImageToMat(uiImage, originalMat);

    cv::Mat grayMat;
    cv::cvtColor(originalMat, grayMat, cv::COLOR_BGR2GRAY);

    cv::Mat blurredMat, diffMat;
    cv::GaussianBlur(grayMat, blurredMat, cv::Size(21, 21), 0);
    cv::subtract(grayMat, blurredMat, diffMat);

    cv::Mat claheMat;
    auto clahe = cv::createCLAHE(2.0, cv::Size(8, 8));
    clahe->apply(diffMat, claheMat);

    cv::Mat edgeMat;
    cv::Canny(claheMat, edgeMat, 50, 150);

    cv::Mat morphMat;
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));
    cv::morphologyEx(edgeMat, morphMat, cv::MORPH_CLOSE, kernel);

    cv::Mat thresholdMat;
    cv::adaptiveThreshold(morphMat, thresholdMat, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 15, -2);

    UIImage *processedUIImage = MatToUIImage(thresholdMat);
    return processedUIImage;
}

+ (UIImage *)processCardImageForEmbossedText:(UIImage *)uiImage {
    cv::Mat originalMat;
    UIImageToMat(uiImage, originalMat);

    if (originalMat.type() == CV_8UC4) {
        cv::cvtColor(originalMat, originalMat, cv::COLOR_RGBA2BGR);
    } else if (originalMat.type() == CV_8UC3) {
        cv::cvtColor(originalMat, originalMat, cv::COLOR_RGB2BGR);
    } else {
        NSLog(@"Error: Unsupported image format");
        return uiImage;
    }

    cv::Mat hsvMat;
    cv::cvtColor(originalMat, hsvMat, cv::COLOR_BGR2HSV);

    cv::Mat reshapedMat = hsvMat.reshape(1, hsvMat.rows * hsvMat.cols);
    reshapedMat.convertTo(reshapedMat, CV_32F);

    cv::Mat labels, centers;
    int K = 5; // Number of K-means clusters
    cv::kmeans(reshapedMat, K, labels, cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 10, 1.0), 3, cv::KMEANS_PP_CENTERS, centers);

    std::vector<int> counts(K, 0);
    for (int i = 0; i < labels.rows; ++i) {
        counts[labels.at<int>(i)]++;
    }
    int dominantColorIndex = std::distance(counts.begin(), std::max_element(counts.begin(), counts.end()));
    cv::Vec3f backgroundColorVec = centers.at<cv::Vec3f>(dominantColorIndex);

    cv::Scalar backgroundColor = cv::Scalar(backgroundColorVec[0], backgroundColorVec[1], backgroundColorVec[2]);

    cv::Mat grayMat;
    cv::cvtColor(originalMat, grayMat, cv::COLOR_BGR2GRAY);

    cv::Scalar lowerBound = backgroundColor - cv::Scalar(10, 40, 40);
    cv::Scalar upperBound = backgroundColor + cv::Scalar(10, 40, 40);

    cv::Mat mask;
    cv::inRange(hsvMat, lowerBound, upperBound, mask);

    cv::Mat processedMat = originalMat.clone();
    for (int y = 0; y < processedMat.rows; y++) {
        for (int x = 0; x < processedMat.cols; x++) {
            if (mask.at<uchar>(y, x) == 0) {
                uchar brightness = grayMat.at<uchar>(y, x);
                cv::Vec3b adjustedColor = cv::Vec3b(
                    static_cast<uchar>(backgroundColor[0] * (brightness / 255.0)),
                    static_cast<uchar>(backgroundColor[1] * (brightness / 255.0)),
                    static_cast<uchar>(backgroundColor[2] * (brightness / 255.0))
                );
                processedMat.at<cv::Vec3b>(y, x) = adjustedColor;
            }
        }
    }

    cv::Mat rgbMat;
    cv::cvtColor(processedMat, rgbMat, cv::COLOR_BGR2RGB);
    
    UIImage *processedImage = MatToUIImage(rgbMat);
    return processedImage;
}

@end
