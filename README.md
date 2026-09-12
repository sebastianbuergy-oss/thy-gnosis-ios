# Thy Gnosis (iOS)

Fan-App für die Berner Band Thy Gnosis: nächstes Konzert, alle bisherigen Shows,
Alben mit Bandcamp-Player zum Reinhören, Videos, Band, Flyer, Shop, Links.

- UIKit-Hülle mit `WKWebView`, die Web-App liegt gebündelt in `web/`.
- Xcode-Projekt wird mit XcodeGen aus `project.yml` erzeugt.
- Build: Codemagic Workflow `ios-testflight` (App-Store-Signierung, Upload nach TestFlight).
- Bundle-ID `com.sebastianbuergy.thygnosis`, iPhone, iOS 16+, nur Hochformat.
- Externe Links (Bandcamp, Spotify, Tickets, Mail) öffnen in Safari bzw. der jeweiligen App.

## Selbst-Aktualisierung

Die App lädt beim Start und bei jeder Rückkehr `feed/feed.json` von diesem Repo
(raw.githubusercontent.com). Der Feed enthält kommende Konzerte und Neuigkeiten
und wird von einem täglichen Job gepflegt (Bandsintown, thygnosis.com, Bandcamp,
YouTube, Facebook, Instagram). Ohne Netz zeigt die App den gebündelten Stand.

Prüfen: `npm run check`
