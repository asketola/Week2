//
//  FilterImageClass.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/15/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit

class FilterImageClass {
  
  var newImage : UIImage?
  var orginalImage : UIImage?
  var filteredImage : UIImage?
  var filterName : String
  var imageQueue : NSOperationQueue   // <- this class regulates the execution of a set of images. After being added to a queue, an operation remains in that queue until it is explicitly canceled or finishes executing its task
  var gpuContext : CIContext   // <- GPU is where we process the photos (More efficient than using the CPU), The CIContext class provides an evaluation context for rendering a CIImage object through Quartz 2D or OpenGL
  
  init( originalImage : UIImage, filterName : String, operationQueue : NSOperationQueue, context : CIContext) {  //<- must initialize the variables, regulated by NSOp and using the CIIContext to process
    self.filterName = filterName
    self.imageQueue = operationQueue
    self.gpuContext = context
    self.orginalImage = originalImage
  }
  
  // filters the images and returns the image
  func generateFilteredImage() {
     println("func generateFilteredImage called in FilteredImageClass swift file")
    let startImage = CIImage(image: self.orginalImage)                                // <- turns the image into a CIImage
    let filter = CIFilter(name: self.filterName)
    filter.setDefaults()   // <- so things aren't empty
    filter.setValue(startImage, forKey: kCIInputImageKey)       // <- Sets the property of the receiver specified by a given key (kCUIInputImageKey) to a given value. kCUIInputImageKey is a key for the CIImage object to use as an input image
    let result = filter.valueForKey(kCIOutputImageKey) as CIImage                    // <- returns the filtered image as a CIImage file
    let extent = result.extent()   // <- returns a rectangle that specifies the extent of the image in working space coordinates.
    let imageRef = self.gpuContext.createCGImage(result, fromRect: extent)           // makes a CGImage image type
    // self.filteredImage = UIImage(CGImage: imageRef)                               // <- this one works, but the image is sometimes rotated incorrectly
    
    // convert the filtered image ref as a UIImage type
    self.filteredImage = UIImage(CGImage: imageRef, scale: self.orginalImage!.scale, orientation: self.orginalImage!.imageOrientation)
  }
}
