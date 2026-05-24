import SwiftUI
import PhotosUI
import UIKit

struct SolveView: View {
    @EnvironmentObject var store: StoreManager
    @ObservedObject var history: MathHistoryStore
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var solution: MathSolution?
    @State private var isThinking = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var showSolution = false
    @State private var orbPulse = false
    @State private var floatingSymbols: [FloatingSymbol] = []
    @State private var orbScale: CGFloat = 1.0

    struct FloatingSymbol: Identifiable {
        let id = UUID()
        let symbol: String
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var scale: CGFloat
    }

    private let mathSymbols = ["∫", "∑", "π", "√", "∞", "Δ", "θ", "λ", "±", "≈", "∂", "∇"]

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            backgroundGlow

            // Floating math symbols when thinking
            ForEach(floatingSymbols) { sym in
                Text(sym.symbol)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.appAccent.opacity(sym.opacity))
                    .scaleEffect(sym.scale)
                    .position(x: sym.x, y: sym.y)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    orbSection
                    if let img = capturedImage {
                        capturedImageSection(img)
                    }
                    if isThinking {
                        thinkingSection
                    } else if let sol = solution, showSolution {
                        solutionSection(sol)
                    }
                    if let err = errorMessage {
                        errorSection(err)
                    }
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView { img in
                capturedImage = img
                showCamera = false
                Task { await solve(image: img) }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    capturedImage = img
                    await solve(image: img)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(store) }
        .onAppear { startOrbPulse() }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("SnapMath")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [.white, Color(hex: "B0BDD4")],
                    startPoint: .top, endPoint: .bottom
                ))
            Text("Snap a photo. Get instant solutions.")
                .font(.system(size: 15)).foregroundStyle(Color.appMuted)
        }
    }

    private var orbSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow rings
                Circle()
                    .stroke(Color.appAccent.opacity(0.06), lineWidth: 1)
                    .frame(width: 220, height: 220)
                    .scaleEffect(orbPulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: orbPulse)

                Circle()
                    .stroke(Color.appAccent.opacity(0.12), lineWidth: 1)
                    .frame(width: 185, height: 185)
                    .scaleEffect(orbPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: orbPulse)

                // Main orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.appAccent.opacity(0.25), Color.appAccent.opacity(0.05)],
                                center: .center, startRadius: 10, endRadius: 75
                            )
                        )
                        .frame(width: 150, height: 150)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.6), Color.appAccent.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 150, height: 150)

                    if isThinking {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.appAccent)
                            .scaleEffect(1.5)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: capturedImage == nil ? "camera.fill" : "arrow.clockwise")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                                .shadow(color: Color.appAccent.opacity(0.5), radius: 12)
                            Text(capturedImage == nil ? "Snap" : "Retry")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .scaleEffect(orbScale)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: orbScale)
            }
            .frame(height: 240)
            .onTapGesture {
                Haptics.impact(.medium)
                orbScale = 0.92
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { orbScale = 1.0 }
                if !store.isPro {
                    let uses = UserDefaults.standard.integer(forKey: "monthly_uses")
                    if uses >= StoreManager.freeUsesPerMonth {
                        showPaywall = true; return
                    }
                }
                showCamera = true
            }

            HStack(spacing: 16) {
                Button {
                    Haptics.impact(.light)
                    if !store.isPro {
                        let uses = UserDefaults.standard.integer(forKey: "monthly_uses")
                        if uses >= StoreManager.freeUsesPerMonth { showPaywall = true; return }
                    }
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Color.appAccent.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                }

                Button {
                    Haptics.impact(.light)
                    if !store.isPro {
                        let uses = UserDefaults.standard.integer(forKey: "monthly_uses")
                        if uses >= StoreManager.freeUsesPerMonth { showPaywall = true; return }
                    }
                    showImagePicker = true
                } label: {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Color.appSurface, in: Capsule())
                        .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1))
                }
            }
            .buttonStyle(.plain)

            if !store.isPro {
                let uses = UserDefaults.standard.integer(forKey: "monthly_uses")
                let remaining = max(0, StoreManager.freeUsesPerMonth - uses)
                Text("\(remaining) free solves remaining this month")
                    .font(.system(size: 12))
                    .foregroundStyle(remaining <= 1 ? Color(hex: "F87171") : Color.appMuted)
            }
        }
    }

    private func capturedImageSection(_ img: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Problem Image")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appMuted)
                .padding(.horizontal, 20)

            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
                .padding(.horizontal, 20)
        }
    }

    private var thinkingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ProgressView().tint(Color.appAccent)
                Text("Solving your problem...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appMuted)
            }
            .padding(20)
            .glassSurface(cornerRadius: 20)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func solutionSection(_ sol: MathSolution) -> some View {
        VStack(spacing: 16) {
            // Problem
            VStack(alignment: .leading, spacing: 10) {
                Label("Problem", systemImage: "questionmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                Text(sol.problem)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassSurface(cornerRadius: 20)

            // Steps
            VStack(alignment: .leading, spacing: 14) {
                Label("Solution Steps", systemImage: "list.number")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)

                ForEach(Array(sol.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.appAccent.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appAccent)
                        }
                        Text(step)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(white: 0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity.combined(with: .offset(x: -10)))
                    .animation(.easeOut(duration: 0.3).delay(Double(i) * 0.08), value: showSolution)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassSurface(cornerRadius: 20)

            // Answer
            VStack(spacing: 8) {
                Text("Answer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appMuted)
                Text(sol.answer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appAccent)
                    .shadow(color: Color.appAccent.opacity(0.4), radius: 10)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appAccent.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appAccent.opacity(0.3), lineWidth: 1.5))
            )

            // Explanation
            VStack(alignment: .leading, spacing: 10) {
                Label("Explanation", systemImage: "lightbulb.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "F59E0B"))
                Text(sol.explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassSurface(cornerRadius: 20)

            // Solve Another
            Button {
                Haptics.impact(.medium)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    solution = nil
                    capturedImage = nil
                    showSolution = false
                    errorMessage = nil
                }
            } label: {
                Label("Solve Another Problem", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(GradientButtonStyle())
        }
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private func errorSection(_ err: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "F87171"))
            Text(err)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "F87171"))
        }
        .padding(16)
        .glassSurface(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    private var backgroundGlow: some View {
        ZStack {
            Ellipse()
                .fill(Color.appAccent.opacity(0.08))
                .frame(width: 350, height: 280)
                .blur(radius: 80)
                .offset(x: 60, y: -200)
            Ellipse()
                .fill(Color(hex: "60A5FA").opacity(0.05))
                .frame(width: 280, height: 220)
                .blur(radius: 60)
                .offset(x: -80, y: 100)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Logic

    private func startOrbPulse() {
        orbPulse = true
    }

    private func spawnFloatingSymbols() {
        floatingSymbols = (0..<12).map { i in
            FloatingSymbol(
                symbol: mathSymbols[i % mathSymbols.count],
                x: CGFloat.random(in: 40...340),
                y: CGFloat.random(in: 100...600),
                opacity: Double.random(in: 0.3...0.7),
                scale: CGFloat.random(in: 0.6...1.2)
            )
        }
    }

    private func solve(image: UIImage) async {
        isThinking = true
        errorMessage = nil
        showSolution = false
        solution = nil
        Haptics.impact(.medium)
        spawnFloatingSymbols()

        do {
            let result = try await SnapMathAI.shared.solveMath(from: image)
            let uses = UserDefaults.standard.integer(forKey: "monthly_uses")
            UserDefaults.standard.set(uses + 1, forKey: "monthly_uses")
            history.add(result, image: image)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                solution = result
                isThinking = false
                floatingSymbols = []
                showSolution = true
            }
            Haptics.notification(.success)
        } catch {
            withAnimation { isThinking = false; floatingSymbols = [] }
            errorMessage = error.localizedDescription
            Haptics.notification(.error)
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onCapture(img) }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
