#include "image_processor.h"
#include "delaunay_triangulation.h"
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
}
