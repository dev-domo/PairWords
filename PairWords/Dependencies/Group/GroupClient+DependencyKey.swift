//
//  GroupClient+DependencyKey.swift
//  PairWords
//
//  Created by 더스틴 on 8/14/26.
//

import Dependencies
@preconcurrency import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

extension GroupClient: nonisolated DependencyKey {
    static let entryCode: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    static let groupsString: String = "groups"
    static let codeString: String = "code"
    static let memberIDsString: String = "memberIDs"
    static let maxAttempts: Int = 5
    
    nonisolated static let liveValue: GroupClient = {
        let db = Firestore.firestore()
        
        @Sendable func generateCode() -> String {
            String((0..<6).map { _ in entryCode.randomElement()! })
        }
        
        @Sendable func codeExists(_ code: String) async throws -> Bool {
            let snapshot = try await createSnapshot(code: code)
            return !snapshot.documents.isEmpty
        }
        
        @Sendable func createSnapshot(code: String) async throws -> QuerySnapshot {
            try await db.collection(groupsString)
                .whereField(codeString, isEqualTo: code)
                .limit(to: 1)
                .getDocuments()
        }
        
        @Sendable func getUID() throws -> String {
            guard let uid = Auth.auth().currentUser?.uid else {
                throw GroupError.notSignedIn
            }
            return uid
        }
        
        return GroupClient(
            createGroup: {
                let uid = try getUID()
                var code = String((0..<6).map { _ in entryCode.randomElement()! })
                while try await codeExists(code) {
                    code = generateCode()
                }
                
                let group = Group(enterCode: code, memberIds: [uid], createdAt: Date())
                _ = try db.collection(groupsString).addDocument(from: group)
                return code
            },
            
            enterGroup: { enterCode in
                let uid = try getUID()
                let snapshot = try await createSnapshot(code: enterCode)
                
                guard let doc = snapshot.documents.first else {
                    throw GroupError.notFound
                }
                
                try await doc.reference.updateData([
                    memberIDsString: FieldValue.arrayUnion([uid])
                ])
                
                return doc.documentID
            },
            
            withdrawGroup: { groupID in
                let uid = try getUID()
                try await db.collection(groupsString).document(groupID).updateData([
                    memberIDsString: FieldValue.arrayRemove([uid])
                ])
            }
        )
    }()
}
