#include "image_processor.h"

void ImageProcessor::convertToGrayScale(const std::string &inputImagePath, const std::string &outputImagePath)
{
    cv::Mat inputImage = cv::imread(inputImagePath, cv::IMREAD_COLOR);
    if (inputImage.empty())
    {
        throw std::runtime_error("Could not open or find the image");
    }

    cv::Mat grayImage;
    cv::cvtColor(inputImage, grayImage, cv::COLOR_BGR2GRAY);

    cv::imwrite(outputImagePath, grayImage);
}
