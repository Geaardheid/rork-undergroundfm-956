//
//  Format.swift
//  UndergroundFM
//
//  Kleine formatteer-helpers voor de UI.
//

import Foundation

/// Formatteert grote aantallen compact: 1.200 → "1.2K", 1.500.000 → "1.5M".
func formatCount(_ value: Int64) -> String {
    switch value {
    case 1_000_000...:
        return trimmedDecimal(Double(value) / 1_000_000) + "M"
    case 1_000...:
        return trimmedDecimal(Double(value) / 1_000) + "K"
    default:
        return "\(value)"
    }
}

/// 1.0 → "1", 1.2 → "1.2", 12.0 → "12", 123.4 → "123".
private func trimmedDecimal(_ d: Double) -> String {
    if d >= 100 { return String(format: "%.0f", d) }
    let s = String(format: "%.1f", d)
    return s.hasSuffix(".0") ? String(s.dropLast(2)) : s
}
