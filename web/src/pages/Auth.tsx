import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Loader2, Mail, CheckCircle2 } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";

type Mode = "login" | "register";

export default function Auth() {
  const navigate = useNavigate();
  const { signIn, signUp } = useAuth();
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [displayName, setDisplayName] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [confirmSent, setConfirmSent] = useState<boolean>(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (mode === "login") {
        await signIn(email.trim(), password);
        navigate("/");
      } else {
        const { needsConfirmation } = await signUp(email.trim(), password, displayName.trim() || "Fan");
        if (needsConfirmation) setConfirmSent(true);
        else navigate("/");
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Er ging iets mis. Probeer opnieuw.";
      setError(friendlyError(message));
    } finally {
      setLoading(false);
    }
  };

  if (confirmSent) {
    return (
      <div className="flex min-h-screen items-center justify-center px-4">
        <div className="w-full max-w-sm animate-fade-up rounded-2xl border border-border bg-card p-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-primary/15">
            <Mail className="h-7 w-7 text-primary" />
          </div>
          <h2 className="font-display text-xl font-bold">Bevestig je e-mail</h2>
          <p className="mt-2 text-sm text-muted-foreground">
            We hebben een bevestigingslink gestuurd naar <span className="text-foreground">{email}</span>.
            Bevestig je account en log daarna in.
          </p>
          <button
            type="button"
            onClick={() => {
              setConfirmSent(false);
              setMode("login");
            }}
            className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary"
          >
            <CheckCircle2 className="h-4 w-4" /> Terug naar inloggen
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="w-full max-w-sm animate-fade-up">
        <div className="mb-8 text-center">
          <img
            src="/logo-u.png"
            alt="UndergroundFM"
            className="mx-auto h-14 w-14 object-contain glow-yellow"
          />
          <h1 className="mt-4 font-display text-2xl font-extrabold tracking-tight">
            UNDERGROUND<span className="text-primary">FM</span>
          </h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {mode === "login" ? "Log in om te luisteren" : "Maak een account aan"}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          {mode === "register" && (
            <input
              type="text"
              placeholder="Naam"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              className="w-full rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
            />
          )}
          <input
            type="email"
            required
            placeholder="E-mail"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
          />
          <input
            type="password"
            required
            placeholder="Wachtwoord"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none"
          />

          {error && <p className="text-sm text-destructive">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="flex w-full items-center justify-center rounded-xl bg-primary px-6 py-3.5 font-display text-base font-bold uppercase tracking-wide text-primary-foreground transition-transform hover:scale-[1.01] disabled:opacity-60"
          >
            {loading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : mode === "login" ? (
              "Inloggen"
            ) : (
              "Registreren"
            )}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-muted-foreground">
          {mode === "login" ? "Nog geen account?" : "Al een account?"}{" "}
          <button
            type="button"
            onClick={() => {
              setError(null);
              setMode(mode === "login" ? "register" : "login");
            }}
            className="font-semibold text-primary hover:underline"
          >
            {mode === "login" ? "Registreren" : "Inloggen"}
          </button>
        </p>
      </div>
    </div>
  );
}

function friendlyError(message: string): string {
  const m = message.toLowerCase();
  if (m.includes("invalid login")) return "Onjuiste e-mail of wachtwoord.";
  if (m.includes("already registered") || m.includes("already exists"))
    return "Dit e-mailadres is al in gebruik.";
  if (m.includes("password")) return "Wachtwoord moet minstens 6 tekens zijn.";
  if (m.includes("email")) return "Voer een geldig e-mailadres in.";
  return message;
}
