//
//  BarcodeModel.swift
//  Services

import Foundation

struct BarcodeModel: Codable {
    let FileStatus: Int
    let RequestData : [requestData]
}

struct requestData: Codable {
    let RecognitionType: String
    let data : [BarcodeData]
    let ServiceType: ServiceType
}

struct BarcodeData: Codable {
    let Symbology: String
    let Value: String
    let Bounds: String
    let RotationAngle: Int
}

enum ServiceType: String, Codable {
    case Recognition
    case Coversion
}
