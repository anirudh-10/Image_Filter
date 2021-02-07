# Image_Filter

Refer to Description for Design Overview

#### Specification

Design an image filter in VHDL that uses a 3x3 sliding window for QQVGA size images (look up Wikipedia page on “Graphic Display Resolutions” for meaning of QQVGA), with 8-bit pixel resolution.

Use a Read-Write Memory module (RWM, more popularly known as RAM or RandomAccess Memory) to store the original image as well as the filtered image and a Read Only
Memory module (ROM) to store the filter coefficients. The coefficient memory should hold two sets of coefficients - one for a smoothening filter and one for a sharpening filter.

Do not bother about how the memory modules are initialized with original image and filter coefficients.
An external switch indicates whether the image is to be smoothened or sharpened. A pushbutton is used to start the filtering operation. After constructing the filtered image, the system waits for next pressing of the push-button. 
