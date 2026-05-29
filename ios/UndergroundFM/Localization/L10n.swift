//
//  L10n.swift
//  UndergroundFM
//
//  Runtime in-app vertalingen (NL / EN / ES). Standaard NL.
//  Gebruik: Text(L10n.t("auth.login")) of L10n.shared.t("...")
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case nl, en, es

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nl: return "Nederlands"
        case .en: return "English"
        case .es: return "Español"
        }
    }

    var flag: String {
        switch self {
        case .nl: return "🇳🇱"
        case .en: return "🇬🇧"
        case .es: return "🇪🇸"
        }
    }
}

@Observable
final class L10n {
    static let shared = L10n()

    private let storageKey = "app_language"
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            self.language = .nl
        }
    }

    func setLanguage(_ lang: AppLanguage) {
        self.language = lang
    }

    func t(_ key: String) -> String {
        let dict: [String: String]
        switch language {
        case .nl: dict = Self.nl
        case .en: dict = Self.en
        case .es: dict = Self.es
        }
        return dict[key] ?? Self.nl[key] ?? key
    }

    // MARK: - NL (default)
    private static let nl: [String: String] = [
        "app.name": "UndergroundFM",
        "app.tagline": "Alleen underground. Altijd eerlijk betaald.",

        "auth.login": "Inloggen",
        "auth.register": "Registreren",
        "auth.email": "E-mailadres",
        "auth.password": "Wachtwoord",
        "auth.displayName": "Naam",
        "auth.continue": "Doorgaan",
        "auth.noAccount": "Nog geen account?",
        "auth.hasAccount": "Heb je al een account?",
        "auth.logout": "Uitloggen",
        "auth.loggedInAs": "Ingelogd als",

        "role.fan": "Ik ben een Fan",
        "role.artist": "Ik ben een Artiest",
        "role.choose": "Kies je rol",

        "invite.title": "Voer je uitnodigingscode in",
        "invite.subtitle": "Artiesten komen alleen via een invite-code op het platform.",
        "invite.verify": "Code verifiëren",
        "invite.invalid": "Ongeldige of verlopen code",
        "invite.foundingBadge": "Founding Artist",
        "invite.foundingWelcome": "Welkom! Je krijgt 60% revenue share als Founding Artist.",

        "errors.required": "Vul alle velden in",
        "errors.invalidEmail": "Ongeldig e-mailadres",
        "errors.passwordShort": "Wachtwoord moet minstens 6 tekens zijn",
        "errors.network": "Verbindingsfout — probeer opnieuw",
        "errors.unknown": "Er ging iets mis",

        "settings.language": "Taal",
        "common.loading": "Laden…",
        "common.cancel": "Annuleren",
        "common.done": "Klaar",
        "common.comingSoon": "Binnenkort beschikbaar",

        "tab.home": "Home",
        "tab.discover": "Ontdek",
        "tab.upload": "Upload",
        "tab.library": "Bibliotheek",
        "tab.profile": "Profiel",

        "feed.featured": "UITGELICHT",
        "feed.seeAll": "Alles zien",
        "feed.empty": "Nog niets in deze categorie — kom snel terug.",
        "feed.errorTitle": "Laden mislukt",
        "feed.retry": "Opnieuw",
        "feed.trending_rap": "Trending Rap",
        "feed.new_drill": "Nieuw Drill",
        "feed.new_afro": "Nieuw Afro",
        "feed.trending_trap": "Trending Trap",
        "feed.new_rb": "Nieuw R&B",
        "feed.new_house": "Nieuw House",

        "artist.becomeAction": "Word artiest",
        "artist.becomeTitle": "Word artiest",
        "artist.becomeSubtitle": "Maak een artiestenprofiel aan en begin met uploaden.",
        "artist.nameLabel": "Artiestennaam",
        "artist.namePlaceholder": "Jouw artiestennaam",
        "artist.bioLabel": "Bio",
        "artist.bioPlaceholder": "Vertel kort wie je bent (max 500 tekens)",
        "artist.genresLabel": "Genres",
        "artist.instagramLabel": "Instagram (optioneel)",
        "artist.submit": "Profiel aanmaken",
        "artist.successTitle": "Welkom op het podium",
        "artist.successMessage": "Je artiestenprofiel staat live. Je kunt nu uploaden.",
        "artist.errorNameRequired": "Vul je artiestennaam in",
        "artist.labelPrefix": "Artiest",

        "upload.title": "Track uploaden",
        "upload.subtitle": "Upload je muziek en laat het underground horen.",
        "upload.audioLabel": "Audio bestand",
        "upload.audioPlaceholder": "Kies een mp3 of m4a bestand",
        "upload.audioTapToChange": "Tik om te wijzigen",
        "upload.coverLabel": "Cover afbeelding",
        "upload.coverPlaceholder": "Kies een cover (16:9)",
        "upload.coverSelected": "Cover geselecteerd",
        "upload.titleLabel": "Titel",
        "upload.titlePlaceholder": "Track titel",
        "upload.descriptionLabel": "Beschrijving (optioneel)",
        "upload.descriptionPlaceholder": "Vertel het verhaal achter deze track",
        "upload.genresLabel": "Genres",
        "upload.explicitLabel": "Expliciete content",
        "upload.explicitHint": "Bevat expliciete teksten",
        "upload.uploadButton": "Track uploaden",
        "upload.successTitle": "Track geüpload!",
        "upload.successMessage": "Je track staat live op UndergroundFM.",
    ]

    // MARK: - EN
    private static let en: [String: String] = [
        "app.name": "UndergroundFM",
        "app.tagline": "Only underground. Always fair pay.",

        "auth.login": "Log in",
        "auth.register": "Sign up",
        "auth.email": "Email",
        "auth.password": "Password",
        "auth.displayName": "Display name",
        "auth.continue": "Continue",
        "auth.noAccount": "No account yet?",
        "auth.hasAccount": "Already have an account?",
        "auth.logout": "Log out",
        "auth.loggedInAs": "Logged in as",

        "role.fan": "I'm a Fan",
        "role.artist": "I'm an Artist",
        "role.choose": "Choose your role",

        "invite.title": "Enter your invite code",
        "invite.subtitle": "Artists join the platform by invite code only.",
        "invite.verify": "Verify code",
        "invite.invalid": "Invalid or expired code",
        "invite.foundingBadge": "Founding Artist",
        "invite.foundingWelcome": "Welcome! You get 60% revenue share as a Founding Artist.",

        "errors.required": "Please fill in all fields",
        "errors.invalidEmail": "Invalid email address",
        "errors.passwordShort": "Password must be at least 6 characters",
        "errors.network": "Network error — please try again",
        "errors.unknown": "Something went wrong",

        "settings.language": "Language",
        "common.loading": "Loading…",
        "common.cancel": "Cancel",
        "common.done": "Done",
        "common.comingSoon": "Coming soon",

        "tab.home": "Home",
        "tab.discover": "Discover",
        "tab.upload": "Upload",
        "tab.library": "Library",
        "tab.profile": "Profile",

        "feed.featured": "FEATURED",
        "feed.seeAll": "See all",
        "feed.empty": "Nothing here yet — check back soon.",
        "feed.errorTitle": "Failed to load",
        "feed.retry": "Retry",
        "feed.trending_rap": "Trending Rap",
        "feed.new_drill": "New Drill",
        "feed.new_afro": "New Afro",
        "feed.trending_trap": "Trending Trap",
        "feed.new_rb": "New R&B",
        "feed.new_house": "New House",

        "artist.becomeAction": "Become an artist",
        "artist.becomeTitle": "Become an artist",
        "artist.becomeSubtitle": "Create an artist profile and start uploading.",
        "artist.nameLabel": "Artist name",
        "artist.namePlaceholder": "Your artist name",
        "artist.bioLabel": "Bio",
        "artist.bioPlaceholder": "Tell us who you are (max 500 chars)",
        "artist.genresLabel": "Genres",
        "artist.instagramLabel": "Instagram (optional)",
        "artist.submit": "Create profile",
        "artist.successTitle": "Welcome to the stage",
        "artist.successMessage": "Your artist profile is live. You can now upload.",
        "artist.errorNameRequired": "Enter your artist name",
        "artist.labelPrefix": "Artist",

        "upload.title": "Upload track",
        "upload.subtitle": "Upload your music and let the underground hear it.",
        "upload.audioLabel": "Audio file",
        "upload.audioPlaceholder": "Choose an mp3 or m4a file",
        "upload.audioTapToChange": "Tap to change",
        "upload.coverLabel": "Cover image",
        "upload.coverPlaceholder": "Choose a cover (16:9)",
        "upload.coverSelected": "Cover selected",
        "upload.titleLabel": "Title",
        "upload.titlePlaceholder": "Track title",
        "upload.descriptionLabel": "Description (optional)",
        "upload.descriptionPlaceholder": "Tell the story behind this track",
        "upload.genresLabel": "Genres",
        "upload.explicitLabel": "Explicit content",
        "upload.explicitHint": "Contains explicit lyrics",
        "upload.uploadButton": "Upload track",
        "upload.successTitle": "Track uploaded!",
        "upload.successMessage": "Your track is live on UndergroundFM.",
    ]

    // MARK: - ES
    private static let es: [String: String] = [
        "app.name": "UndergroundFM",
        "app.tagline": "Solo underground. Siempre pago justo.",

        "auth.login": "Iniciar sesión",
        "auth.register": "Registrarse",
        "auth.email": "Correo electrónico",
        "auth.password": "Contraseña",
        "auth.displayName": "Nombre",
        "auth.continue": "Continuar",
        "auth.noAccount": "¿No tienes cuenta?",
        "auth.hasAccount": "¿Ya tienes una cuenta?",
        "auth.logout": "Cerrar sesión",
        "auth.loggedInAs": "Conectado como",

        "role.fan": "Soy un Fan",
        "role.artist": "Soy un Artista",
        "role.choose": "Elige tu rol",

        "invite.title": "Introduce tu código de invitación",
        "invite.subtitle": "Los artistas solo se unen a la plataforma con un código de invitación.",
        "invite.verify": "Verificar código",
        "invite.invalid": "Código inválido o caducado",
        "invite.foundingBadge": "Artista Fundador",
        "invite.foundingWelcome": "¡Bienvenido! Recibes el 60% de revenue share como Artista Fundador.",

        "errors.required": "Por favor completa todos los campos",
        "errors.invalidEmail": "Correo electrónico inválido",
        "errors.passwordShort": "La contraseña debe tener al menos 6 caracteres",
        "errors.network": "Error de red — inténtalo de nuevo",
        "errors.unknown": "Algo salió mal",

        "settings.language": "Idioma",
        "common.loading": "Cargando…",
        "common.cancel": "Cancelar",
        "common.done": "Hecho",
        "common.comingSoon": "Próximamente",

        "tab.home": "Inicio",
        "tab.discover": "Descubrir",
        "tab.upload": "Subir",
        "tab.library": "Biblioteca",
        "tab.profile": "Perfil",

        "feed.featured": "DESTACADO",
        "feed.seeAll": "Ver todo",
        "feed.empty": "Aún no hay nada — vuelve pronto.",
        "feed.errorTitle": "Error al cargar",
        "feed.retry": "Reintentar",
        "feed.trending_rap": "Rap en tendencia",
        "feed.new_drill": "Drill nuevo",
        "feed.new_afro": "Afro nuevo",
        "feed.trending_trap": "Trap en tendencia",
        "feed.new_rb": "R&B nuevo",
        "feed.new_house": "House nuevo",

        "artist.becomeAction": "Conviértete en artista",
        "artist.becomeTitle": "Conviértete en artista",
        "artist.becomeSubtitle": "Crea un perfil de artista y empieza a subir música.",
        "artist.nameLabel": "Nombre artístico",
        "artist.namePlaceholder": "Tu nombre artístico",
        "artist.bioLabel": "Bio",
        "artist.bioPlaceholder": "Cuéntanos quién eres (máx. 500 caracteres)",
        "artist.genresLabel": "Géneros",
        "artist.instagramLabel": "Instagram (opcional)",
        "artist.submit": "Crear perfil",
        "artist.successTitle": "Bienvenido al escenario",
        "artist.successMessage": "Tu perfil de artista está activo. Ya puedes subir música.",
        "artist.errorNameRequired": "Introduce tu nombre artístico",
        "artist.labelPrefix": "Artista",

        "upload.title": "Subir track",
        "upload.subtitle": "Sube tu música y deja que el underground la escuche.",
        "upload.audioLabel": "Archivo de audio",
        "upload.audioPlaceholder": "Elige un archivo mp3 o m4a",
        "upload.audioTapToChange": "Toca para cambiar",
        "upload.coverLabel": "Imagen de portada",
        "upload.coverPlaceholder": "Elige una portada (16:9)",
        "upload.coverSelected": "Portada seleccionada",
        "upload.titleLabel": "Título",
        "upload.titlePlaceholder": "Título de la pista",
        "upload.descriptionLabel": "Descripción (opcional)",
        "upload.descriptionPlaceholder": "Cuenta la historia detrás de esta pista",
        "upload.genresLabel": "Géneros",
        "upload.explicitLabel": "Contenido explícito",
        "upload.explicitHint": "Contiene letras explícitas",
        "upload.uploadButton": "Subir track",
        "upload.successTitle": "¡Track subido!",
        "upload.successMessage": "Tu track está en vivo en UndergroundFM.",
    ]
}
