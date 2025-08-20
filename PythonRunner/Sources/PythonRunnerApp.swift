// MARK: - App Entry Point

// File: PythonRunner/Sources/PythonRunnerApp.swift
import SwiftUI

@main
struct PythonRunnerApp: App {
    @StateObject private var pythonEngine = PythonEngine()

    init() {
        // Initialize Python on app launch
        Task {
            await PythonEngine.shared.initializePython()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pythonEngine)
        }
    }
}
