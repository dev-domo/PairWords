//
//  Slang.swift
//  PairWords
//
//  Created by 더스틴 on 8/13/26.
//

@preconcurrency import FirebaseFirestore

struct Slang: Codable, Identifiable, Equatable, Sendable {
    @DocumentID var id: String?
    let name: String
    let representativeMeaning: String
    let createdBy: String
    let createdAt: Date
}
