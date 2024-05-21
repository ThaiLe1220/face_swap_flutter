#include "face_morph.h"

// Function to apply affine transformation to a source image
cv::Mat apply_affine_transform(cv::Mat src, std::vector<cv::Point2f> &srcTri, std::vector<cv::Point2f> &dstTri, cv::Size size)
{
    // Calculate the affine transform matrix
    cv::Mat warpMat = cv::getAffineTransform(srcTri, dstTri);
    cv::Mat dst;
    // Apply the affine transform
    cv::warpAffine(src, dst, warpMat, size, cv::INTER_LINEAR, cv::BORDER_REFLECT_101);
    return dst;
}

// Function to warp a triangle in the image
void warp_tri(cv::Mat &img1, cv::Mat &img2, cv::Mat &morphed_img, std::vector<cv::Point2f> &t1, std::vector<cv::Point2f> &t2, float alpha)
{
    // Calculate bounding rectangles for each triangle
    cv::Rect r1 = cv::boundingRect(t1);
    cv::Rect r2 = cv::boundingRect(t2);

    std::vector<cv::Point2f> t1Rect, t2Rect;
    // Adjust triangle coordinates to the bounding rectangle
    for (int i = 0; i < 3; i++)
    {
        t1Rect.push_back(cv::Point2f(t1[i].x - r1.x, t1[i].y - r1.y));
        t2Rect.push_back(cv::Point2f(t2[i].x - r2.x, t2[i].y - r2.y));
    }

    // Crop the image patches corresponding to the triangles
    cv::Mat img1Rect = img1(r1);
    cv::Mat img2Rect = img2(r2);

    // Warp the image patches to the destination triangle
    cv::Mat warpImage1 = apply_affine_transform(img1Rect, t1Rect, t1Rect, r1.size());
    cv::Mat warpImage2 = apply_affine_transform(img2Rect, t2Rect, t1Rect, r1.size());

    // Blend the warped images using alpha
    cv::Mat imgRect = (1.0 - alpha) * warpImage1 + alpha * warpImage2;
    cv::Mat mask = cv::Mat::zeros(r1.height, r1.width, CV_8UC1);

    // Create a mask for the triangle
    std::vector<cv::Point> tRectInt;
    for (auto &pt : t1Rect)
    {
        tRectInt.push_back(cv::Point(static_cast<int>(pt.x), static_cast<int>(pt.y)));
    }

    cv::fillConvexPoly(mask, tRectInt, cv::Scalar(255), 16, 0);

    // Place the blended image patch back into the output image
    cv::Mat imgROI = morphed_img(r1);
    imgRect.copyTo(imgROI, mask);
}

// Function to create a binary mask for non-black pixels in the image
cv::Mat mask_out_non_black(cv::Mat &image)
{
    // Convert the image to grayscale
    cv::Mat grayscale_image;
    cv::cvtColor(image, grayscale_image, cv::COLOR_BGR2GRAY);

    // Threshold the grayscale image to create a binary mask
    cv::Mat binary_mask;
    cv::threshold(grayscale_image, binary_mask, 1, 255, cv::THRESH_BINARY);

    return binary_mask;
}

// Function to blend two images selectively using a mask and alpha blending
cv::Mat selective_alpha_blend(const cv::Mat &background, const cv::Mat &foreground, const cv::Mat &mask, float alpha)
{
    // Create a copy of the background image
    cv::Mat blended_image = background.clone();

    for (int y = 0; y < mask.rows; ++y)
    {
        for (int x = 0; x < mask.cols; ++x)
        {
            if (mask.at<uchar>(y, x) != 0)
            {
                for (int c = 0; c < background.channels(); ++c)
                {
                    blended_image.at<cv::Vec3b>(y, x)[c] =
                        alpha * background.at<cv::Vec3b>(y, x)[c] +
                        (1 - alpha) * foreground.at<cv::Vec3b>(y, x)[c];
                }
            }
        }
    }

    return blended_image;
}

// Function to morph two images using specified correspondences and triangles
cv::Mat morph_images(cv::Mat &img1, cv::Mat &img2, std::vector<cv::Point2f> &points1, std::vector<cv::Point2f> &points2, std::vector<std::tuple<int, int, int>> &tri_list, float alpha)
{
    // Create a new image to hold the morphed result
    cv::Mat morphed_img = cv::Mat::zeros(img1.size(), img1.type());

    // Morph each triangle in the list
    for (auto &triangle : tri_list)
    {
        std::vector<cv::Point2f> t1 = {points1[std::get<0>(triangle)], points1[std::get<1>(triangle)], points1[std::get<2>(triangle)]};
        std::vector<cv::Point2f> t2 = {points2[std::get<0>(triangle)], points2[std::get<1>(triangle)], points2[std::get<2>(triangle)]};

        warp_tri(img1, img2, morphed_img, t1, t2, 1);
    }

    std::vector<cv::Point> points;
    std::vector<int> mouth_list_ids_dlib = {99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116};
    for (int idx : mouth_list_ids_dlib)
    {
        points.push_back(cv::Point(points1[idx].x, points1[idx].y));
    }

    // Create a mask to identify non-black pixels
    cv::Mat non_black_mask;
    cv::cvtColor(morphed_img, non_black_mask, cv::COLOR_BGR2GRAY);
    cv::threshold(non_black_mask, non_black_mask, 1, 255, cv::THRESH_BINARY);
    cv::Rect bounding_box = cv::boundingRect(non_black_mask);
    int x = bounding_box.x;
    int y = bounding_box.y;
    int w = bounding_box.width;
    int h = bounding_box.height;

    cv::Point center_face((x + x + w) / 2, (y + y + h) / 2);

    cv::Mat mask = mask_out_non_black(morphed_img);
    cv::bitwise_not(mask, mask);
    cv::fillPoly(mask, points, cv::Scalar(255, 255, 255));
    cv::Mat img1_no_face;
    cv::Mat mouth_mask = cv::Mat::zeros(img1.size(), CV_8UC1);
    cv::fillPoly(mouth_mask, points, cv::Scalar(255, 255, 255));
    cv::Mat result_mix;
    cv::Mat result_nor;
    cv::bitwise_and(img1, img1, img1_no_face, mask);
    cv::bitwise_not(mask, mask);

    cv::seamlessClone(morphed_img, img1, mask, center_face, result_nor, cv::NORMAL_CLONE);
    cv::seamlessClone(morphed_img, img1, mask, center_face, result_mix, cv::MIXED_CLONE);

    cv::Mat result = selective_alpha_blend(result_nor, result_mix, mask, alpha);
    result = selective_alpha_blend(result, img1, mouth_mask, 0.5);
    // cv::Mat result;
    // cv::add(morphed_img, img1_no_face, result);
    return result;
}
