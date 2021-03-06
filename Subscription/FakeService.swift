//
//  FakeService.swift
//  Subscription
//
//  Created by Chad on 3/29/19.
//  Copyright © 2019 raizlabs. All rights reserved.
//

import Foundation
import UIKit

public struct DataModel {
    var id: String
    var title: String
    var subtitle: String
    var color: UIColor
}

class DataEndpoint {
    static func getShipment(completion: @escaping (Result<[DataModel],Error>) -> Void) {
        // Random delay
        let randomDelay = Int.random(in: 1...5)
        print("Delay = \(randomDelay)")
        // Wait until we publish to move to main queue?
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(randomDelay)) {
            // 20% chance of error
            let isError: Bool = Int.random(in: 1...5) == 1
            // Random response
            if isError {
                completion(.failure(FakeError.serviceError))
            } else {
                let arrayCount = Int.random(in: 10...25)
                var resultArray: [DataModel] = []
                let defaultArray = Array.init(repeating: DataModel(id:"123", title: "Data Item 1", subtitle: "Subtitle", color: .red), count: arrayCount)
                defaultArray.forEach { (result) in
                    var newResult = result
                    if let randomColor = DataColors(rawValue: Int.random(in: 0...(DataColors.allCases.count - 1))) {
                        newResult.color =  randomColor.color()
                    }
                    let randomAdj = DataModifiers.allCases[Int.random(in: 0...(DataModifiers.allCases.count - 1))]
                    let randomMarsupial = DataTitles.allCases[Int.random(in: 0...(DataTitles.allCases.count - 1))]
                    newResult.title = randomAdj.rawValue.capitalized + " " + randomMarsupial.rawValue
                    resultArray.append(newResult)
                }
                completion(.success(resultArray))
            }
        }
    }
}

public enum FakeError: Swift.Error {
    case serviceError
}

public enum DataColors: Int, CaseIterable {
    case red
    case blue
    case pink
    case peach
    case green

    func color() -> UIColor {
        switch self {
        case .red:
            return UIColor(named: "red") ?? .lightGray
        case .blue:
            return UIColor(named: "blue") ?? .lightGray
        case .pink:
            return UIColor(named: "pink") ?? .lightGray
        case .peach:
            return UIColor(named: "peach") ?? .lightGray
        case .green:
            return UIColor(named: "green") ?? .lightGray
        }
    }
}

/// marsupials
public enum DataTitles: String, CaseIterable {
    case kangaroos
    case wallabies
    case koalas
    case wombats
    case tasmanianDevils = "Tasmanian devils"
    case opossums
    case gliders
    case bandicoots
    case quolls
    case potoroos
    case bettongs
    case yapoks
    case cuscuses
    case dunnarts
    case numbats
    case bilbies
}

/// positive adjectives
public enum DataModifiers: String, CaseIterable {
    case aggressive
    case agreeable
    case ambitious
    case brave
    case calm
    case delightful
    case eager
    case faithful
    case gentle
    case happy
    case jolly
    case kind
    case lively
    case nice
    case obedient
    case polite
    case proud
    case silly
    case thankful
    case victorious
    case witty
    case wonderful
    case zealous
}
