//
//  FlowChips.swift
//  UndergroundFM
//
//  Herbruikbare flow-layout voor genre/tag selectie chips.
//

import SwiftUI

struct GenreChip: Identifiable, Hashable {
    let id: String
    let label: String
}

struct FlowChips: View {
    let items: [GenreChip]
    let isSelected: (GenreChip) -> Bool
    let onTap: (GenreChip) -> Void

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 90), spacing: AppSpacing.sm)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(items) { item in
                let selected = isSelected(item)
                Button {
                    onTap(item)
                } label: {
                    Text(item.label)
                        .font(.system(size: AppFontSize.sm, weight: .bold))
                        .foregroundStyle(selected ? AppColors.yellowText : AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected ? AppColors.yellow : AppColors.card)
                        .overlay(
                            Capsule().stroke(selected ? AppColors.yellow : AppColors.border, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
    }
}
