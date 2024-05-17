#include "delaunay_triangulation.h"

// Function to check if a point is within a rectangle
bool rectContains(cv::Rect rect, cv::Point2f point)
{
    return (point.x > rect.x && point.x < rect.x + rect.width &&
            point.y > rect.y && point.y < rect.y + rect.height);
}

// Function to draw Delaunay triangles from subdivision and map them to vertex indices
std::vector<std::tuple<int, int, int>> drawDelaunay(int f_w, int f_h, cv::Subdiv2D &subdiv, std::unordered_map<cv::Point2f, int, Point2fHash> &dictionary)
{
    std::vector<std::tuple<int, int, int>> list4;
    std::vector<cv::Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    cv::Rect r(0, 0, f_w, f_h);

    for (size_t i = 0; i < triangleList.size(); i++)
    {
        cv::Vec6f t = triangleList[i];
        cv::Point2f pt1(t[0], t[1]);
        cv::Point2f pt2(t[2], t[3]);
        cv::Point2f pt3(t[4], t[5]);

        // Only add triangles completely within the bounds
        if (rectContains(r, pt1) && rectContains(r, pt2) && rectContains(r, pt3))
        {
            list4.emplace_back(dictionary[pt1], dictionary[pt2], dictionary[pt3]);
        }
    }

    return list4;
}

// Function to set up Delaunay triangulation for a given list of points
std::vector<std::tuple<int, int, int>> makeDelaunay(int f_w, int f_h, std::vector<cv::Point2f> &points)
{
    cv::Rect rect(0, 0, f_w, f_h);
    cv::Subdiv2D subdiv(rect);
    std::unordered_map<cv::Point2f, int, Point2fHash> dictionary;

    // Insert points into subdiv and map them by index
    for (int i = 0; i < points.size(); ++i)
    {
        subdiv.insert(points[i]);
        dictionary[points[i]] = i;
    }

    return drawDelaunay(f_w, f_h, subdiv, dictionary);
}
