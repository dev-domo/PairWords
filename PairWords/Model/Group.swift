//
//  Group.swift
//  PairWords
//
//  Created by 더스틴 on 8/11/26.
//

import FirebaseFirestore

struct Group: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var code: String
    var memberIds: [String]
    var createdAt: Date
}
