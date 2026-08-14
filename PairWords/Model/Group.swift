//
//  Group.swift
//  PairWords
//
//  Created by 더스틴 on 8/11/26.
//

import FirebaseFirestore

struct Group: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let enterCode: String
    var memberIds: [String]
    let createdAt: Date
}
