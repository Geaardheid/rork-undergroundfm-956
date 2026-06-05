//
//  SubscriptionService.swift
//  UndergroundFM
//
//  Centrale bron van waarheid voor de abonnementsstatus (Spotify-model: betalen
//  gebeurt via een web Payment Link, 0% Apple-cut). Houdt dit op ÉÉN plek zodat de
//  Android-port later alleen deze ene service hoeft te herbouwen.
//
//  - `isSubscribed` leest de gecachte `subscription_status` van de ingelogde user
//    (via AuthStore.currentUser), zodat het direct na login beschikbaar is.
//  - `refresh()` haalt `subscription_status` opnieuw op uit de `users`-tabel voor
//    de huidige auth.uid(), zodat een betaling op het web na terugkeer ontgrendelt
//    zonder volledige re-login.
//

import Foundation

/// Minimale rij voor het opnieuw ophalen van enkel de abonnementsstatus.
nonisolated struct SubscriptionStatusRow: Decodable {
    let subscriptionStatus: String?

    enum CodingKeys: String, CodingKey {
        case subscriptionStatus = "subscription_status"
    }
}

/// Antwoord van de `create-portal-session` Edge Function (Stripe Customer Portal).
nonisolated struct PortalSessionResponse: Decodable {
    let url: String
}

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    private let sb = SupabaseService.shared

    /// De AuthStore vormt de gecachte bron van de geladen user. Zwakke referentie
    /// zodat de service nooit de store in leven houdt.
    private weak var auth: AuthStore?

    /// Stuurt de zichtbaarheid van de PaywallView aan vanuit de centrale gate.
    var showPaywall: Bool = false

    /// De web Payment Link waar niet-abonnees naartoe gestuurd worden.
    /// Spotify-model: betalen buiten de app, geen in-app purchase.
    let paymentLinkURL = URL(string: "https://undergroundapp.pages.dev")!

    /// Hoeveel seconden een niet-abonnee per track mag beluisteren (preview-modus).
    let previewLimit: TimeInterval = 30

    private init() {}

    /// Koppel de AuthStore (één keer bij app-start) zodat de status uit de geladen
    /// user gelezen kan worden zonder extra round-trip.
    func configure(auth: AuthStore) {
        self.auth = auth
    }

    /// Enige bron van waarheid: artiesten hebben altijd volledige toegang;
    /// voor de rest telt alleen `active` als geabonneerd. Alles anders
    /// (nil, trial, expired, past_due, canceled, inactive) → niet.
    var isSubscribed: Bool {
        guard let user = auth?.currentUser else { return false }
        if user.role == .artist { return true }
        return user.subscriptionStatus == "active"
    }

    /// Haal `subscription_status` opnieuw op voor de huidige auth.uid() en werk de
    /// gecachte user bij. Retourneert de nieuwe `isSubscribed`-waarde.
    @discardableResult
    func refresh() async -> Bool {
        guard let auth,
              let user = auth.currentUser,
              let token = SessionStore.shared.session?.accessToken else {
            return isSubscribed
        }
        do {
            let rows: [SubscriptionStatusRow] = try await sb.select(
                SubscriptionStatusRow.self,
                from: "users",
                query: [
                    "id": "eq.\(user.id)",
                    "select": "subscription_status",
                    "limit": "1"
                ],
                accessToken: token
            )
            if let status = rows.first?.subscriptionStatus {
                auth.updateSubscriptionStatus(status)
                // Sluit de paywall automatisch zodra het abonnement actief is.
                if status == "active" {
                    showPaywall = false
                }
            }
        } catch {
            // Transiente netwerkfouten: behoud de gecachte status.
        }
        return isSubscribed
    }

    /// Voer `action` uit als de gebruiker geabonneerd is; toon anders de paywall.
    func gate(_ action: () -> Void) {
        if isSubscribed {
            action()
        } else {
            showPaywall = true
        }
    }

    /// Open de web Payment Link in de browser (Spotify-model).
    func openPaymentLink(using open: (URL) -> Void) {
        open(paymentLinkURL)
    }

    /// Open de Stripe Customer Portal zodat een abonnee zijn abonnement kan beheren.
    /// Roept de `create-portal-session` Edge Function aan (POST, met het access token
    /// in de Authorization-header) en opent de teruggegeven url in de browser.
    /// Bij een fout valt het terug op het tonen van de paywall.
    func openManageSubscription(using open: @escaping (URL) -> Void) async {
        let base = SupabaseConfig.url
        guard !base.isEmpty,
              let token = SessionStore.shared.session?.accessToken,
              let endpoint = URL(string: "\(base)/functions/v1/create-portal-session") else {
            showPaywall = true
            return
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                showPaywall = true
                return
            }
            let result = try JSONDecoder().decode(PortalSessionResponse.self, from: data)
            guard let portalURL = URL(string: result.url) else {
                showPaywall = true
                return
            }
            open(portalURL)
        } catch {
            showPaywall = true
        }
    }
}
