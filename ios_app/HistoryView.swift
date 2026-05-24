import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: MathHistoryStore
    @State private var appeared = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(history.items.count) solved")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appMuted)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.appSurface, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                if history.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(Array(history.items.enumerated()), id: \.element.id) { i, item in
                            historyRow(item, index: i)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                        .onDelete(perform: history.delete)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 82) }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private func historyRow(_ item: MathHistoryItem, index: Int) -> some View {
        HStack(spacing: 14) {
            // Thumbnail or icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.12))
                    .frame(width: 56, height: 56)
                if let data = item.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "function")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.problemText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 10) {
                    Label("\(item.stepsCount) steps", systemImage: "list.number")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appAccent)
                    Text(dateFormatter.string(from: item.solvedAt))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("=")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appMuted)
                Text(item.answer)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .glassSurface(cornerRadius: 18)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.06), value: appeared)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.appAccent.opacity(0.5))
            }
            Text("No history yet")
                .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            Text("Solve your first math problem\nand it will appear here.")
                .font(.system(size: 14)).foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
