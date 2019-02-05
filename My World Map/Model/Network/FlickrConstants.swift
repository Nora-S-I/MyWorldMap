//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation


struct Flickr {
    static let APIScheme = "https"
    static let APIHost = "api.flickr.com"
    static let APIPath = "/services/rest"
    
    static let SearchBBoxHalfWidth = 0.2
    static let SearchBBoxHalfHeight = 0.2
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
}

// MARK: - Flickr Parameter Keys

struct FlickrParameterKeys {
    static let Method = "method"
    static let APIKey = "api_key"
    static let GalleryID = "gallery_id"
    static let Extras = "extras"
    static let Format = "format"
    static let NoJSONCallback = "nojsoncallback"
    static let SafeSearch = "safe_search"
    static let BoundingBox = "bbox"
    static let PhotosPerPage = "per_page"
    static let Accuracy = "accuracy"
    static let Page = "page"
}

// MARK: - Flickr Parameter Values

struct FlickrParameterValues {
    static let SearchMethod = "flickr.photos.search"
    static let APIKey = "04de9ad02329f5e4bf0d8b42cd93ef11"
    static let ResponseFormat = "json"
    static let DisableJSONCallback = "1" /* 1 means "yes" */
    static let MediumURL = "url_n"
    static let UseSafeSearch = "1" /* 1 means safe content */
    static let PhotosPerPage = 30
    static let AccuracyCityLevel = "11"
    static let AccuracyStreetLevel = "16"
}

