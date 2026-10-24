//
//  ATMsApp.swift
//  ATMs
//
//  Created by User on 10.09.2026.
//

import SwiftUI
import SwiftData

@main
struct ATMsApp: App {
    // Зчитуємо стан авторизації на найвищому рівні додатку
    @AppStorage("isAuthorized") private var isAuthorized: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isAuthorized {
                    // Якщо вже входили раніше — одразу завантажуємо довідник
                    MainTabView()
                } else {
                    // Якщо входу ще не було — показуємо екран авторизації
                    login()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
