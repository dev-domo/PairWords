//
//  Recording.swift
//  PairWords
//
//  Created by 더스틴 on 8/13/26.
//

import FirebaseFirestore

struct Recording: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var audioURL: String
    var createdBy: String
    var createdAt: Date
}
