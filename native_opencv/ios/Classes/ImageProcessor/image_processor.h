#ifndef IMAGE_PROCESSOR_H
#define IMAGE_PROCESSOR_H

#include <opencv2/opencv.hpp>

class ImageProcessor
{
public:
    static void convertToGrayScale(const std::string &inputImagePath, const std::string &outputImagePath);
};

#endif // IMAGE_PROCESSOR_H
