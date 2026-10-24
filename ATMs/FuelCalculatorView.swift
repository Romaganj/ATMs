//
//  FuelCalculatorView.swift
//  ATMs
//
//  Created by User on 12.09.2026.
//

import SwiftUI
import Combine

struct FuelCalculatorView: View {
    @State private var distanceStr: String = ""
    @State private var litersStr: String = ""
    @State private var targetDistanceStr: String = ""
    @State private var customConsumptionStr: String = ""
    @State private var pricePerLiterStr: String = ""

    @State private var keyboardHeight: CGFloat = 0

    enum Field: Hashable {
        case distance, liters, targetDistance, customConsumption, pricePerLiter
    }
    
    @FocusState private var focusedField: Field?

    var calculatedConsumption: Double {
        let dist = Double(distanceStr) ?? 0
        let liters = Double(litersStr) ?? 0
        guard dist > 0 else { return 0 }
        return (liters / dist) * 100
    }

    var fuelNeededForTrip: Double {
        let targetDist = Double(targetDistanceStr) ?? 0
        let consumption = Double(customConsumptionStr) ?? calculatedConsumption
        return (targetDist * consumption) / 100
    }

    var tripCost: Double {
        let price = Double(pricePerLiterStr) ?? 0
        return fuelNeededForTrip * price
    }

    var body: some View {
        ZStack {
            Color.neuBackground
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 12)
                        Text("Калькулятор пального")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.top, 20)

                        // БЛОК 1
                        VStack(alignment: .leading, spacing: 14) {
                            Text("1. Розрахунок поточної витрати")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black.opacity(0.7))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Пройдений кілометраж:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                NeuTextField(
                                    placeholder: "Наприклад: 600 (км)",
                                    text: $distanceStr,
                                    field: .distance,
                                    focusedField: $focusedField
                                )
                                .id(Field.distance)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Витрачено палива:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                NeuTextField(
                                    placeholder: "Наприклад: 48 (л)",
                                    text: $litersStr,
                                    field: .liters,
                                    focusedField: $focusedField
                                )
                                .id(Field.liters)
                            }

                            HStack {
                                Text("Середня витрата:")
                                    .foregroundColor(.black.opacity(0.6))
                                Spacer()
                                Text(String(format: "%.2f л / 100 км", calculatedConsumption))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.neuBackground)
                                .neumorphicShadow()
                        )
                        .padding(.horizontal, 20)

                        // БЛОК 2
                        VStack(alignment: .leading, spacing: 14) {
                            Text("2. Планування нової поїздки")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black.opacity(0.7))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Відстань майбутньої поїздки:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                NeuTextField(
                                    placeholder: "Наприклад: 350 (км)",
                                    text: $targetDistanceStr,
                                    field: .targetDistance,
                                    focusedField: $focusedField
                                )
                                .id(Field.targetDistance)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Витрата л/100км (якщо інша):")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                NeuTextField(
                                    placeholder: "Залишіть пустим для авто-розрахунку",
                                    text: $customConsumptionStr,
                                    field: .customConsumption,
                                    focusedField: $focusedField
                                )
                                .id(Field.customConsumption)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ціна за 1 літр пального:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                                NeuTextField(
                                    placeholder: "Наприклад: 55.5 (грн)",
                                    text: $pricePerLiterStr,
                                    field: .pricePerLiter,
                                    focusedField: $focusedField
                                )
                                .id(Field.pricePerLiter)
                            }

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Знадобиться палива:")
                                        .foregroundColor(.black.opacity(0.6))
                                    Spacer()
                                    Text(String(format: "%.2f л", fuelNeededForTrip))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                
                                if Double(pricePerLiterStr) ?? 0 > 0 {
                                    HStack {
                                        Text("Орієнтовна вартість:")
                                            .foregroundColor(.black.opacity(0.6))
                                        Spacer()
                                        Text(String(format: "%.2f грн", tripCost))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.neuBackground)
                                .neumorphicShadow()
                        )
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 40)
                    }
                    .frame(maxWidth: .infinity)
                    // Коли клавіатура відкрита, даємо запас під неї
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 30 : 110)
                    .onChange(of: focusedField) { oldValue, target in
                        if let target = target {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    proxy.scrollTo(target, anchor: .center) // або Field.search залежно від файлу
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            hideKeyboard()
        }
        .onReceive(Publishers.keyboardHeight) { height in
            self.keyboardHeight = height
        }
    }
}

struct NeuTextField: View {
    let placeholder: String
    @Binding var text: String
    let field: FuelCalculatorView.Field
    var focusedField: FocusState<FuelCalculatorView.Field?>.Binding

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .focused(focusedField, equals: field)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.neuBackground)
                    .neumorphicShadow()
            )
            .foregroundColor(.black)
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return 0 }
                return rect.height
            }
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

//#Preview {
//    FuelCalculatorView()
//}
