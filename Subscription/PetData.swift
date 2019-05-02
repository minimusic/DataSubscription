//
//  PetData.swift
//  Subscription
//
//  Created by Chad on 10/9/18.
//  Copyright © 2018 raizlabs. All rights reserved.
//

//public protocol PetSubscriber: AnyObject {
//    func publisher(_ publisher: PetData, sentMessage: PublishMessageType)
//}
//
//public class PetData: ExplicitPublisher<Pet, PetSubscriber> {
//
//    // This should only be called by request completion
//    public func removeInstance(_ itemID: Int) {
//        // Find matching instance
//        data = data.filter({ $0.id != itemID })
//        isLoading = false
//        // notify all subscribers
//        publish(.dataMessages)
//    }
//
//    // This should only be called by request completion
//    public func updateInstance(_ newItem: Pet) {
//        // find matching item, handle duplicates?
//        for index in 0..<data.count {
//            let aPet = data[index]
//            if aPet.id == newItem.id {
//                // replace matching item with updated version
//                data[index] = newItem
//            }
//        }
//        isLoading = false
//        // notify all subscribers
//        publish(.dataMessages)
//    }
//
//    override public func publish(to subscriber: PetSubscriber, with message: PublishMessageType) {
//        subscriber.publisher(self, sentMessage: message)
//    }
//}
