//
//  FavoritesService.swift
//  Services
//
//  Created by Chris Ballinger on 10/24/18.
//  Copyright © 2018 Raizlabs. All rights reserved.
//

import Foundation


//extension APIClient: FavoritesService {
//    public func createFavorites(completion: @escaping (Result<VariantCollection>) -> Void) -> RequestProtocol? {
//        guard let customerId = self.customerId else {
//            Log.error("Cannot create favorites because customerId is nil!")
//            completion(.failure(APIError.missingParameters))
//            return nil
//        }
//        let endpoint = FavoritesEndpoint.CreateList(customerId: customerId)
//        return request(endpoint) { (response, error) in
//            if let favorites = response {
//                self._favorites = favorites
//                completion(.success(favorites))
//            } else if let error = error {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    public var favorites: VariantCollection? {
//        return _favorites
//    }
//
//    public func getFavorites(completion: @escaping (Result<VariantCollection>) -> Void) -> RequestProtocol? {
//        guard let favoritesId = customer?.favoritesId else {
//            Log.error("Cannot fetch favorites because customer or favorites is nil!")
//            completion(.failure(APIError.missingParameters))
//            return nil
//        }
//        let endpoint = FavoritesEndpoint.Get(favoritesId: favoritesId)
//        return request(endpoint) { (response, error) in
//            if let favorites = response {
//                self._favorites = favorites
//                completion(.success(favorites))
//            } else if let error = error {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    @discardableResult
//    public func getFavorites(favoritesId: Identifier<VariantCollection>, completion: @escaping (Result<VariantCollection>) -> Void) -> RequestProtocol? {
//        let endpoint = FavoritesEndpoint.Get(favoritesId: favoritesId)
//        return request(endpoint) { (response, error) in
//            if let favorites = response {
//                self._favorites = favorites
//                completion(.success(favorites))
//            } else if let error = error {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    @discardableResult
//    public func addFavorite(variantId: Identifier<Variant>, completion: @escaping (Result<VariantCollectionItem>) -> Void) -> RequestProtocol? {
//        guard let favoritesId = self.favorites?.id else {
//            Log.error("Cannot create favorite because favoritesId is nil!")
//            completion(.failure(APIError.missingParameters))
//            return nil
//        }
//        let endpoint = FavoritesEndpoint.AddFavorite(favoritesId: favoritesId, variantId: variantId)
//        return request(endpoint) { (response, error) in
//            if let vci = response {
//                // TODO: refetch full favorites list here?
//                completion(.success(vci))
//            } else if let error = error {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    public func getFavorite(variantId: Identifier<Variant>, completion: @escaping (Result<VariantCollectionItem>) -> Void) -> RequestProtocol? {
//        guard let favoritesId = customer?.favoritesId else {
//            Log.error("Cannot fetch favorites because customer or favorites is nil!")
//            completion(.failure(APIError.missingParameters))
//            return nil
//        }
//        let endpoint = FavoritesEndpoint.GetFavorite(favoritesId: favoritesId, variantId: variantId)
//        return request(endpoint) { (response, error) in
//            if let searchResults = response,
//                let result = searchResults.results.first?.value {
//                // technically there can be more than one result
//                // but there never _should_ be more than one
//                completion(.success(result))
//            } else if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.failure(APIError.invalidResponse))
//            }
//        }
//    }
//
//    @discardableResult
//    public func deleteFavorite(variantId: Identifier<Variant>, completion: @escaping (Result<Void>) -> Void) -> RequestProtocol? {
//        return getFavorite(variantId: variantId) { (result) in
//            switch result {
//            case .success(let favorite):
//                self.deleteFavorite(favoriteId: favorite.id, completion: completion)
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    @discardableResult
//    public func deleteFavorite(favoriteId: Identifier<VariantCollectionItem>, completion: @escaping (Result<Void>) -> Void) -> RequestProtocol? {
//        let endpoint = FavoritesEndpoint.DeleteFavorite(favoriteId: favoriteId)
//        return request(endpoint) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
//}
//
//public final class FavoritesManager: NSObject {
//    public let service: APIClient
//    public let publisher: NewPublisher<VariantCollection>
//    private var cachedFavoritesId: Identifier<VariantCollection>?
//
//    public init(service: APIClient) {
//        self.service = service
//        publisher = NewPublisher<VariantCollection>()
//    }
//
//    public func reloadFavorites() {
//        if let cachedID = cachedFavoritesId {
//            getFavorites(favoritesId: cachedID)
//        }
//    }
//
//    public func getFavorites(favoritesId: Identifier<VariantCollection>) {
//        publisher.startLoading()
//        service.getFavorites(favoritesId: favoritesId) { (result) in
//            switch result {
//            case .success(let favoritesResult):
//                self.publisher.updateData(favoritesResult)
//            case .failure(let error):
//                // Search may have been cancelled
//                Log.error("Could not get customer: \(error)")
//                self.publisher.setError(error)
//            }
//        }
//    }
//
//    public func deleteFavorite(favoriteId: Identifier<Variant>) {
//        service.deleteFavorite(variantId: favoriteId) { (result) in
//            switch result {
//            case .success:
//                Log.info("Deleted favorite \(favoriteId)")
//                self.reloadFavorites()
//            case .failure(let error):
//                Log.error("Could not delete favorite: \(favoriteId) \(error)")
//            }
//        }
//    }
//
//    public func addFavorite(favoriteId: Identifier<Variant>) {
//        service.addFavorite(variantId: favoriteId) { (result) in
//            switch result {
//            case .success(let variantCollectionItem):
//                Log.info("Added favorite \(variantCollectionItem)")
//                self.reloadFavorites()
//            case .failure(let error):
//                Log.error("Couldn't add delete favorite: \(favoriteId) \(error)")
//            }
//        }
//    }
//}
//
//extension FavoritesManager: ManagerProtocol {
//    public func start(with container: DataContainer) {
//        let customerManager = container.customerManager
//        customerManager.subscribe(self)
//    }
//
//    public func refreshIfNeeded() {
//        switch publisher.state {
//        case .error:
//            if let favesId = cachedFavoritesId {
//                getFavorites(favoritesId: favesId)
//            }
//        default:
//            break
//        }
//    }
//
//    public func logout() {
//        publisher.reset()
//        cachedFavoritesId = nil
//    }
//}
//
//extension FavoritesManager: NewSubscriberProtocol {
//    public func publication(from publisher: AnyNewPublisher) {
//        if let customerPublisher = publisher as? NewPublisher<Customer> {
//            switch customerPublisher.state {
//            case .loaded(let customerData):
//                if let favesId = customerData.favoritesId {
//                    cachedFavoritesId = favesId
//                    getFavorites(favoritesId: favesId)
//                }
//            default:
//                return
//            }
//        } else {
//            Log.error("Recieved un-handled publication.")
//        }
//    }
//}
