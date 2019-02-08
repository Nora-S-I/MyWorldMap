//
//  PhotosViewerViewController.swift
//  My World Map
//
//  Created by Norah Al Ibrahim on 2/5/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit


class PhotosViewerViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var selectedIndex: Int!
    var photoArray: [Photo]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        imageView.image = UIImage(data: photoArray[selectedIndex].image! as Data)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func handleRightSwipe(_ sender:UISwipeGestureRecognizer) {
        if selectedIndex - 1 >= 0 {
            selectedIndex -= 1
            imageView.image = UIImage(data: photoArray[selectedIndex].image! as Data)
        }
    }
    
    @objc func handleLeftSwipe(_ sender:UISwipeGestureRecognizer) {
        
        if selectedIndex + 1 < photoArray.count {
            selectedIndex += 1
            imageView.image = UIImage(data: photoArray[selectedIndex].image! as Data)
        }
    }
}
