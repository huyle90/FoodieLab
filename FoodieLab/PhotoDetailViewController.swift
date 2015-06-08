//
//  PhotoDetailViewController.swift
//  FoodieLab
//
//  Created by Huy Le on 6/8/15.
//  Copyright (c) 2015 Huy Le. All rights reserved.
//

import Foundation

private let imageViewX : CGFloat = 0
private let imageViewY : CGFloat = (CGSize.screenHeight() - imageViewHeight)/2 + 32
private let imageViewWidth : CGFloat = CGSize.screenWidth()
private let imageViewHeight : CGFloat = 400

class PhotoDetailViewController: UIViewController {
    var placeId: String!
    var imageView: UIImageView!
    private var placeDetailSearchQueries : [NSDictionary]!

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil);
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        self.view.backgroundColor = UIColor.whiteColor()
        //self.placeDetailSearchQueries = []
        
        imageView = UIImageView(frame: CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight))
        imageView.backgroundColor = UIColor.grayColor()
        self.view.addSubview(imageView)
        getPhotoWithReference(self.placeId)
        
    }
    func load_image(urlString:String)
    {
        
        var imgURL: NSURL! = NSURL(string: urlString)
        let request: NSURLRequest = NSURLRequest(URL: imgURL)
        NSURLConnection.sendAsynchronousRequest(
            request, queue: NSOperationQueue.mainQueue(),
            completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                if error == nil {
                    self.imageView.image = UIImage(data: data)
                }
        })
        
    }
    func getPhotoWithReference(reference: String){
        self.retrieveGooglePlaceInformation(reference, completion: { (results) -> () in
            

            if let photoDetails = results {
                let photosArray : [NSDictionary]! = photoDetails["photos"] as? [NSDictionary]
                if photosArray != nil {
                    if let photoReference : String = photosArray[0]["photo_reference"] as? String {
                        println(photoReference)
                        var urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)&key=AIzaSyDZeZ2BweGVdUli7hSMfljgtAYQp4RAV5U"
                        println(urlString)
                        self.load_image(urlString)
                    }
                }
            }
        })

    }
    
    func retrieveGooglePlaceInformation(reference : String!, completion: (NSDictionary?) -> ()){
        

        var urlString = "https://maps.googleapis.com/maps/api/place/details/json?reference=\(reference)&key=AIzaSyDZeZ2BweGVdUli7hSMfljgtAYQp4RAV5U"
        let url = NSURL(string: urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        let defaultConfigObject = NSURLSessionConfiguration.defaultSessionConfiguration()
            
        let delegateFreeSession = NSURLSession(configuration: defaultConfigObject, delegate: nil, delegateQueue: nil)
            
        var request = NSURLRequest(URL: url!)
        let queue:NSOperationQueue = NSOperationQueue()
        
        let task = delegateFreeSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: nil) as? NSDictionary
            if dictionary != nil {
                let results : NSDictionary! = dictionary!["result"] as? NSDictionary
                let status : String! = (dictionary!["status"] as? String) ?? ""
                if (status == "NOT_FOUND" || status == "REQUEST_DENIED" || error != nil){
                    completion(nil)
                }
                else{
                    completion(results)
                
                }
            }
        })
        task.resume()
        
    }

}





