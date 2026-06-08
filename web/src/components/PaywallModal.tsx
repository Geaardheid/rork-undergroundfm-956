import { Lock, X } from "lucide-react";

interface PaywallModalProps {
  open: boolean;
  onClose: () => void;
}

export function PaywallModal({ open, onClose }: PaywallModalProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4 backdrop-blur-sm">
      <div className="relative w-full max-w-md animate-fade-up rounded-2xl border border-border bg-card p-8 text-center">
        <button
          type="button"
          onClick={onClose}
          aria-label="Sluiten"
          className="absolute right-4 top-4 text-muted-foreground transition-colors hover:text-foreground"
        >
          <X className="h-5 w-5" />
        </button>

        <div className="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/15 glow-yellow">
          <Lock className="h-8 w-8 text-primary" />
        </div>

        <h2 className="font-display text-2xl font-extrabold tracking-tight text-foreground">
          Word lid om te luisteren
        </h2>
        <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
          Onbeperkt luisteren naar de underground vereist een actief abonnement. Steun de scene en
          ontgrendel elke track.
        </p>

        <a
          href="https://undergroundfm.nl"
          target="_blank"
          rel="noopener noreferrer"
          className="mt-6 inline-flex w-full items-center justify-center rounded-xl bg-primary px-6 py-3.5 font-display text-base font-bold uppercase tracking-wide text-primary-foreground transition-transform hover:scale-[1.02] glow-yellow"
        >
          Abonnement activeren
        </a>
        <p className="mt-3 text-xs text-muted-foreground">undergroundfm.nl</p>
      </div>
    </div>
  );
}
