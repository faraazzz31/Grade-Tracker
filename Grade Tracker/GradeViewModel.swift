//
//  GradeViewModel.swift
//  grade_calc
//
//  Created by Faraaz Ahmed on 11/3/24.
//

import Foundation

class GradeViewModel: ObservableObject {
    @Published var courses: [Course] = []
    private let storageKey = "savedCourses"
    
    init() {
        loadCourses()
    }
    
    // MARK: - Course Management
    func addCourse(name: String, targetGrade: Double) {
        let newCourse = Course(
            id: UUID(),
            name: name,
            targetGrade: targetGrade,
            assignments: []
        )
        objectWillChange.send()
        courses.append(newCourse)
        saveCourses()
    }
    
    func deleteCourse(at indexSet: IndexSet) {
        courses.remove(atOffsets: indexSet)
        saveCourses()
    }
    
    // MARK: - Assignment Management
    func addAssignment(to course: Course, name: String, weight: Double) {
        let newAssignment = Assignment(
            id: UUID(),
            name: name,
            weight: weight,
            score: nil,
            isCompleted: false
        )
        
        course.objectWillChange.send()  // Notify before change
        course.assignments.append(newAssignment)
        objectWillChange.send()
        saveCourses()
    }
    
    func updateAssignment(_ assignment: Assignment, in course: Course, score: Double) {
        guard let index = course.assignments.firstIndex(where: { $0.id == assignment.id }) else { return }
        
        var updatedAssignment = assignment
        updatedAssignment.score = score
        updatedAssignment.isCompleted = true
        
        course.objectWillChange.send()  // Notify before change
        course.assignments[index] = updatedAssignment
        objectWillChange.send()
        saveCourses()
    }
    
    func deleteAssignment(_ assignment: Assignment, from course: Course) {
            course.objectWillChange.send()
            course.assignments.removeAll(where: { $0.id == assignment.id })
            objectWillChange.send()
            saveCourses()
        }
    
    // MARK: - Grade Calculations
    func calculateCurrentGrade(for course: Course) -> Double {
        let completedAssignments = course.assignments.filter { $0.isCompleted }
        let totalWeight = completedAssignments.reduce(0.0) { $0 + $1.weight }
        
        guard totalWeight > 0 else { return 0.0 }
        
        let weightedSum = completedAssignments.reduce(0.0) { sum, assignment in
            sum + (assignment.score ?? 0.0) * (assignment.weight / 100.0)
        }
        
        return (weightedSum / totalWeight) * 100.0
    }
    
    func calculateRequiredScore(for course: Course) -> Double? {
        let remaining = course.assignments.filter { !$0.isCompleted }
        let remainingWeight = remaining.reduce(0.0) { $0 + $1.weight }
        
        guard remainingWeight > 0 else { return nil }
        
        let currentGrade = calculateCurrentGrade(for: course)
        let completedWeight = course.assignments
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + $1.weight }
        
        let targetPoints = course.targetGrade * (completedWeight + remainingWeight) / 100.0
        let currentPoints = currentGrade * completedWeight / 100.0
        let neededPoints = targetPoints - currentPoints
        
        return (neededPoints / remainingWeight) * 100.0
    }
    
    // MARK: - Persistence
    private func saveCourses() {
        if let encoded = try? JSONEncoder().encode(courses) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadCourses() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Course].self, from: data) {
            courses = decoded
        }
    }
}
