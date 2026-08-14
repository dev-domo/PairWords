//
//  Slang.swift
//  PairWords
//
//  Created by 더스틴 on 8/13/26.
//

import FirebaseFirestore

struct Slang: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let name: String
    let createdBy: String
    let createdAt: Date
}
