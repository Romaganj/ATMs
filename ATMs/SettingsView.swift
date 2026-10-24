//
//  SettingsView.swift
//  ATMs
//
//  Created by User on 12.09.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isAuthorized") private var isAuthorized: Bool = true

    var body: some View {
        ZStack {
            Color.neuBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    Text("Налаштування")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Spacer().frame(height: 40)
                    
                    // Кнопка виходу (скидання авторизації)
                    Button(action: {
                        isAuthorized = false
                    }) {
                        Text("Вийти з акаунта")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.red.opacity(0.8))
                                    .neumorphicShadow()
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 110)
            }
        }
    }
}

//#Preview {
//    SettingsView()
//}
