//
//  ViewController.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/12/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit
import Social

class ViewController: UIViewController, ImageSelectedProtocol, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  // Global variable defined
  let alertController = UIAlertController(title: "Title", message: "Message", preferredStyle: UIAlertControllerStyle.ActionSheet) // <- This is the pop-up alert message/window you get to select stuff from when you press Photos
  let mainImageView = UIImageView()  // the big picture on the 1st page
  var collectionView : UICollectionView!  //???
  var collectionViewYConstraint : NSLayoutConstraint!   // <- why is this constraint important enough to be a golobal variable?
  var originalThumbnail : UIImage!
  var filterNames = [String]()   // <- these names come from apple
  let imageQueue = NSOperationQueue()  // this is what lets you put things to work in a background thread
  var gpuContext : CIContext!  // this placeholder var lets you use the gpu to process stuff
  var thumbnails = [Thumbnail]()   // <- array that will hold all our filtered thumbnails after we altered them with the filter
  
  var doneButton : UIBarButtonItem!
  var shareButton : UIBarButtonItem!
  
  override func loadView() {
    let rootView = UIView(frame: UIScreen.mainScreen().bounds)   // defines the rootView variable as the full screen of the phone

    rootView.addSubview(self.mainImageView)  // adds the mainImageView to the rootView, must alawys do
    self.mainImageView.setTranslatesAutoresizingMaskIntoConstraints(false)  // always need to release auto-constraints when coding without storyboard
    self.mainImageView.backgroundColor = UIColor.redColor()   // placeholder background color so you can see where the main pic will go
    rootView.backgroundColor = UIColor.whiteColor()  // background of the rootView
    self.mainImageView.contentMode = UIViewContentMode.ScaleAspectFill  /// <- fixes mainImageView proprty to scaletofill all images that are passed to it
   
    println("loadview")
    // Defining the button "Photos" on the 1st page
    let photoButton = UIButton()   /// defines what photoButton is (its a button!)
    photoButton.setTranslatesAutoresizingMaskIntoConstraints(false) // release auto-constraints, must awlays do
    rootView.addSubview(photoButton)   // add to rootView, must do
    photoButton.setTitle("Photos", forState: .Normal)
    photoButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
    //  photoButton.backgroundColor = UIColor.brownColor()  // <- set background if you want to see the button
    photoButton.addTarget(self, action: "photoButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)  // give the button its action ability
    
    // for the collectionView functions
    let collectionviewFlowLayout = UICollectionViewFlowLayout()
    self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: collectionviewFlowLayout)
    collectionviewFlowLayout.itemSize = CGSize(width: 100, height: 100)
    collectionviewFlowLayout.scrollDirection = .Horizontal
    rootView.addSubview(collectionView)
    collectionView.setTranslatesAutoresizingMaskIntoConstraints(false)
    collectionView.dataSource = self
    collectionView.registerClass(GalleryCell.self, forCellWithReuseIdentifier: "FILTER_CELL")
    
    
    // Make a Dictionary called 'views'. It holds all your page's elements ex - "name of stuff" : variable
    let views = ["photoButton" : photoButton, "mainImageView" : self.mainImageView, "collectionView" : collectionView]
    
    self.setupContraintsOnRootView(rootView, forViews: views)
    
    // last call of the function
    self.view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // for new buttons
    self.doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
    self.shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "sharePressed")
    self.navigationItem.rightBarButtonItem = self.shareButton
    
    //For the galleryVC
    let galleryOption = UIAlertAction(title: "Gallery", style: UIAlertActionStyle.Default) { (action) -> Void in
      println("gallery pressed")
      let galleryVC = GalleryViewController()  // defines galleryVC
      galleryVC.delegate = self  // <- makes itself the delegate, this is what makes it conform to the protocol/requirement
      self.navigationController?.pushViewController(galleryVC, animated: true)
    }
    self.alertController.addAction(galleryOption)
    
    let filterOption = UIAlertAction(title: "Filter", style: UIAlertActionStyle.Default) { (action) -> Void in
      self.collectionViewYConstraint.constant = 20
      UIView.animateWithDuration(0.4, animations: { () -> Void in
        self.view.setNeedsLayout()
  })
      // set up the done Button in the alertController
      let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
      self.navigationItem.rightBarButtonItem = doneButton
      
      // put in info to pass filteredimage back to 1st page rootView
      
    }
    self.alertController.addAction(filterOption)
    
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
      let cameraOption = UIAlertAction(title: "Camera", style: .Default, handler: { (action) -> Void in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
      })
      self.alertController.addAction(cameraOption)
    }
    
    let photoOption = UIAlertAction(title: "Photos", style: .Default) { (action) -> Void in
      let photosVC = PhotosViewController()
      photosVC.destinationImageSize = self.mainImageView.frame.size
      photosVC.delegate = self
      self.navigationController?.pushViewController(photosVC, animated: true)
    }
    self.alertController.addAction(photoOption)
    
    // sets up the gpu processing - standard code, write exactly
    let options = [kCIContextWorkingColorSpace : NSNull()] // helps keep things fast
    let eagleContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    self.gpuContext = CIContext(EAGLContext: eagleContext, options: options)
    self.setupThumbnails()
  }
  
  
  
    func setupThumbnails() {
      self.filterNames = ["CISepiaTone","CIPhotoEffectChrome", "CIPhotoEffectNoir"]  // these names come from apple, and must be precicely spelled
      for name in self.filterNames {  // loops through the names in the filter arrray to make an example thumbnail of each filter
        let thumbnail = Thumbnail(filterName: name, operationQueue: self.imageQueue, context: self.gpuContext)
        self.thumbnails.append(thumbnail)  // adds the filter thumbnail to the array
      }
    }
  
  
    
    // Required for the ImageSelectedDelegate protocol, for you to select an image
    func controllerDidSelectImage(image: UIImage) {
      println("image selected deleagte call")
      self.mainImageView.image = image
      self.generateThumbnail(image)
      
      for thumbnail in self.thumbnails {
        thumbnail.orginalImage = self.originalThumbnail  // you always keep the original thumbnail and original picture
        thumbnail.filteredImage = nil
      }
      self.collectionView.reloadData()
    }
  
  // For UIImagePickerController
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    let image = info[UIImagePickerControllerEditedImage] as? UIImage
    self.controllerDidSelectImage(image!)
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // For the Button Selectors, lets you click the button and then the alertController pops up, in a nice animated way
  func photoButtonPressed(sender : UIButton) {
    self.presentViewController(self.alertController, animated: true, completion: nil)
  }
  
  
  // fastest/easiset way to make thumbnails in swift
    func generateThumbnail(originalImage: UIImage) {
      let size = CGSize(width: 100, height: 100)   // <- defines the size we want
      UIGraphicsBeginImageContext(size)   // does the resizing
      originalImage.drawInRect(CGRect(x: 0, y: 0, width: 100, height: 100))   // <- Draws the entire image in the specified rectangle, scaling it as needed to fit
      self.originalThumbnail = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()  // <- releases memory, stops data leaks
    }
  
  // For AlertController done button
  func donePressed() {
  self.collectionViewYConstraint.constant = -120
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
    self.navigationItem.rightBarButtonItem = self.shareButton
  }
  
  // For sharing your image with Twitter
  func sharePressed() {
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
    let compViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    compViewController.addImage(self.mainImageView.image)
    self.presentViewController( compViewController, animated: true, completion: nil)
    } else {
      
    }
    
  }
  
  
  
    // For UICollectioViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section : Int) -> Int {
      return self.thumbnails.count
    }
  
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FILTER_CELL", forIndexPath: indexPath) as GalleryCell
      let thumbnail = self.thumbnails[indexPath.row]
      if thumbnail.orginalImage != nil {  // <- only run if the thumbnail is chosen
        if thumbnail.filteredImage == nil {   // <- only run if a photo exists
          thumbnail.generateFilteredImage()   // actually does the filtering work
          cell.imageView.image = thumbnail.filteredImage!   // <- gives the thumbnail to the cell
        }
      }
      return cell
    }
  
  // For AutoLayout Constraints for the buttons and the pictures
  func setupContraintsOnRootView(rootView : UIView, forViews views : [String : AnyObject]) {
    
    // for the photo button. Formula: make a constraint(s) with a 'let,' then add it to the 'rootView'. Uses the names set in the Dictionary: 'views'
    let photoButtonConstraintVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:[photoButton]-20-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(photoButtonConstraintVertical)
    let photoButton = views["photoButton"] as UIView!
    let photoButtonConstraintHorizontal = NSLayoutConstraint(item: photoButton, attribute: .CenterX, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
    rootView.addConstraint(photoButtonConstraintHorizontal)
    photoButton.setContentHuggingPriority(750, forAxis: UILayoutConstraintAxis.Vertical)  // this fixes ???
    
    // for the mainImageView
    let mainImageViewConstraintsHorizontal = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[mainImageView]-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(mainImageViewConstraintsHorizontal)
    let mainImageViewConstraintVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:|-72-[mainImageView]-30-[photoButton]", options: nil, metrics: nil, views: views)
    rootView.addConstraints(mainImageViewConstraintVertical)
    
    // for the collectionView
    let collectionViewConstraintsHorizontal = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(collectionViewConstraintsHorizontal)
    let collectionViewConstraintHeight = NSLayoutConstraint.constraintsWithVisualFormat("V:[collectionView(100)]", options: nil, metrics: nil, views: views)
    self.collectionView.addConstraints(collectionViewConstraintHeight)
    let collectionViewConstraintVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:[collectionView]-(-120)-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(collectionViewConstraintVertical)
    self.collectionViewYConstraint = collectionViewConstraintVertical.first as NSLayoutConstraint  // sets the global variable collectionViewYConstraint, so we can use it in other places in the code
  }
}
