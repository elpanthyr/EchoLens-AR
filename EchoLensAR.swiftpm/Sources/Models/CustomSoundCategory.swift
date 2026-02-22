import SwiftUI

struct CustomSoundCategory: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let classifierIdentifier: String
    let displayName: String
    var sfSymbol: String
    let colorHue: Double

    var color: Color {
        Color(hue: colorHue, saturation: 0.7, brightness: 0.8)
    }

    init(classifierIdentifier: String, displayName: String, sfSymbol: String, colorHue: Double) {
        self.id = UUID()
        self.classifierIdentifier = classifierIdentifier
        self.displayName = displayName
        self.sfSymbol = sfSymbol
        self.colorHue = colorHue
    }
}
