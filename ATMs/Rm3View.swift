//
//  Rm3View.swift
//  ATMs
//  code to commit
//  Created by User on 12.09.2026.
//

import SwiftUI
import Combine
import AVKit
import PDFKit

struct Rm3Item: Identifiable {
    let id = UUID()
    let code: String
    let col1: String
    let col2: String
    let col5: String
}

struct Rm3View: View {
    @State private var searchText: String = ""
    @State private var searchedQuery: String = ""
    @State private var filteredItems: [Rm3Item] = []
    @State private var isLoading: Bool = false
    @State private var hasSearched: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var selectedVideo: IdentifiableItem?
    @State private var selectedImage: IdentifiableItem?
    @State private var selectedPDF: IdentifiableItem?
    
    enum Field: Hashable {
        case search
    }
    
    @FocusState private var isSearchFocused: Field?

    var body: some View {
        ZStack {
            
            Color.neuBackground
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        headerIconView
                        
                        Text("RM3 Diagnostics")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))

                        searchSection(proxy: proxy)

                        if hasSearched {
                            resultsSection
                        }

                        linksSection

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 30 : 110)
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
        .sheet(item: $selectedVideo) { item in
            videoModalView(item: item)
        }
        .sheet(item: $selectedImage) { item in
            imageModalView(item: item)
        }
        .sheet(item: $selectedPDF) { item in
            pdfModalView(item: item)
        }
    }
    
    // MARK: - Винесені компоненти для розвантаження компілятора
    
    private var headerIconView: some View {
        ZStack {
            
            Circle()
                .fill(Color.neuBackground)
                .frame(width: 90, height: 90)
                .neumorphicShadow()
            
            
            Image(systemName: "cpu.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
        }
        .padding(.top, 20)
    }

    private func searchSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.black.opacity(0.4))
                .padding(.leading, 12)

            TextField("код помилки", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Color.black.opacity(0.8))
                .focused($isSearchFocused, equals: .search)
                .id(Field.search)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchedQuery = ""
                    hasSearched = false
                    filteredItems = []
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
        .onChange(of: isSearchFocused) { _, target in
            if target != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(Field.search, anchor: .center)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("РЕЗУЛЬТАТИ ПОШУКУ (\(filteredItems.count))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.black.opacity(0.4))
                .padding(.horizontal, 4)

            if isLoading {
                ProgressView("Завантаження rm3old.csv...")
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

                            if item.col1 != "—" {
                                Text(item.col1)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color.black.opacity(0.8))
                            }
                            
                            if item.col2 != "—" {
                                Text(item.col2)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.black.opacity(0.7))
                            }

                            if item.col5 != "—" {
                                Text(item.col5)
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

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ІНСТРУКЦІЇ ТА СХЕМИ")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.black.opacity(0.4))
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                NeuRow(title: "Поповнення на ескроу", icon: "play.circle.fill", iconColor: .blue) {
                    selectedVideo = IdentifiableItem(id: "cashintoescrow", title: "Тест RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "Видача коштів", icon: "play.circle.fill", iconColor: .blue) {
                    selectedVideo = IdentifiableItem(id: "cashout", title: "Тест RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "З ескроу в сейф", icon: "play.circle.fill", iconColor: .blue) {
                    selectedVideo = IdentifiableItem(id: "escrowtosafe", title: "Тест RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "Датчики RM3", icon: "sensor.fill", iconColor: .orange) {
                    selectedImage = IdentifiableItem(id: "rm3img", title: "Датчики RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "Інструкція з облуговування RM3", icon: "doc.richtext.fill", iconColor: .red) {
                    selectedPDF = IdentifiableItem(id: "rm3service", title: "Інструкція RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "Встановлення ел. замку", icon: "doc.richtext.fill", iconColor: .red) {
                    selectedPDF = IdentifiableItem(id: "zamok", title: "Інструкція RM3")
                }
                
                Divider().padding(.horizontal, 16)
                
                NeuRow(title: "Додаткове живлення ел. замку", icon: "doc.richtext.fill", iconColor: .red) {
                    selectedPDF = IdentifiableItem(id: "zampower", title: "Інструкція RM3")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.neuBackground)
                    .neumorphicShadow()
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Модальні вікна без зайвого if let для неопціонального String
    
    private func videoModalView(item: IdentifiableItem) -> some View {
        NavigationStack {
            ZStack {
                let id = item.id
                if let url = Bundle.main.url(forResource: id, withExtension: "mp4") {
                    VideoPlayer(player: AVPlayer(url: url))
                        .edgesIgnoringSafeArea(.all)
                } else {
                    ContentUnavailableView("Відео не знайдено", systemImage: "video.slash", description: Text("Додайте файл у бандл проєкту"))
                }
            }
            .navigationTitle(item.title ?? "Відео")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func imageModalView(item: IdentifiableItem) -> some View {
        NavigationStack {
            ZStack {
                Color.neuBackground
                    .ignoresSafeArea()
                
                let id = item.id
                ZoomableImageView(imageName: id)
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

    private func pdfModalView(item: IdentifiableItem) -> some View {
        NavigationStack {
            ZStack {
                Color.neuBackground
                    .ignoresSafeArea()
                
                let id = item.id
                if let url = Bundle.main.url(forResource: id, withExtension: "pdf") {
                    PDFKitRepresentable(url: url)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView("PDF файл не знайдено", systemImage: "doc.slash", description: Text("Додайте файл у бандл проєкту"))
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

    // MARK: - Методи пошуку та CSV
    
    func performSearch() {
        hideKeyboard()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        searchedQuery = query
        hasSearched = true
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let results = searchInCsvUniversal(fileName: "rm3old", query: query)
            DispatchQueue.main.async {
                self.filteredItems = results
                self.isLoading = false
            }
        }
    }

    func searchInCsvUniversal(fileName: String, query: String) -> [Rm3Item] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            return []
        }
         
        var content: String = ""
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            do {
                content = try String(contentsOfFile: path, encoding: .windowsCP1251)
            } catch {
                return []
            }
        }
         
        let lines = content.components(separatedBy: .newlines)
        var items: [Rm3Item] = []
         
        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
             
            let separator: Character = line.contains(";") ? ";" : ","
            let columns = line.components(separatedBy: String(separator))
             
            guard let rawCode = columns.first else { continue }
            let code = rawCode
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))
             
            if code.localizedCaseInsensitiveContains(query) {
                let cleanCell: (Int) -> String = { index in
                    guard columns.indices.contains(index) else { return "—" }
                    let val = columns[index]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))
                    return val.isEmpty ? "—" : val
                }
                 
                let item = Rm3Item(
                    code: code,
                    col1: cleanCell(1),
                    col2: cleanCell(2),
                    col5: cleanCell(5)
                )
                items.append(item)
            }
        }
        return items
    }
}
