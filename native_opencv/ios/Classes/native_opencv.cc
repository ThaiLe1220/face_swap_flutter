#include "image_processor.h"
#include "delaunay_triangulation.h"
#include "face_morph.h"
#include <vector>

extern "C"
{
	__attribute__((visibility("default"))) __attribute__((used))
	const char *
	version()
	{
		return CV_VERSION;
	}

	__attribute__((visibility("default"))) __attribute__((used)) const char *convertToGrayScale(const char *inputImagePath, const char *outputImagePath)
	{
		try
		{
			ImageProcessor::convertToGrayScale(inputImagePath, outputImagePath);
			return nullptr; // No error
		}
		catch (const std::exception &e)
		{
			return e.what(); // Return the error message
		}
	}

	__attribute__((visibility("default"))) __attribute__((used)) const char *makeDelaunay(int f_w, int f_h, const float *points, int points_size, int *result, int *result_size)
	{
		try
		{
			std::vector<cv::Point2f> cvPoints;
			for (int i = 0; i < points_size; i += 2)
			{
				cvPoints.emplace_back(points[i], points[i + 1]);
			}

			auto triangles = makeDelaunay(f_w, f_h, cvPoints);

			int index = 0;
			for (const auto &tri : triangles)
			{
				result[index++] = std::get<0>(tri);
				result[index++] = std::get<1>(tri);
				result[index++] = std::get<2>(tri);
			}
			*result_size = index;

			return nullptr; // No error
		}
		catch (const std::exception &e)
		{
			return e.what(); // Return the error message
		}
	}

	__attribute__((visibility("default"))) __attribute__((used)) const char *morphImages(const char *img1Path, const char *img2Path, const float *points1, const float *points2, const int *triangles, int numTriangles, float alpha, const char *outputPath)
	{
		try
		{
			cv::Mat img1 = cv::imread(img1Path);
			cv::Mat img2 = cv::imread(img2Path);
			if (img1.empty() || img2.empty())
			{
				throw std::runtime_error("Could not open or find the images");
			}

			std::vector<cv::Point2f> cvPoints1;
			std::vector<cv::Point2f> cvPoints2;
			for (int i = 0; i < numTriangles * 3; i += 2)
			{
				cvPoints1.emplace_back(points1[i], points1[i + 1]);
				cvPoints2.emplace_back(points2[i], points2[i + 1]);
			}

			std::vector<std::tuple<int, int, int>> triList;
			for (int i = 0; i < numTriangles; i += 3)
			{
				triList.emplace_back(triangles[i], triangles[i + 1], triangles[i + 2]);
			}

			cv::Mat morphedImg = morph_images(img1, img2, cvPoints1, cvPoints2, triList, alpha);

			cv::imwrite(outputPath, morphedImg);
			return nullptr; // No error
		}
		catch (const std::exception &e)
		{
			cv::Mat img1 = cv::imread(img1Path);
			cv::imwrite(outputPath, img1);
			return e.what(); // Return the error message
		}
	}
}
