//
//  ContentView.swift
//  grade_calc
//
//  Created by Faraaz Ahmed on 11/3/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GradeViewModel()
    @State private var selectedCourse: Course? = nil
    @State private var showingAddCourse = false
    @State private var showingDeleteCourseAlert = false
    @State private var courseToDelete: IndexSet?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCourse) {
                ForEach(viewModel.courses) { course in
                    CourseRowView(course: course, viewModel: viewModel)
                }
                .onDelete { indexSet in
                    courseToDelete = indexSet
                    showingDeleteCourseAlert = true
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: {
                        showingAddCourse = true
                    }) {
                        Label("Add Course", systemImage: "folder.badge.plus")
                    }
                    
                    if let selectedCourse = selectedCourse {
                        Button(role: .destructive) {
                            if let index = viewModel.courses.firstIndex(where: { $0.id == selectedCourse.id }) {
                                courseToDelete = IndexSet([index])
                                showingDeleteCourseAlert = true
                            }
                        } label: {
                            Label("Delete Course", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Delete Course", isPresented: $showingDeleteCourseAlert) {
                Button("Cancel", role: .cancel) {
                    courseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let indexSet = courseToDelete {
                        if let index = indexSet.first,
                           index < viewModel.courses.count,
                           let courseToDelete = viewModel.courses[safe: index] {
                            if selectedCourse?.id == courseToDelete.id {
                                selectedCourse = nil
                            }
                        }
                        viewModel.deleteCourse(at: indexSet)
                    }
                    courseToDelete = nil
                }
            } message: {
                if let indexSet = courseToDelete,
                   let index = indexSet.first,
                   index < viewModel.courses.count,
                   let course = viewModel.courses[safe: index] {
                    Text("Are you sure you want to delete '\(course.name)'? This will delete all assignments and grades associated with this course.")
                }
            }
        } detail: {
            if let course = selectedCourse {
                CourseDetailView(course: course, viewModel: viewModel)
            } else {
                Text("Select a course")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingAddCourse) {
            AddCourseView(viewModel: viewModel)
                .frame(minWidth: 400, minHeight: 250)
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct CourseRowView: View {
    @ObservedObject var course: Course
    @ObservedObject var viewModel: GradeViewModel
    
    var body: some View {
        NavigationLink(value: course) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                Text("Current Grade: \(viewModel.calculateCurrentGrade(for: course), specifier: "%.1f")%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
}

struct CourseDetailView: View {
    @ObservedObject var course: Course
    @ObservedObject var viewModel: GradeViewModel
    @State private var showingAddAssignment = false
    @State private var editingAssignmentID: UUID?
    @State private var gradeText = ""
    @State private var refreshID = UUID()
    @State private var showingDeleteAlert = false
    @State private var assignmentToDelete: Assignment?
    
    private var editingAssignment: Binding<Bool> {
        Binding(
            get: { editingAssignmentID != nil },
            set: { if !$0 { editingAssignmentID = nil } }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Grade Summary Card
            VStack(spacing: 16) {
                HStack(spacing: 32) {
                    VStack {
                        Text("Current Grade")
                            .font(.headline)
                        Text("\(viewModel.calculateCurrentGrade(for: course), specifier: "%.1f")%")
                            .font(.system(size: 24, weight: .bold))
                    }
                    
                    VStack {
                        Text("Target Grade")
                            .font(.headline)
                        Text("\(course.targetGrade, specifier: "%.1f")%")
                            .font(.system(size: 24, weight: .bold))
                    }
                    
                    if let required = viewModel.calculateRequiredScore(for: course) {
                        VStack {
                            Text("Required Average")
                                .font(.headline)
                            Text("\(required, specifier: "%.1f")%")
                                .font(.system(size: 24, weight: .bold))
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Assignments Table
            Table(course.assignments) {
                TableColumn("Name") { (assignment: Assignment) in
                    Text(assignment.name)
                }
                TableColumn("Weight") { (assignment: Assignment) in
                    Text("\(assignment.weight, specifier: "%.1f")%")
                }
                TableColumn("Status") { (assignment: Assignment) in
                    HStack {
                        if assignment.isCompleted {
                            Text("\(assignment.score ?? 0, specifier: "%.1f")%")
                            Button("Edit") {
                                editingAssignmentID = assignment.id
                                gradeText = "\(assignment.score ?? 0)"
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        } else {
                            Button("Enter Score") {
                                editingAssignmentID = assignment.id
                                gradeText = ""
                            }
                        }
                        
                        Button(role: .destructive) {
                            assignmentToDelete = assignment
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
            }
            .tableStyle(.bordered)
            .id(refreshID)
            
            // Total Weight Warning
            let totalWeight = course.assignments.reduce(0) { $0 + $1.weight }
            if totalWeight > 100 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Total assignment weight exceeds 100% (\(totalWeight, specifier: "%.1f")%)")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if totalWeight < 100 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Total assignment weight: \(totalWeight, specifier: "%.1f")%")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddAssignment = true }) {
                    Label("Add Assignment", systemImage: "doc.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentView(course: course, viewModel: viewModel)
                .frame(minWidth: 400, minHeight: 250)
        }
        .sheet(isPresented: editingAssignment) {
            if let assignmentID = editingAssignmentID,
               let assignment = course.assignments.first(where: { $0.id == assignmentID }) {
                VStack(spacing: 20) {
                    Text("Enter Score")
                        .font(.headline)
                    
                    Text("Assignment: \(assignment.name)")
                        .foregroundColor(.secondary)
                    
                    TextField("Score (0-100)", text: $gradeText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .onSubmit {
                            saveScore(for: assignment)
                        }
                    
                    HStack {
                        Button("Cancel") {
                            editingAssignmentID = nil
                        }
                        
                        Button("Save") {
                            saveScore(for: assignment)
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(Double(gradeText) == nil ||
                                Double(gradeText)! < 0 ||
                                Double(gradeText)! > 100)
                    }
                }
                .padding()
                .frame(width: 300, height: 200)
            }
        }
        .alert("Delete Assignment",
               isPresented: $showingDeleteAlert,
               presenting: assignmentToDelete) { assignment in
            Button("Cancel", role: .cancel) {
                assignmentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    viewModel.deleteAssignment(assignment, from: course)
                    refreshID = UUID()
                }
                assignmentToDelete = nil
            }
        } message: { assignment in
            Text("Are you sure you want to delete '\(assignment.name)'? This action cannot be undone.")
        }
    }
    
    private func saveScore(for assignment: Assignment) {
        if let score = Double(gradeText),
           score >= 0 && score <= 100 {
            viewModel.updateAssignment(assignment, in: course, score: score)
            refreshID = UUID()
            editingAssignmentID = nil
            gradeText = ""
        }
    }
}

// Make sure to also update AddAssignmentView


struct AddCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GradeViewModel
    @State private var courseName = ""
    @State private var targetGrade = 90.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Course")
                .font(.title2)
                .padding(.top)
            
            Form {
                TextField("Course Name", text: $courseName)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading) {
                    Text("Target Grade: \(targetGrade, specifier: "%.0f")%")
                    Slider(value: $targetGrade, in: 0...100, step: 1)
                }
            }
            .padding()
            
            HStack {
                Button("Cancel") { dismiss() }
                
                Button("Add Course") {
                    viewModel.addCourse(name: courseName, targetGrade: targetGrade)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(courseName.isEmpty)
            }
            .padding(.bottom)
        }
    }
}

struct AddAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var course: Course
    @ObservedObject var viewModel: GradeViewModel
    @State private var assignmentName = ""
    @State private var weight = 10.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Assignment")
                .font(.title2)
                .padding(.top)
            
            Form {
                TextField("Assignment Name", text: $assignmentName)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading) {
                    Text("Weight: \(weight, specifier: "%.0f")%")
                    Slider(value: $weight, in: 0...100, step: 1)
                }
            }
            .padding()
            
            HStack {
                Button("Cancel") { dismiss() }
                
                Button("Add Assignment") {
                    viewModel.addAssignment(to: course, name: assignmentName, weight: weight)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(assignmentName.isEmpty)
            }
            .padding(.bottom)
        }
    }
}
