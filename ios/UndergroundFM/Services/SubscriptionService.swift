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
    let paymentLinkURL = URL(string: "https://undergroundfm.app/subscribe")!

    private init() {}

    /// Koppel de AuthStore (één keer bij app-start) zodat de status uit de geladen
    /// user gelezen kan worden zonder extra round-trip.
    func configure(auth: AuthStore) {
        self.auth = auth
    }

    /// Enige bron van waarheid: alleen `active` telt als geabonneerd.
    /// Alles anders (nil, trial, expired, past_due, canceled, inactive) → niet.
    var isSubscribed: Bool {
        auth?.currentUser?.subscriptionStatus == "active"
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
}
