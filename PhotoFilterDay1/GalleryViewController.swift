//
//  GalleryViewController.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/12/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit

protocol ImageSelectedProtocol {  // <- this is what allows you to pass data between the *ViewControllers, things associated with this
  func controllerDidSelectImage(UIImage) -> Void
}

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  
  // Define the global variables
  var collectionView : UICollectionView!
  var images = [UIImage]()  // <- they array of images that will hold our 
  var delegate : ImageSelectedProtocol?  // placeholder of type defined
  var collectionViewFlowLayout : UICollectionViewFlowLayout!

  override func loadView() {
      let rootView = UIView(frame: UIScreen.mainScreen().bounds)
      self.collectionViewFlowLayout = UICollectionViewFlowLayout()
      self.collectionView = UICollectionView(frame: rootView.frame, collectionViewLayout: collectionViewFlowLayout)
      rootView.addSubview(self.collectionView)
      self.collectionView.dataSource = self
      self.collectionView.delegate = self
      collectionViewFlowLayout.itemSize = CGSize(width: 200, height: 200)
      
      self.view = rootView

    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.whiteColor()
    self.collectionView.registerClass(GalleryCell.self, forCellWithReuseIdentifier: "GALLERY_CELL")
    let image1 = UIImage(named: "IMG_3877.JPG")
    let image2 = UIImage(named: "IMG_3142.JPG")
    let image3 = UIImage(named: "IMG_3102.jpg")
    let image4 = UIImage(named: "IMG_3148.jpg")
    let image5 = UIImage(named: "IMG_3843.JPG")
    let image6 = UIImage(named: "IMG_3948.JPG")
    self.images.append(image1!)
    self.images.append(image2!)
    self.images.append(image3!)
    self.images.append(image4!)
    self.images.append(image5!)
    self.images.append(image6!)
    
    
    // Pinch gesture initiizers
    let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "collectionViewPinched")
    self.collectionView.addGestureRecognizer(pinchRecognizer)
  }
  
  // Gesture Recognizer Actions
  func collectionViewPinched(sender : UIPinchGestureRecognizer) {
    switch sender.state {
    case .Began:
      println("began pinching")
    case .Changed:
      println("changed pinching")
    case .Ended:
      println("ended pinch")
    default:
      println("defualt")
    }
    println("collection view pinched")
    
  }
  
  // UICollectionViewDataSource both functions required
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.images.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GALLERY_CELL", forIndexPath: indexPath) as GalleryCell
    let image = self.images[indexPath.row]
    cell.imageView.image = image
    return cell
  }

  // For UICollectionViewDelegate
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    self.delegate?.controllerDidSelectImage(self.images[indexPath.row])  // uses the protocol to pass the image and row its at over to the View Controller
    
    
    self.navigationController?.popViewControllerAnimated(true)
  }
  

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
