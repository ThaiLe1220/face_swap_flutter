#ifndef FACE_MORPH_H
#define FACE_MORPH_H

#include <vector>
#include <tuple>
#include <opencv2/opencv.hpp>

// Declaration for the function that applies affine transformation
cv::Mat apply_affine_transform(cv::Mat src, std::vector<cv::Point2f> &srcTri, std::vector<cv::Point2f> &dstTri, cv::Size size);

// Declaration for the function to warp a triangle in the image
void warp_tri(cv::Mat &img1, cv::Mat &img2, cv::Mat &morphed_img, std::vector<cv::Point2f> &t1, std::vector<cv::Point2f> &t2, float alpha);

// Declaration for the function to mask out non-black pixels
cv::Mat mask_out_non_black(cv::Mat &image);

// Declaration for the function to blend two images selectively using a mask and alpha blending
cv::Mat selective_alpha_blend(const cv::Mat &background, const cv::Mat &foreground, const cv::Mat &mask, float alpha);

// Declaration for the function that morphs two images based on a given alpha blending factor
cv::Mat morph_images(cv::Mat &img1, cv::Mat &img2, std::vector<cv::Point2f> &points1, std::vector<cv::Point2f> &points2, std::vector<std::tuple<int, int, int>> &tri_list, float alpha);

#endif // FACE_MORPH_H
