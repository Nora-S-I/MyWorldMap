//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/27/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "PhotoCollectionViewCell"
    var imageUrl: String = ""
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
}
