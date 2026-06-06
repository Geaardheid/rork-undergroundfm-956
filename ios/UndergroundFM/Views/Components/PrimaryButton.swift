//
//  PrimaryButton.swift
//  UndergroundFM
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(AppColors.yellowText)
                } else {
                    Text(title)
                        .font(.system(size: AppFontSize.md, weight: .bold))
                        .foregroundStyle(AppColors.yellowText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isDisabled ? AppColors.yellowDark : AppColors.yellow)
            .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
        .disabled(isLoading || isDisabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppFontSize.md, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: AppRadius.md))
        }
        .buttonStyle(PressableScaleStyle())
    }
}

struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { HapticManager.light() }
            }
    }
}
