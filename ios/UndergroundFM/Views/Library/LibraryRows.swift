//
//  LibraryRows.swift
//  UndergroundFM
//
//  Rij-componenten voor de Bibliotheek-tab.
//

import SwiftUI

// MARK: - Track row

struct LibraryTrackRow: View {
    let track: Track
    var isCurrent: Bool = false
    var playlists: [Playlist] = []
    var onAddToPlaylist: ((Playlist) -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            TrackThumbnail(url: track.thumbnailUrl, cornerRadius: AppRadius.sm)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: AppFontSize.sm, weight: .medium))
                    .foregroundStyle(AppColors.textSecond)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .black))
                Text(formatCount(track.streamCount))
                    .font(.system(size: AppFontSize.xs, weight: .semibold))
            }
            .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(isCurrent ? AppColors.yellow.opacity(0.08) : AppColors.card)
        .overlay(alignment: .leading) {
            if isCurrent {
                AppColors.yellow
                    .frame(width: 4)
                    .clipShape(.rect(cornerRadius: 2))
            }
        }
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .contentShape(Rectangle())
        .contextMenu {
            if !playlists.isEmpty, let onAddToPlaylist {
                ForEach(playlists) { playlist in
                    Button {
                        onAddToPlaylist(playlist)
                    } label: {
                        Label(playlist.name, systemImage: "text.badge.plus")
                    }
                }
            }
        }
    }
}

// MARK: - Artist row

struct LibraryArtistRow: View {
    let artist: ArtistProfile
    @Bindable var l10n: L10n

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ProfileAvatar(initials: initials, photoUrl: artist.avatarUrl, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(artist.artistName)
                        .font(.system(size: AppFontSize.base, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    if artist.isFoundingArtist {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AppColors.yellow)
                    }
                }
                if !artist.genreTags.isEmpty {
                    Text(artist.genreTags.map(displayGenre).joined(separator: " · "))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .contentShape(Rectangle())
    }

    private func displayGenre(_ raw: String) -> String {
        switch raw.lowercased() {
        case "rb", "r&b": return "R&B"
        default: return raw.prefix(1).uppercased() + raw.dropFirst()
        }
    }

    private var initials: String {
        let parts = artist.artistName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(artist.artistName.prefix(2)).uppercased()
    }
}

// MARK: - Playlist row

struct PlaylistRow: View {
    let playlist: Playlist
    let covers: [String]
    @Bindable var l10n: L10n

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            PlaylistCover(name: playlist.name, covers: covers, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: AppFontSize.base, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.sm) {
                    Text(l10n.t("library.trackCount").replacingOccurrences(of: "%@", with: "\(playlist.trackCount)"))
                        .font(.system(size: AppFontSize.sm, weight: .medium))
                        .foregroundStyle(AppColors.textSecond)
                    visibilityBadge
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(.rect(cornerRadius: AppRadius.md))
        .contentShape(Rectangle())
    }

    private var visibilityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: playlist.isPublic ? "globe" : "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text(l10n.t(playlist.isPublic ? "library.public" : "library.private"))
                .font(.system(size: AppFontSize.xs, weight: .bold))
        }
        .foregroundStyle(playlist.isPublic ? AppColors.yellow : AppColors.textMuted)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((playlist.isPublic ? AppColors.yellow : AppColors.textMuted).opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Playlist cover (collage / single + overlay)

struct PlaylistCover: View {
    let name: String
    let covers: [String]
    var size: CGFloat = 64

    var body: some View {
        Group {
            if covers.count >= 4 {
                collage
            } else {
                singleWithOverlay
            }
        }
        .frame(width: size, height: size)
        .background(AppColors.cardHover)
        .clipShape(.rect(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var collage: some View {
        VStack(spacing: 1) {
            HStack(spacing: 1) {
                coverTile(covers[0])
                coverTile(covers[1])
            }
            HStack(spacing: 1) {
                coverTile(covers[2])
                coverTile(covers[3])
            }
        }
    }

    private var singleWithOverlay: some View {
        Color(AppColors.cardHover)
            .overlay {
                if let first = covers.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else {
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .overlay {
                LinearGradient(
                    colors: [AppColors.yellow.opacity(0.0), AppColors.yellow.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                Text(name)
                    .font(.system(size: size > 100 ? AppFontSize.md : AppFontSize.xs, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.5), radius: 3)
                    .padding(4)
            }
    }

    private var placeholder: some View {
        Image(systemName: "music.note")
            .font(.system(size: size * 0.3, weight: .bold))
            .foregroundStyle(AppColors.textMuted)
    }

    private func coverTile(_ urlStr: String) -> some View {
        Color(AppColors.cardHover)
            .overlay {
                if let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else {
                            Color(AppColors.card)
                        }
                    }
                } else {
                    Color(AppColors.card)
                }
            }
            .clipped()
    }
}
