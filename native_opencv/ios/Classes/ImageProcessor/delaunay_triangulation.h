#ifndef DELAUNAY_TRIANGULATION_H
#define DELAUNAY_TRIANGULATION_H

#include <iostream>
#include <vector>
#include <tuple>
#include <unordered_map>
#include <opencv2/opencv.hpp>
#include <functional> // For std::hash

// Define a custom hash function for cv::Point2f
struct Point2fHash
{
    std::size_t operator()(const cv::Point2f &p) const noexcept
    {
        std::size_t h1 = std::hash<float>{}(p.x);
        std::size_t h2 = std::hash<float>{}(p.y);
        return h1 ^ (h2 << 1); // Combine hashes
    }
};

// Check if a given point is inside the specified rectangle
bool rectContains(cv::Rect rect, cv::Point2f point);

// Compute Delaunay triangulation and return triangles as tuples of indices
std::vector<std::tuple<int, int, int>> drawDelaunay(int f_w, int f_h, cv::Subdiv2D &subdiv, std::unordered_map<cv::Point2f, int, Point2fHash> &dictionary);

// Initialize Delaunay triangulation process with a list of points
std::vector<std::tuple<int, int, int>> makeDelaunay(int f_w, int f_h, std::vector<cv::Point2f> &points);

#endif // DELAUNAY_TRIANGULATION_H

/*
Using a dictionary (`std::unordered_map`) with a custom `std::hash` function to improve the speed and reliability of geometric computations, crucial for handling complex datasets efficiently:
1. Efficient Access: The dictionary allows for fast lookups, insertions, and deletions, crucial for managing point indices dynamically.
2. Custom Hashing: A custom `std::hash` improves hash distribution and reduces collisions, ensuring faster and more consistent performance across operations.
3. Optimized Memory: This approach minimizes space complexity by using points as keys directly, avoiding separate data structures for points and their indices.
*/
