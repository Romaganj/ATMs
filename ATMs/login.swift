//
//  login.swift
//  ATMs
//
//  Created by User on 10.09.2026.
//

import SwiftUI

struct login: View {
    // Зберігаємо стан авторизації у пам'яті пристрою між запусками програми
    @AppStorage("isAuthorized") private var isAuthorized: Bool = false
    
    // Змінна для зберігання введеного пароля
    @State private var passwordInput: String = ""
    
    // Прапорець показу помилки
    @State private var showError: Bool = false
    
    // Фокус для клавіатури
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        ZStack {
            Color.neuBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isPasswordFocused = false
                }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                   
                    // MARK: - Логотип / Іконка
                    ZStack {
                        Circle()
                            .fill(Color.neuBackground)
                            .frame(width: 110, height: 110)
                            .neumorphicShadow()
                           
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.18))
                    }
                   
                    Spacer().frame(height: 28)
                   
                    // MARK: - Заголовки
                    Text("Авторизація")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                   
                    Spacer().frame(height: 8)
                   
                    Text("Введіть пароль для доступу")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.4))
                   
                    Spacer().frame(height: 40)
                   
                    // MARK: - Поле вводу пароля
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.leading, 12)
                          
                        SecureField("••••••••", text: $passwordInput)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .keyboardType(.numberPad)
                            .foregroundColor(Color.black.opacity(0.8))
                            .focused($isPasswordFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                validatePassword()
                            }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.neuBackground)
                            .neumorphicShadow()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(showError ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)
                   
                    // Повідомлення про помилку
                    if showError {
                        Spacer().frame(height: 12)
                        Text("Невірний пароль! Спробуйте ще.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.red.opacity(0.8))
                            .transition(.opacity)
                    }
                   
                    Spacer().frame(height: 28)
                   
                    // MARK: - Кнопка Входу
                    Button(action: validatePassword) {
                        Text("УВІЙТИ")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                    .neumorphicShadow()
                            )
                    }
                    .padding(.horizontal, 24)
                   
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    // MARK: - Логіка перевірки пароля
    private func validatePassword() {
        isPasswordFocused = false
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyy"
        let currentPassword = formatter.string(from: Date())
         
        if passwordInput == currentPassword {
            withAnimation {
                showError = false
                // Зміна цього параметра миттєво переключить головний екран додатку на NcrView
                isAuthorized = true
            }
        } else {
            withAnimation {
                showError = true
            }
        }
    }
}

// MARK: - Розширення для кольорів та тіней

extension Color {
    static let neuBackground = Color(red: 0.90, green: 0.92, blue: 0.94)
}

extension View {
    func neumorphicShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 4, y: 4)
            .shadow(color: Color.white.opacity(0.8), radius: 6, x: -4, y: -4)
    }
}

// Залишаємо старі структури для сумісності з іншими файлами, якщо вони там використовуються
struct NeuBackground<S: Shape>: View {
    var isHighlighted: Bool = false
    var shape: S
    
    var body: some View {
        ZStack {
            if isHighlighted {
                shape
                    .fill(Color(.systemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                    .shadow(color: Color.white.opacity(0.7), radius: 4, x: -2, y: -2)
            } else {
                shape
                    .fill(Color(.systemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 5, y: 5)
                    .shadow(color: Color.white.opacity(0.7), radius: 8, x: -5, y: -5)
            }
        }
    }
}

extension View {
    func neuBackground<S: Shape>(isHighlighted: Bool = false, shape: S = RoundedRectangle(cornerRadius: 12)) -> some View {
        self.background(NeuBackground(isHighlighted: isHighlighted, shape: shape))
    }
}

#Preview {
    login()
}
