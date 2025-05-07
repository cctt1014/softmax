#include <cstdint> // For uint32_t
#include <vector>  // For std::vector
#include <cmath>   // For std::exp

// Function to convert a float to IEEE 754 single-precision format
uint32_t floatToIEEE754(float value) {
    // Use a union to interpret the float as a 32-bit integer
    union {
        float f;
        uint32_t u;
    } converter;

    converter.f = value; // Assign the float value
    return converter.u;  // Return the 32-bit representation
}

// Function to convert IEEE 754 Hex back to a decimal float
float IEEE754ToFloat(uint32_t hexValue) {
    union {
        float f;
        uint32_t u;
    } converter;

    converter.u = hexValue; // Assign the hex value
    return converter.f;     // Return the float representation
}

// Function to calculate the softmax output for a vector of floating-point numbers
std::vector<float> calculateSoftmax(const std::vector<float>& input) {
    std::vector<float> output(input.size());
    float sum = 0.0;

    // Compute the exponentials and their sum
    for (float value : input) {
        sum += std::exp(value);
    }

    // Compute the softmax output
    for (size_t i = 0; i < input.size(); ++i) {
        output[i] = std::exp(input[i]) / sum;
    }

    return output;
}



