//
//  Post+CoreDataProperties.swift
//  Blink
//
//  Created by Matic Conradi on 18/09/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import Foundation
import CoreData

extension Post {
    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }
    
    @NSManaged var post: String
    @NSManaged var desc: String
    @NSManaged var link: String
    @NSManaged var image: String
    @NSManaged var imageSize: [Double]
    @NSManaged var condition: String
    @NSManaged var time: Int
}
