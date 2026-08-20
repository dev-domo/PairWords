//
//  Meaning.swift
//  PairWords
//
//  Created by 더스틴 on 8/13/26.
//

@preconcurrency import FirebaseFirestore

struct Meaning: Codable, Identifiable, Equatable, Sendable {
    @DocumentID var id: String?
    let text: String
    let createdBy: String
    let createdAt: Date
}
