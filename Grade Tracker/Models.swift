//
//  Models.swift
//  grade_calc
//
//  Created by Faraaz Ahmed on 11/3/24.
//

import Foundation

class Course: Identifiable, Codable, ObservableObject, Hashable {
    let id: UUID
    var name: String
    var targetGrade: Double
    @Published var assignments: [Assignment] {
        didSet {
            objectWillChange.send()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, targetGrade, assignments
    }
    
    init(id: UUID = UUID(), name: String, targetGrade: Double, assignments: [Assignment] = []) {
        self.id = id
        self.name = name
        self.targetGrade = targetGrade
        self.assignments = assignments
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        targetGrade = try container.decode(Double.self, forKey: .targetGrade)
        assignments = try container.decode([Assignment].self, forKey: .assignments)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(targetGrade, forKey: .targetGrade)
        try container.encode(assignments, forKey: .assignments)
    }
    
    // MARK: - Hashable Implementation
    static func == (lhs: Course, rhs: Course) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Assignment: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var weight: Double
    var score: Double?
    var isCompleted: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        lhs.id == rhs.id
    }
}
