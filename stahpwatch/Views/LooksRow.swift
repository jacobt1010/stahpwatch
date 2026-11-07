import SwiftUI

/// Looks in Customize: tap to switch, long-press to rename, duplicate or delete.
struct LooksRow: View {
    @Environment(AppSettings.self) private var settings

    @State private var deleting: Look?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                saveTile
                ForEach(settings.looks) { lookTile($0) }
            }
            .padding(.trailing, 24)
        }
        .scrollIndicators(.hidden)
        .padding(.trailing, -24)
        .alert("Delete \(deleting?.name ?? "this Look")?",
               isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Delete", role: .destructive) {
                if let deleting { settings.delete(deleting) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var saveTile: some View {
        Button {
            NamePrompt.present(initialName: settings.nextLookName) { settings.addLook(named: $0) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 84, height: 89)
                    .overlay(Rectangle().strokeBorder(settings.color(.fontTicks), lineWidth: 1))
                    .contentShape(Rectangle())
                Text("New")
                    .font(.system(size: 15, weight: .bold))
            }
        }
        .buttonStyle(PressDimStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New Look from current")
        .accessibilityAddTraits(.isButton)
    }

    private func lookTile(_ look: Look) -> some View {
        let active = look.id == settings.activeLookID
        return Button { settings.select(look) } label: {
            DialTile(title: look.name, style: look.style, colors: settings.dialColors(for: look),
                     border: settings.color(.fontTicks), isSelected: active)
        }
        .buttonStyle(PressDimStyle())
        .contextMenu {
            Button("Rename", systemImage: "pencil") { startRename(look) }
            Button("Duplicate", systemImage: "plus.square.on.square") { settings.duplicate(look) }
            if settings.looks.count > 1 {
                Button("Delete", systemImage: "trash", role: .destructive) { deleting = look }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(look.name) Look")
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: "Rename") { startRename(look) }
        .accessibilityAction(named: "Duplicate") { settings.duplicate(look) }
        .accessibilityAction(named: "Delete") { if settings.looks.count > 1 { deleting = look } }
    }

    private func startRename(_ look: Look) {
        NamePrompt.present(initialName: look.name) { settings.rename(look, to: $0) }
    }
}
