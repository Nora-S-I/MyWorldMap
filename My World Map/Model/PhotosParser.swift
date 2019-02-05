//
//  PhotosParser.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct PhotosParser: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [PhotoParser]
}

struct PhotoParser: Codable {
    
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_n"
        case title
    }
}
