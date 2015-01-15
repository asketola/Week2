//
//  PhotosViewController.swift
//  PhotoFilterDay1
//
//  Created by Annemarie Ketola on 1/14/15.
//  Copyright (c) 2015 Up Early, LLC. All rights reserved.
//

import UIKit
import Photos

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  
  // Define global variables for PH photo stuff
  var assentsFetchResults : PHFetchResult!  // defines type, var set later
  var assetCollection : PHAssetCollection!  // defines type, var set later
  var imageManger = PHCachingImageManager()  // defined as method
  
  // Define global variable for the UICollectionView, which makes the view to see the phots you want to import
  var collectionView : UICollectionView!
  
  // Define global variable for ???
  var destinationImageSize : CGSize!
  
  // Define the variable to hook up with the ImageSelectedProtocol defined in the GalleryViewController that helps pass data
  var delegate : ImageSelectedProtocol?
  
  override func loadView() {
    let rootView = UIView(frame: UIScreen.mainScreen().bounds)   // makes the new window/screen
    
    self.collectionView = UICollectionView(frame: rootView.bounds, collectionViewLayout: UICollectionViewFlowLayout())  //makes the collectionView
    
    let flowLayout = collectionView.collectionViewLayout as UICollectionViewFlowLayout
    flowLayout.itemSize = CGSize(width: 100, height: 100)  // <- defines the size of the images in the collectioveView, they are 100 by 100 thumbnails
    
    rootView.addSubview(collectionView)  // <- adds the collectioView to the subView, have to do
    collectionView.setTranslatesAutoresizingMaskIntoConstraints(false) // <- gets rid of the autoconstraints, must do
    
    // always the last line!
    self.view = rootView // loads the rootView (?) is this true?
  }
  


    override func viewDidLoad() {
        super.viewDidLoad()
      
      // does stuff together for PH
      self.imageManger = PHCachingImageManager()
      self.assentsFetchResults = PHAsset.fetchAssetsWithOptions(nil)
      
      // Sets the powers of the collectionView, gets it own data, is its own delegate
      self.collectionView.dataSource = self
      self.collectionView.delegate = self
      self.collectionView.registerClass(GalleryCell.self, forCellWithReuseIdentifier: "PHOTO_CELL")  // calls the GalleryCell as a template, new identifier we are naming here is "PHOTO_CELL"

        // Do any additional setup after loading the view.
    }
  
  
  // Functions for the collectionView
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.assentsFetchResults.count  // finds out how many assets there are
  }
  
  // this function calls the GalleryCell to use it as a template and make the cell. It then makes the photo a thumbnail (?)
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PHOTO_CELL", forIndexPath: indexPath) as GalleryCell  // sets the cell with the GalleryCell
    
    let asset = self.assentsFetchResults[indexPath.row] as PHAsset
    self.imageManger.requestImageForAsset(asset, targetSize: CGSize(width: 100, height: 100), contentMode: PHImageContentMode.AspectFill, options: nil) { (requestedImage, info) -> Void in
      cell.imageView.image = requestedImage
    }
    return cell
  }
  
  // this is the function that lets you select the image and then pass it over to the 1st page (rootView)
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    println("didselectitem")
    let selectedAsset = self.assentsFetchResults[indexPath.row] as PHAsset
    self.imageManger.requestImageForAsset(selectedAsset, targetSize: self.destinationImageSize, contentMode: PHImageContentMode.AspectFill, options: nil) { (requestedImage, info) -> Void in  // something image?
      self.delegate?.controllerDidSelectImage(requestedImage)  // calls the protocol to share the data, using the delegate
      
      
      
      self.navigationController?.popToRootViewControllerAnimated(true)  // moves it to the other page
  }
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
