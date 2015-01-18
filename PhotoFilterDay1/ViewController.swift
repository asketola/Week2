//
//  ViewController.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/12/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit
import Social

class ViewController: UIViewController, ImageSelectedProtocol, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate {
  
  // Global variable defined
  let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet) // PopMenu defined
  let mainImageView = UIImageView()                                // the big picture on the 1st page
  var collectionView : UICollectionView!                           // This holds the thumbnail filters scroll
  var collectionViewYConstraint : NSLayoutConstraint!              // <- This is to move the collection View up to make space for the filter thumbnails
  var mainImageViewVertConstraint : NSLayoutConstraint!            // This is to squish the mainImageView when the filter scroll pops up
  var originalThumbnail : UIImage!
  var filterNames = [String]()                                     // <- these names come from apple
  let imageQueue = NSOperationQueue()                              // this is what lets you put things to work in a background thread
  var gpuContext : CIContext!                                      // this placeholder var lets you use the gpu to process stuff
  var thumbnails = [Thumbnail]()                                   // <- array that will hold all our filtered thumbnails after we altered them with the filter
  var filteredImageArray = [FilterImageClass]()                    // array that will hold all our filtered big images after we altered them with the filter
  var originalImage : UIImage?                                     // for the pic in the mainImageView after we pass an image back
  var popOver : UIPopoverPresentationController?
  
  var doneButton : UIBarButtonItem!
  var shareButton : UIBarButtonItem!
  
  override func loadView() {
    let rootView = UIView(frame: UIScreen.mainScreen().bounds)              // defines the rootView variable as the full screen of the phone

    rootView.addSubview(self.mainImageView)                                 // adds the mainImageView to the rootView, must alawys do
    self.mainImageView.setTranslatesAutoresizingMaskIntoConstraints(false)  // always need to release auto-constraints when coding without storyboard
    self.mainImageView.backgroundColor = UIColor.redColor()                 // placeholder background color so you can see where the main pic will go
    self.mainImageView.clipsToBounds = true
    rootView.backgroundColor = UIColor.blackColor()                         // background of the rootView
    self.mainImageView.contentMode = UIViewContentMode.ScaleAspectFill      // <- fixes mainImageView proprty to scaletofill all images that are passed to it
   
    println("loadview")
    // Defining the button "Photos" on the 1st page
    let photoButton = UIButton()                                            // defines what photoButton is (its a button!)
    photoButton.setTranslatesAutoresizingMaskIntoConstraints(false)         // release auto-constraints, must awlays do
    rootView.addSubview(photoButton)                                        // add to rootView, must do
    photoButton.setTitle(NSLocalizedString("Photos", comment: "This is the title for the main photos button"), forState: .Normal)
    photoButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
    //  photoButton.backgroundColor = UIColor.brownColor()                  // <- set background if you want to see the button
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
    
    // ****************************************** View Dictionary ******************************************
    // Make a Dictionary called 'views'. It holds all your page's elements ex - "name of stuff" : variable
    let views = ["photoButton" : photoButton, "mainImageView" : self.mainImageView, "collectionView" : collectionView]
    
    self.setupContraintsOnRootView(rootView, forViews: views)
    
    // last call of the function
    self.view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // ****************************************** UIBar Done Button Setup ******************************************
    self.doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "This is the title for the done button"), style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
    self.shareButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "sharePressed")
    self.navigationItem.rightBarButtonItem = self.shareButton
    
    // ****************************************** Alert Action Gallery Selection Setup ******************************************
    let galleryOption = UIAlertAction(title: NSLocalizedString("Gallery", comment: "This is the title for the gallery button"), style: UIAlertActionStyle.Default) { (action) -> Void in
      println("gallery pressed")
      let galleryVC = GalleryViewController()                                        // defines galleryVC
      galleryVC.delegate = self                                      // <- makes itself the delegate, this is what makes it conform to the protocol/requirement
      self.navigationController?.pushViewController(galleryVC, animated: true)       // pushes the view to the gallery view
    }
    self.alertController.addAction(galleryOption)
    
    
    // ****************************************** Alert Action Filter Selection Setup ******************************************
    let filterOption = UIAlertAction(title: NSLocalizedString("Filter", comment: "This is the title for the filter button"), style: UIAlertActionStyle.Default) { (action) -> Void in
      println("filter button pressed")
      self.collectionViewYConstraint.constant = 20
      self.mainImageViewVertConstraint.constant = 73                                 // moves the mainImageView up so it doesn't overlap with filter thumbnails
      UIView.animateWithDuration(0.4, animations: { () -> Void in                    // makes the image move with animation
        self.view.setNeedsLayout()
      })
      
      // ****************************************** Alert Action Done Button in Filter Section Setup ******************************************
      let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "This is the title for the done button"), style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
      self.navigationItem.rightBarButtonItem = doneButton
    }
    self.alertController.addAction(filterOption)
    
    // ****************************************** Alert Action Use Camera for Pic Setup ******************************************
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
      let cameraOption = UIAlertAction(title: NSLocalizedString("Camera", comment: "This is the title for the camera button"), style: .Default, handler: { (action) -> Void in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
      })
      self.alertController.addAction(cameraOption)
    }
    
    // ****************************************** Alert Action Use Phone Pics Setup ******************************************
    let photoOption = UIAlertAction(title: NSLocalizedString("PhonePics", comment: "This is the title for the phonepic button"), style: .Default) { (action) -> Void in
      let photosVC = PhotosViewController()
      photosVC.destinationImageSize = self.mainImageView.frame.size
      photosVC.delegate = self
      self.navigationController?.pushViewController(photosVC, animated: true)               // pushes the view to the phone pics page (3rd page)
    }
    
    self.alertController.addAction(photoOption)
    
    // for ipad? I didn't have an issue with the app not working on the iPad simulator, but things I read said to put this in for iPads
    if let presentationController = alertController.popoverPresentationController {
      presentationController.sourceView = view
      presentationController.sourceRect = view.bounds
    }
    
    // ****************************************** GPU Processessing Setup ******************************************
    let options = [kCIContextWorkingColorSpace : NSNull()] // helps keep things fast
    let eagleContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    self.gpuContext = CIContext(EAGLContext: eagleContext, options: options)
    self.setupThumbnails()
    
    // ****************************************** Tap Gesture Setup ******************************************
    var tapGesture = UITapGestureRecognizer(target: self, action: Selector("handleTapGesture:"))
    tapGesture.numberOfTapsRequired = 2
    //view.addGestureRecognizer(tapGesture)                                // <- original, can tap anywhere, overrides ability to select animage to filter
    self.mainImageView.addGestureRecognizer(tapGesture)                    // make it just the mainImageView - seems to work for the print statements
    self.mainImageView.userInteractionEnabled = true                       // not sure if this will help with the UIGesture recognition
    
    
    self.collectionView.delegate = self
  } // closes ViewDidLoad
  
  override func viewDidAppear(animated: Bool) {
    println("viewDidAppear")
    self.originalImage = self.mainImageView.image
  }
  
   // ****************************************** Tap Gesture Function ******************************************
  func handleTapGesture(tapGesture: UITapGestureRecognizer) {
    println("tap - func handleTapGesture called")
    if mainImageView.image != nil {
      println("You can filter an image")
      println("as if filter button had been pressed")
      self.collectionViewYConstraint.constant = 20                                  // makes space for the thumbnails in in the collectionView
      self.mainImageViewVertConstraint.constant = 73                                // moves the mainImageView up so it doesn't overlap with filter thumbnails
      UIView.animateWithDuration(0.4, animations: { () -> Void in                   // makes the image move with animation
        self.view.setNeedsLayout()
      })
      // set up the done Button in the alertController
      let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: "This is the title for the done button"), style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
      self.navigationItem.rightBarButtonItem = doneButton
    } else {
      println("There is no image to filter")
    }
  }
  
// ****************************************** Filter setupThumbnail Function ******************************************
    func setupThumbnails() {
      println("func setupThumbnails called")
      self.filterNames = ["CISepiaTone","CIPhotoEffectChrome", "CIPhotoEffectNoir", "CIDotScreen", "CIPixellate", "CIColorMonochrome", "CIFalseColor", "CIHatchedScreen", "CIColorPosterize", "CICircularScreen"]  // these names come from apple, and must be precicely spelled
      for name in self.filterNames {  // loops through the names in the filter arrray to make an example thumbnail of each filter
        let thumbnail = Thumbnail(filterName: name, operationQueue: self.imageQueue, context: self.gpuContext)
        self.thumbnails.append(thumbnail)  // adds the filter thumbnail to the array
      }
  }
        //set up here to click on the thumbnail and pass on the filtername and pass that on to mainImageView
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
          println("This is the indexPath for the filtered thumbnails: \(self.filterNames[indexPath.row])")
          println("func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) called")
          
          let name = self.filterNames[indexPath.row]
          let filterImage = FilterImageClass(originalImage: self.originalImage!, filterName: name, operationQueue: self.imageQueue, context: self.gpuContext)
          filterImage.generateFilteredImage()
      
          self.mainImageView.image = filterImage.filteredImage                    // sets the image to the mainImageView
    }
 
    
    // Required for the ImageSelectedDelegate protocol, for you to select an image
    func controllerDidSelectImage(image: UIImage) {
      println("func controllerDidSelectImage called")
      self.mainImageView.image = image
      self.generateThumbnail(image)
      
      for thumbnail in self.thumbnails {
        thumbnail.orginalImage = self.originalThumbnail                            // you always keep the original thumbnail and original picture
        thumbnail.filteredImage = nil
      }
      self.collectionView.reloadData()
    }
  
  // ****************************************** UIImagePickerController Function ******************************************
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    println("func imagePickerController called")
    let image = info[UIImagePickerControllerEditedImage] as? UIImage
    self.controllerDidSelectImage(image!)
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // For the Button Selectors
  // ****************************************** Button Selector Function ******************************************
  func photoButtonPressed(sender : UIButton) {                     // <- lets you click the button and then the alertController pops up, in a nice animated way
    println("func photoButtonPressed called")
    self.presentViewController(self.alertController, animated: true, completion: nil)
  }
  
  
  // ****************************************** GenerateThumbnail Function ******************************************
    func generateThumbnail(originalImage: UIImage) {
      println("func generateThumbnail called")
      let size = CGSize(width: 100, height: 100)                              // <- defines the size we want
      UIGraphicsBeginImageContext(size)                                       // does the resizing
      originalImage.drawInRect(CGRect(x: 0, y: 0, width: 100, height: 100))   // <- Draws the entire image in the specified rectangle, scaling it as needed to fit
      self.originalThumbnail = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()                                             // <- releases memory, stops data leaks
    }
  
  // ****************************************** donePressed Function ******************************************
  func donePressed() {                                                        // For AlertController done button
    println("func donePressed called")
  self.collectionViewYConstraint.constant = -120
    self.mainImageViewVertConstraint.constant = 30
    UIView.animateWithDuration(0.4, animations: { () -> Void in
      self.view.layoutIfNeeded()
    })
    self.navigationItem.rightBarButtonItem = self.shareButton
    println("You pressed the done button")
  }
  
  
  func sharePressed() {                                                       // For sharing your image with Twitter
    println("func sharePressed called")
    if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
    let compViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    compViewController.addImage(self.mainImageView.image)
    self.presentViewController( compViewController, animated: true, completion: nil)
    } else {
    }
  }
    // ****************************************** CollectionView Functions ******************************************
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section : Int) -> Int {  // required for the UICollectionViewData
      println("func collectionView(collectionView: UICollectionView, numberOfItemsInSection section : Int) -> Int")
      return self.thumbnails.count
    }
  
  
  // This function tells you how to draw an individual cell in the thumbnails array
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
      println("func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell called")
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FILTER_CELL", forIndexPath: indexPath) as GalleryCell
      let thumbnail = self.thumbnails[indexPath.row]
      if thumbnail.orginalImage != nil {  // <- only run if the thumbnail is chosen
        if thumbnail.filteredImage == nil {   // <- only run if a photo exists
          thumbnail.generateFilteredImage()   // actually does the filtering work
          cell.imageView.image = thumbnail.filteredImage!   // <- gives the thumbnail to the cell
        } else {
          cell.imageView.image = thumbnail.filteredImage! //if the answer isn't nill, then reload the pic. Otherwise, it will forget while you are scrolling, and only reshow the old pics
        }
      }
      println("This came from the UICollevtionViewDataSource func")
      return cell
    }
  
  
  // ****************************************** AutoLayout Constraints Definitions ******************************************
  func setupContraintsOnRootView(rootView : UIView, forViews views : [String : AnyObject]) {
  
    // for the photo button. Formula: make a constraint(s) with a 'let,' then add it to the 'rootView'. Uses the names set in the Dictionary: 'views'
    let photoButtonConstraintVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:[photoButton]-20-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(photoButtonConstraintVertical)
    let photoButton = views["photoButton"] as UIView!
    let photoButtonConstraintHorizontal = NSLayoutConstraint(item: photoButton, attribute: .CenterX, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
    rootView.addConstraint(photoButtonConstraintHorizontal)
    photoButton.setContentHuggingPriority(750, forAxis: UILayoutConstraintAxis.Vertical)  // this fixes ???
    
    // for the mainImageView
    let mainImageViewConstraintsHorizontal = NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[mainImageView]-8-|", options: nil, metrics: nil, views: views)
    rootView.addConstraints(mainImageViewConstraintsHorizontal)
    let mainImageViewConstraintVertical = NSLayoutConstraint.constraintsWithVisualFormat("V:|-72-[mainImageView]-30-[photoButton]", options: nil, metrics: nil, views: views)

    self.mainImageViewVertConstraint = mainImageViewConstraintVertical.last as NSLayoutConstraint // to squish the image when the filter scroll pops-up
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
