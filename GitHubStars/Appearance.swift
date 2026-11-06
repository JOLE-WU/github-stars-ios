import SwiftUI

/// 各编程语言对应的主题色（用于列表/卡片上的语言圆点）。
func languageColor(_ language: String) -> Color {
    let map: [String: Color] = [
        "Swift": Color(hex: 0xF05138),
        "Python": Color(hex: 0x3572A5),
        "JavaScript": Color(hex: 0xF1E05A),
        "TypeScript": Color(hex: 0x3178C6),
        "Go": Color(hex: 0x00ADD8),
        "Rust": Color(hex: 0xDEA584),
        "Java": Color(hex: 0xB07219),
        "C++": Color(hex: 0xF34B7D),
        "C": Color(hex: 0x555555),
        "C#": Color(hex: 0x178600),
        "Ruby": Color(hex: 0x701516),
        "Kotlin": Color(hex: 0xA97BFF),
        "PHP": Color(hex: 0x4F5D95),
        "Shell": Color(hex: 0x89E051),
        "Dart": Color(hex: 0x00B4AB),
        "Vue": Color(hex: 0x41B883),
        "HTML": Color(hex: 0xE34C26)
    ]
    return map[language] ?? Color(hex: 0x8E8E93)
}

extension Color {
    /// 通过十六进制整数构造颜色，例如 0xF05138。
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
