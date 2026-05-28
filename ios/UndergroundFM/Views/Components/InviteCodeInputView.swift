//
//  InviteCodeInputView.swift
//  UndergroundFM
//
//  6-vakjes invoer voor invite codes, monospace, auto-hoofdletters.
//

import SwiftUI

struct InviteCodeInputView: View {
    @Binding var code: String
    let length: Int = 6

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            // Hidden text field that handles input
            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let filtered = newValue
                        .uppercased()
                        .unicodeScalars
                        .filter { CharacterSet.alphanumerics.contains($0) }
                        .prefix(length)
                    code = String(String.UnicodeScalarView(filtered))
                }
            ))
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .focused($focused)
            .opacity(0.01)
            .frame(maxWidth: .infinity)

            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<length, id: \.self) { index in
                    let char = index < code.count
                        ? String(code[code.index(code.startIndex, offsetBy: index)])
                        : ""
                    let isActive = focused && index == code.count
                    Text(char)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(
                                    isActive || !char.isEmpty ? AppColors.yellow : AppColors.border,
                                    lineWidth: isActive ? 2 : 1
                                )
                        )
                        .clipShape(.rect(cornerRadius: AppRadius.md))
                        .animation(.easeInOut(duration: 0.15), value: code)
                }
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            focused = true
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focused = true
            }
        }
    }
}
