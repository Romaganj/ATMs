import SwiftUI
import Combine

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NcrView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(0)
                
                Rm3View()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(1)
                
                FuelCalculatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(2)
                
                BarcodeScannerView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(3)
                
                SettingsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Меню ховається при відкритті клавіатури, звільняючи простір для скролу
            if keyboardHeight == 0 {
                CustomBottomBar(selectedTab: $selectedTab)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
        .onReceive(Publishers.keyboardHeight) { height in
            self.keyboardHeight = height
        }
    }
}

// MARK: - Нижнє меню на 4 вкладки
struct CustomBottomBar: View {
    @Binding var selectedTab: Int

    var body: some View {
            HStack(spacing: 0) {
                TabButton(title: "NCR", icon: "cpu.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "RM3", icon: "doc.text.fill", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Паливо", icon: "fuelpump.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                // Додано кнопку для сканера
                TabButton(title: "Сканер", icon: "barcode.viewfinder", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
                TabButton(title: "Налаштування", icon: "gearshape.fill", isSelected: selectedTab == 4) {
                    selectedTab = 4
                }
            }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.neuBackground)
                .neumorphicShadow()
        )
        .padding(.horizontal, 16)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color.black.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
    }
}
