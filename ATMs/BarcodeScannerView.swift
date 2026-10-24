//
//  BarcodeScannerView.swift
//  ATMs
//
//  Created by User on 12.09.2026.
//

import SwiftUI
import AVFoundation
import Combine

struct BarcodeScannerView: View {
    // Структура для елементів історії
    struct ScannedItem: Identifiable, Equatable {
        let id = UUID()
        let code: String
        let timestamp: Date
    }

    @State private var recentItems: [ScannedItem] = []     // Усі нещодавні скани (перший елемент — останній)
    @State private var selectedCodes: [String] = []       // Коди, які користувач додав у фінальний список
    @State private var showCopiedAlert: Bool = false      // Флаг для сповіщення про копіювання
    
    // Таймер для очищення старих елементів через 15 секунд
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.neuBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок
                    Text("Сканер штрихкодів")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.top, 20)

                    // БЛОК 1: Вікно камери
                    ZStack {
                        BarcodeScannerRepresentable { code in
                            handleNewScannedCode(code)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Декоративна рамка-приціл
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.7), lineWidth: 3)
                            .frame(width: 260, height: 120)
                            .allowsHitTesting(false)
                    }
                    .frame(height: 240)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.neuBackground)
                            .neumorphicShadow()
                    )
                    .padding(.horizontal, 20)

                    // БЛОК 2: Знайдені кадрою коди (Останній у салатовому, решта нижче з таймером 15 сек)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Знайдені камерою:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.6))

                        if recentItems.isEmpty {
                            Text("Наведіть камеру на штрихкод чи QR-код...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.black.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.neuBackground)
                                        .neumorphicShadow()
                                )
                        } else {
                            // 1. НАЙСВІЖІШИЙ КОД (Салатовий фон)
                            if let latestItem = recentItems.first {
                                Button(action: {
                                    addCodeToSelected(latestItem.code)
                                }) {
                                    HStack {
                                        Image(systemName: "barcode.viewfinder")
                                            .foregroundColor(.green.opacity(0.8))
                                            .font(.system(size: 18))
                                        Text(latestItem.code)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black.opacity(0.85))
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text("Додати")
                                                .font(.system(size: 13, weight: .bold))
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 18))
                                        }
                                        .foregroundColor(.green)
                                    }
                                    .padding(14)
                                    // САЛАТОВИЙ КОНТЕЙНЕР
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.green.opacity(0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                                            )
                                    )
                                }
                            }

                            // 2. ПОПЕРЕДНІ КОДИ (Зникають через 15 сек)
                            if recentItems.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Попередні (зникають через 15 сек):")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.black.opacity(0.4))
                                        .padding(.top, 4)

                                    // Беремо всі елементи, окрім першого (бо перший вже зверху в салатовому)
                                    ForEach(recentItems.dropFirst()) { item in
                                        Button(action: {
                                            addCodeToSelected(item.code)
                                        }) {
                                            HStack {
                                                Image(systemName: "barcode")
                                                    .foregroundColor(.gray)
                                                Text(item.code)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.black.opacity(0.7))
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.green.opacity(0.7))
                                            }
                                            .padding(10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.neuBackground)
                                                    .neumorphicShadow()
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.neuBackground)
                            .neumorphicShadow()
                    )
                    .padding(.horizontal, 20)

                    // БЛОК 3: Список вибраних кодів для відправки
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Обрані коди (\(selectedCodes.count)):")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.6))
                            Spacer()
                            if !selectedCodes.isEmpty {
                                Button("Очистити") {
                                    selectedCodes.removeAll()
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            if selectedCodes.isEmpty {
                                Text("Ще не обрано жодного коду")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(selectedCodes, id: \.self) { item in
                                    HStack {
                                        Text("• \(item)")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.black.opacity(0.8))
                                        Spacer()
                                        Button(action: {
                                            selectedCodes.removeAll { $0 == item }
                                        }) {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // Кнопка копіювання
                        Button(action: {
                            let textToCopy = selectedCodes.joined(separator: "\n")
                            UIPasteboard.general.string = textToCopy
                            showCopiedAlert = true
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Скопіювати та переслати")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedCodes.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                            )
                        }
                        .disabled(selectedCodes.isEmpty)
                        .padding(.top, 6)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.neuBackground)
                            .neumorphicShadow()
                    )
                    .padding(.horizontal, 20)
                    
                    // Запас простору знизу від плаваючого меню
                    Spacer().frame(height: 120)
                }
            }
        }
        // Щосекунди перевіряємо час життя елементів: видаляємо ті, що старіші за 15 секунд
        .onReceive(timer) { _ in
            let now = Date()
            recentItems.removeAll { item in
                // Не видаляємо найсвіжіший елемент (перший у списку), щоб він не зникав перед очима
                if item == recentItems.first { return false }
                return now.timeIntervalSince(item.timestamp) > 15.0
            }
        }
        .alert("Скопійовано!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Вибрані коди скопійовано до буфера обміну. Тепер їх можна вставити в будь-який месенджер.")
        }
    }

    private func handleNewScannedCode(_ code: String) {
        // Якщо цей код вже є найпершим (щойно зчитаним), не дублюємо його щомиті
        if recentItems.first?.code == code { return }

        // Якщо такий код вже є десь у списку нижче — видаляємо його звідти, щоб підняти наверх як найсвіжіший
        recentItems.removeAll { $0.code == code }

        let newItem = ScannedItem(code: code, timestamp: Date())
        recentItems.insert(newItem, at: 0) // Ставимо на початок (у салатовий блок)

        // Обмежуємо історію максимум 6 елементами загалом
        if recentItems.count > 6 {
            recentItems.removeLast()
        }

        // Вібрація припійку нового штрихкоду
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func addCodeToSelected(_ code: String) {
        if !selectedCodes.contains(code) {
            selectedCodes.append(code)
            
            // Легкий відгук
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - Підключення нативного AVFoundation сканера
struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewControllerInternal {
        let controller = ScannerViewControllerInternal()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewControllerInternal, context: Context) {}
}

class ScannerViewControllerInternal: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?
    private var lastScannedTime: Date = .distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .qr, .ean13, .ean8, .code128, .code39, .code93, .pdf417, .upce
            ]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = view.layer.bounds
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            // Захист від спаму подій (фіксуємо не частіше ніж раз на 0.4 сек)
            if Date().timeIntervalSince(lastScannedTime) > 0.4 {
                lastScannedTime = Date()
                onCodeScanned?(stringValue)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
    }
}
