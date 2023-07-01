//
//  Photos.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [Photo]
}
