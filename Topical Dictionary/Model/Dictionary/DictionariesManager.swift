//
//  DictionariesManager.swift
//  Topical Dictionary
//
//  Created by İbrahim Ethem Karalı on 24.08.2020.
//  Copyright © 2020 İbrahim Ethem Karalı. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class DictionariesManager {
    
    var db: Firestore!
    
    weak var delegate: DictionariesManagerDelegate?
    var allDictionaries: [DictionaryModel]?
    var sortingType = SortingType.newToOld
    var isListingFav = false
    
    var currentUser: User? {
        self.fireBaseSettings()
        return Auth.auth().currentUser
    }
    
    private func fireBaseSettings() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db = Firestore.firestore()
        db.settings = settings
    }
    
    
    func setListener() {
        
        if let user = currentUser {
            let snapShotListener = db.collection(Keys.dictionaryCollectionID.rawValue).whereField("creator", isEqualTo: user.uid).addSnapshotListener { (querySnapshot, error) in
                if let err = error {
                    self.delegate?.didFailLoadDictionaries(self, error: err)
                    return
                }
                if self.allDictionaries == nil {
                    self.loadDictionaries(querySnapshot, error)
                    return
                }
                if let documentChanges = querySnapshot?.documentChanges {
                    for change in documentChanges {
                        
                        switch change.type {
                        case .added:
                            guard let changedDictionary = try! change.document.data(as: DictionaryModel.self) else { return}
                            self.allDictionaries?.append(changedDictionary)
                            self.sortDictionaries(by: self.sortingType)
                            self.delegate?.didAddDictionary(self, dictionary: changedDictionary)
                        case .removed:
                            guard let changedDictionary = try! change.document.data(as: DictionaryModel.self) else { return}
                            self.allDictionaries?.removeAll(where: { (dictionaryModel) -> Bool in
                                dictionaryModel.id == changedDictionary.id
                            })
                        default:
                            guard let changedDictionary = try! change.document.data(as: DictionaryModel.self) else { return}
                            let index = self.allDictionaries?.firstIndex(where: { (dictionaryModel) -> Bool in
                                changedDictionary.id == dictionaryModel.id
                            })
                            if index != nil {
                                //self.updateDictionary(document)
                                self.allDictionaries![index!] = changedDictionary
                                self.sortDictionaries(by: self.sortingType)
                            }
                        }
                        
                    }
                    self.delegate?.dictionariesDidChange(self)
                }
            }
            AppDelegate.snapShotListeners.append(snapShotListener)
        }
    }
    
    private func loadDictionaries(_ querySnapshot: QuerySnapshot?, _ error: Error?) {
        if error != nil {
            self.delegate?.didFailLoadDictionaries(self, error: error!)
        }
        if let documents = querySnapshot?.documents {
            self.allDictionaries = self.mapDocuments(documents)
            self.sortDictionaries(by: self.sortingType)
        }
    }
    
    private func mapDocuments(_ documents: [QueryDocumentSnapshot]) -> [DictionaryModel] {
        let items = documents.compactMap { (queryDocumentSnapshot) -> DictionaryModel in
            return try! queryDocumentSnapshot.data(as: DictionaryModel.self)!
        }
        
        return items
    }
    
    func sortDictionaries(by sortingType: SortingType) {
        self.sortingType = sortingType // if given type is different then change
        if allDictionaries != nil {
            switch sortingType {
            case .aToZ:
                allDictionaries!.sort(by: { (d0, d1) -> Bool in
                    (d0.topic ?? "").lowercased() < (d1.topic ?? "").lowercased()
                })
            case .zToA:
                allDictionaries!.sort(by: { (d0, d1) -> Bool in
                    (d0.topic ?? "").lowercased() > (d1.topic ?? "").lowercased()
                })
            case .oldToNew:
                allDictionaries!.sort(by: {
                    ($0.date ?? Timestamp(seconds: 0, nanoseconds: 0)).seconds < ($1.date ?? Timestamp(seconds: 0, nanoseconds: 0)).seconds
                })
            default:
                allDictionaries!.sort(by: {
                    ($0.date ?? Timestamp(seconds: 0, nanoseconds: 0)).seconds > ($1.date ?? Timestamp(seconds: 0, nanoseconds: 0)).seconds
                })
            }
            
            DispatchQueue.main.async {
                self.delegate?.didLoadDictionaries(self, dictionaries: self.allDictionaries!)
            }
            
        }
    }
    
    func favoriteDictionaries() -> [DictionaryModel] {
        guard let favDictionaries = allDictionaries?.filter({ (dictionaryModel) -> Bool in
            dictionaryModel.isFavorite ?? false
        }) else {
            return [DictionaryModel]()
        }
        
        return favDictionaries
    }
    
    
    
}

protocol DictionariesManagerDelegate: AnyObject {
    func didLoadDictionaries(_ dictionaryManager: DictionariesManager, dictionaries: [DictionaryModel])
    func didFailLoadDictionaries(_ dictionaryManager: DictionariesManager, error: Error)
    func dictionariesDidChange(_ dictionaryManager: DictionariesManager)
    func didAddDictionary(_ dictionaryManager: DictionariesManager, dictionary: DictionaryModel)
}
