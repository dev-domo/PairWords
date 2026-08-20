//
//  EquatableError.swift
//  PairWords
//
//  Created by 더스틴 on 8/20/26.
//

struct EquatableError: Error, Equatable {
    let base: Error

    init(_ base: Error) {
        self.base = base
    }

    static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
        String(reflecting: lhs.base) == String(reflecting: rhs.base)
    }
}
