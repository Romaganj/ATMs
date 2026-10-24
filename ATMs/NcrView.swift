//
//  NcrView.swift
//  ATMs
//

import SwiftUI
import AVKit
import UIKit
import PDFKit

struct NCRErrorItem: Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let solution: String
}

struct IdentifiableItem: Identifiable {
    let id: String
    var title: String? = nil
}

struct NcrView: View {
    // Змінна для виходу з акаунту (якщо знадобиться кнопка «Вийти»)
    @AppStorage("isAuthorized") private var isAuthorized: Bool = true
    
    @State private var allItems: [NCRErrorItem] = []
    @State private var searchText: String = ""
    @State private var searchedQuery: String = ""
    @State private var hasSearched: Bool = false
    @State private var isLoading: Bool = true
    
    // Стани для CRC32 калькулятора
    @State private var crcInput: String = ""
    
    // Фокус для керування клавіатурою
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isCrcFocused: Bool
    
    // Стани для модальних вікон інструкцій та медіа
    @State private var selectedVideo: IdentifiableItem? = nil
    @State private var selectedImage: IdentifiableItem? = nil
    @State private var selectedPDF: IdentifiableItem? = nil

    var filteredItems: [NCRErrorItem] {
        guard hasSearched else { return [] }
        let query = searchedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return [] }
        
        return allItems.filter { item in
            item.code.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query) ||
            item.solution.localizedCaseInsensitiveContains(query)
        }
    }
    
    var calculatedCRC32: String {
        let trimmed = crcInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "00000000" }
        return calculateCRC32(for: trimmed)
    }

    var body: some View {
        ZStack {
            Color.neuBackground
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 10)
                    Image("stimul")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                            .padding(.top, 12)
                                            .padding(.bottom, 12)
                    Spacer().frame(height: 5)

                    // MARK: - Пошуковий рядок
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.leading, 12)

                        TextField("", text: $searchText, prompt: Text("код помилки").foregroundColor(.black.opacity(0.6)))
                            .font(.system(size: 16))
                            .foregroundColor(Color.black.opacity(0.8))
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                performSearch()
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchedQuery = ""
                                hasSearched = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.black.opacity(0.4))
                            }
                        }

                        Button(action: performSearch) {
                            Text("Пошук")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                )
                        }
                        .padding(.trailing, 4)
                    }
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.neuBackground)
                            .neumorphicShadow()
                    )
                    .padding(.horizontal, 24)

                    // MARK: - Результати пошуку
                    if hasSearched {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("РЕЗУЛЬТАТИ ПОШУКУ (\(filteredItems.count))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.black.opacity(0.4))
                                .padding(.horizontal, 4)

                            if isLoading {
                                ProgressView("Завантаження ncrall.csv...")
                                    .padding(.top, 20)
                            } else if filteredItems.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundColor(Color.black.opacity(0.3))
                                    Text("Нічого не знайдено за запитом \"\(searchedQuery)\"")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.black.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.neuBackground)
                                        .neumorphicShadow()
                                )
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(filteredItems) { item in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(item.code)
                                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                                    )
                                                Spacer()
                                            }

                                            Text(item.description)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color.black.opacity(0.8))

                                            if !item.solution.isEmpty {
                                                Text(item.solution)
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(Color.black.opacity(0.5))
                                            }
                                        }
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.neuBackground)
                                                .neumorphicShadow()
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // MARK: - Кнопки інструкцій та схем
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ІНСТРУКЦІЇ ТА СХЕМИ")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            NeuRow(title: "Відео тесту NCR", icon: "play.circle.fill", iconColor: .blue) {
                                selectedVideo = IdentifiableItem(id: "ncrtest", title: "Тест NCR")
                            }
                            
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Поповнення / зняття тест", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "ncrtest", title: "Інструкція NCR")
                            }
                            
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Датчики Upper (Верхні)", icon: "sensor.fill", iconColor: .green) {
                                selectedImage = IdentifiableItem(id: "uppersensor", title: "Схема Upper Sensor")
                            }
                            
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Датчики Lower (Нижні)", icon: "sensor.fill", iconColor: .orange) {
                                selectedImage = IdentifiableItem(id: "lowersensor", title: "Схема Lower Sensor")
                            }
                            
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Антискімінг NCR ", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "antiskimncr", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Криптування NCR", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "encryptncr", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "EPP ковпачок", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "eppncr", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Прошивка контроллера", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "firmwarencr", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Монтаж стабілізатору", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "install2062_2064", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Проміжний транспорт NCR", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "Intermadiate", title: "Інструкція NCR")
                            }
                            Divider().padding(.horizontal, 16)
                            
                            NeuRow(title: "Сервісні зони АТМ", icon: "doc.richtext.fill", iconColor: .red) {
                                selectedPDF = IdentifiableItem(id: "servicezone", title: "Інструкція NCR")
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.neuBackground)
                                .neumorphicShadow()
                        )
                    }
                    .padding(.horizontal, 24)

                    // MARK: - CRC32 Калькулятор
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CRC32 КАЛЬКУЛЯТОР")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.horizontal, 4)

                        VStack(spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "number")
                                    .foregroundColor(Color.black.opacity(0.4))
                                    .padding(.leading, 4)

                                TextField("Введіть текст для CRC32...", text: $crcInput)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .focused($isCrcFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        hideKeyboard()
                                    }

                                if !crcInput.isEmpty {
                                    Button(action: { crcInput = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.black.opacity(0.4))
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.neuBackground)
                                    .neumorphicShadow()
                            )

                            HStack {
                                Text("Результат (тап щоб скопіювати):")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.black.opacity(0.6))
                                
                                Spacer()

                                Text(calculatedCRC32)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(red: 0.17, green: 0.17, blue: 0.18))
                                    )
                                    .onTapGesture {
                                        UIPasteboard.general.string = calculatedCRC32
                                    }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.neuBackground)
                                .neumorphicShadow()
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 110)
                    
                    Spacer().frame(height: 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // 🔒 ПОВНІСТЮ ПРИХОВУЄМО КНОПКУ «НАЗАД», ОСКІЛКИ ЦЕ КОРІНЕВИЙ ЕКРАН
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    hideKeyboard()
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .task {
            loadNCRCSV()
        }
        .sheet(item: $selectedVideo) { item in
            NavigationStack {
                ZStack {
                    if let url = Bundle.main.url(forResource: item.id, withExtension: "mp4") {
                        VideoPlayer(player: AVPlayer(url: url))
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ContentUnavailableView("Відео не знайдено", systemImage: "video.slash", description: Text("Додайте файл \(item.id).mp4 у бандл проєкту"))
                    }
                }
                .navigationTitle(item.title ?? "Відео")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(item: $selectedImage) { item in
            NavigationStack {
                ZStack {
                    Color.neuBackground
                        .ignoresSafeArea()
                    
                    ZoomableImageView(imageName: item.id)
                        .ignoresSafeArea(edges: .bottom)
                }
                .navigationTitle(item.title ?? "Схема")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Закрити") {
                            selectedImage = nil
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
        .sheet(item: $selectedPDF) { item in
            NavigationStack {
                ZStack {
                    Color.neuBackground
                        .ignoresSafeArea()
                    
                    if let url = Bundle.main.url(forResource: item.id, withExtension: "pdf") {
                        PDFKitRepresentable(url: url)
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        ContentUnavailableView("PDF файл не знайдено", systemImage: "doc.slash", description: Text("Додайте файл \(item.id).pdf у бандл проєкту"))
                    }
                }
                .navigationTitle(item.title ?? "Документація")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Закрити") {
                            selectedPDF = nil
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
        isSearchFocused = false
        isCrcFocused = false
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        hideKeyboard()
        if !trimmed.isEmpty {
            searchedQuery = trimmed
            hasSearched = true
        }
    }

    private func calculateCRC32(for string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "00000000" }
        
        let crcTable: [UInt32] = (0..<256).map { i in
            var crc = UInt32(i)
            for _ in 0..<8 {
                if (crc & 1) != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc >>= 1
                }
            }
            return crc
        }
        
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crcTable[index]
        }
        
        return String(format: "%08X", ~crc)
    }

    private func loadNCRCSV() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let path = Bundle.main.path(forResource: "ncrall", ofType: "csv") else {
                print("❌ Файл ncrall.csv не знайдено в бандлі!")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                let rows = content.components(separatedBy: .newlines)
                var parsedItems: [NCRErrorItem] = []

                for row in rows {
                    let columns = row.components(separatedBy: ";")
                    
                    if columns.count >= 2 {
                        let code = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let description = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let solution = columns.count >= 3 ? columns[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                        
                        if !code.isEmpty {
                            parsedItems.append(NCRErrorItem(code: code, description: description, solution: solution))
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.allItems = parsedItems
                    self.isLoading = false
                    print("✅ Успішно завантажено \(parsedItems.count) записів з ncrall.csv")
                }
            } catch {
                print("❌ Помилка читання ncrall.csv: \(error)")
                DispatchQueue.main.async { self.isLoading = false }
            }
        }
    }
}

// Дوпоміжні компоненти залишаються незмінними...
struct ZoomableImageView: UIViewRepresentable {
    let imageName: String
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear

        let img = UIImage(named: imageName) ?? UIImage(systemName: "photo") ?? UIImage()
        let imageView = UIImageView(image: img)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
    }
}

struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.clear
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct NeuRow: View {
    let title: String
    let icon: String
    var iconColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.8))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.black.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
