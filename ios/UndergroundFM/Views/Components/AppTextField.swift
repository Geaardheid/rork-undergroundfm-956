//
//  AppTextField.swift
//  UndergroundFM
//

import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var autocapitalize: TextInputAutocapitalization = .never
    var contentType: UITextContentType? = nil

    @FocusState private var focused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text, prompt: prompt)
            } else {
                TextField("", text: $text, prompt: prompt)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalize)
                    .autocorrectionDisabled()
            }
        }
        .textContentType(contentType)
        .focused($focused)
        .foregroundStyle(AppColors.textPrimary)
        .font(.system(size: AppFontSize.md, weight: .medium))
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 54)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(focused ? AppColors.yellow : AppColors.border, lineWidth: focused ? 1.5 : 1)
        )
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .animation(.easeInOut(duration: 0.15), value: focused)
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(AppColors.textMuted)
    }
}
