//
//  Meaning.swift
//  PairWords
//
//  Created by 더스틴 on 8/13/26.
//

import FirebaseFirestore

struct Meaning: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var text: String
    var createdBy: String
    var createdAt: Date
}
