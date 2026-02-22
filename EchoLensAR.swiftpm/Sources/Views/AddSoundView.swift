import SwiftUI

struct AddSoundView: View {
    @Bindable var store: CustomSoundStore
    @Bindable var soundManager: SoundAnalyzerManager
    @Environment(\.deviceLayout) var layout
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hue: 0.6, saturation: 0.12, brightness: 0.10),
                        Color(hue: 0.7, saturation: 0.15, brightness: 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if !store.customCategories.isEmpty {
                        addedSection
                    }
                    availableSection
                }
            }
            .navigationTitle("Add Sound Alert")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search sounds...")
        }
    }

    private var addedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Custom Alerts")
                .font(.system(size: layout.subtitle, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, layout.pagePadding)
                .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.customCategories) { custom in
                        HStack(spacing: 6) {
                            Image(systemName: custom.sfSymbol)
                                .font(.system(size: layout.caption, weight: .bold))
                                .foregroundStyle(custom.color)

                            Text(custom.displayName)
                                .font(.system(size: layout.caption, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Button {
                                soundManager.queueCustomAlertForDemo(custom)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: layout.caption))
                                    .foregroundStyle(.green)
                            }

                            Button {
                                withAnimation { store.removeCategory(id: custom.id) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: layout.caption))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.horizontal, layout.pagePadding)
            }
            .padding(.bottom, 8)

            Divider().padding(.horizontal, layout.pagePadding)
        }
    }

    private var availableSection: some View {
        let results = store.searchResults(for: searchText)
        return ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(results, id: \.self) { identifier in
                    soundRow(identifier: identifier)
                }
            }
            .padding(.horizontal, layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    private func soundRow(identifier: String) -> some View {
        let displayName = identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        return HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: layout.listIcon, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: layout.featureIcon * 0.8, height: layout.featureIcon * 0.8)
                .background(.cyan.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: layout.body, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(identifier)
                    .font(.system(size: layout.tiny, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    store.addCategory(identifier: identifier)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: round(24 * layout.scale)))
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview("Add Sound") {
    AddSoundView(store: CustomSoundStore(), soundManager: SoundAnalyzerManager())
        .preferredColorScheme(.dark)
}
