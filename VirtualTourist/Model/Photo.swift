//
//  Photo.swift
//  VirtualTourist
//
//  Created by Marco Guevara on 11/03/23.
//

struct Photo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    let url_sq: String
}
