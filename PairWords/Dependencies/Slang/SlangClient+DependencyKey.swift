//
//  SlangClient+DependencyKey.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseStorage
import FirebaseAuth

extension SlangClient: nonisolated DependencyKey {
    nonisolated static let liveValue: SlangClient = {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        return SlangClient(
            observeSlangs: { groupID in
                AsyncStream { continuation in
                    let listener = db.collection("groups").document(groupID)
                        .collection("slangs")
                        .order(by: "createdAt", descending: true)
                        .addSnapshotListener { snapshot, _ in
                            let slangs = snapshot?.documents
                                .compactMap { try? $0.data(as: Slang.self) } ?? []
                            continuation.yield(slangs)
                        }
                    continuation.onTermination = { _ in listener.remove() }
                }
            },

            observeMeanings: { groupID, slangID in
                AsyncStream { continuation in
                    let listener = db.collection("groups").document(groupID)
                        .collection("slangs").document(slangID)
                        .collection("meanings")
                        .order(by: "createdAt", descending: true)
                        .addSnapshotListener { snapshot, _ in
                            let meanings = snapshot?.documents
                                .compactMap { try? $0.data(as: Meaning.self) } ?? []
                            continuation.yield(meanings)
                        }
                    continuation.onTermination = { _ in listener.remove() }
                }
            },

            observeRecordings: { groupID, slangID in
                AsyncStream { continuation in
                    let listener = db.collection("groups").document(groupID)
                        .collection("slangs").document(slangID)
                        .collection("recordings")
                        .order(by: "createdAt", descending: true)
                        .addSnapshotListener { snapshot, _ in
                            let recordings = snapshot?.documents
                                .compactMap { try? $0.data(as: Recording.self) } ?? []
                            continuation.yield(recordings)
                        }
                    continuation.onTermination = { _ in listener.remove() }
                }
            },

            createSlang: { groupID, name, meaning, audioURL in
                guard let uid = Auth.auth().currentUser?.uid else {
                    throw SlangRegistrationError.retryLater
                }

                let audioDownloadURL: String
                do {
                    let ref = storage.reference()
                        .child("groups/\(groupID)/recordings/\(UUID().uuidString).m4a")
                    _ = try await ref.putFileAsync(from: audioURL)
                    audioDownloadURL = try await ref.downloadURL().absoluteString
                } catch {
                    throw SlangRegistrationError.retryLater
                }

                let slangRef = db.collection("groups").document(groupID)
                    .collection("slangs").document()

                let batch = db.batch()
                try batch.setData(from: Slang(
                    id: slangRef.documentID,
                    name: name,
                    representativeMeaning: meaning,
                    createdBy: uid,
                    createdAt: Date()
                ), forDocument: slangRef)

                let meaningRef = slangRef.collection("meanings").document()
                try batch.setData(from: Meaning(
                    id: meaningRef.documentID, text: meaning, createdBy: uid, createdAt: Date()
                ), forDocument: meaningRef)

                let recordingRef = slangRef.collection("recordings").document()
                try batch.setData(from: Recording(
                    id: recordingRef.documentID, audioURL: audioDownloadURL, createdBy: uid, createdAt: Date()
                ), forDocument: recordingRef)

                try await batch.commit()
            },

            addMeaning: { groupID, slangID, meaning in
                guard let uid = Auth.auth().currentUser?.uid else {
                    throw SlangRegistrationError.retryLater
                }
                let data = Meaning(text: meaning, createdBy: uid, createdAt: Date())
                try db.collection("groups").document(groupID)
                    .collection("slangs").document(slangID)
                    .collection("meanings").addDocument(from: data)
            },

            addRecording: { groupID, slangID, audioURL in
                guard let uid = Auth.auth().currentUser?.uid else {
                    throw SlangRegistrationError.retryLater
                }
                do {
                    let ref = storage.reference()
                        .child("groups/\(groupID)/recordings/\(UUID().uuidString).m4a")
                    _ = try await ref.putFileAsync(from: audioURL)
                    let downloadURL = try await ref.downloadURL().absoluteString
                    let data = Recording(audioURL: downloadURL, createdBy: uid, createdAt: Date())
                    try db.collection("groups").document(groupID)
                        .collection("slangs").document(slangID)
                        .collection("recordings").addDocument(from: data)
                } catch {
                    throw SlangRegistrationError.retryLater
                }
            },

            fetchSlang: { groupID, keyword in
                let snapshot = try await db.collection("groups").document(groupID)
                    .collection("slangs")
                    .order(by: "name")
                    .getDocuments()

                let all = snapshot.documents.compactMap { try? $0.data(as: Slang.self) }
                return all.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
            }
        )
    }()
}
