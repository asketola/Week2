//
//  GalleryCell.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/12/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell {                  // This defines the proprties of the 'cell'/image - how you will see each image in the Photo Gallery
  
  let imageView = UIImageView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addSubview(self.imageView)
    self.backgroundColor = UIColor.whiteColor()
    imageView.frame = self.bounds
    
    // Required code for imageView
    imageView.contentMode = UIViewContentMode.ScaleAspectFill
    imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
    imageView.layer.masksToBounds = true
    
    let views = ["imageView" : imageView]
    
    // Constraints for the image in the imageView
    let imageViewConstraintsHorizontal = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: nil, metrics: nil, views: views)
    self.addConstraints(imageViewConstraintsHorizontal)
    let imageViewConstraintsVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: nil, metrics: nil, views: views)
    self.addConstraints(imageViewConstraintsVertical)
  }
  // Required code
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
