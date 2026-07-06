# External Integrations

**Analysis Date:** 2026-07-06

## APIs & External Services

**Status:** None configured

No external APIs or cloud services are currently integrated into the application.

## Data Storage

**Databases:**
- Not applicable - No database integration configured
- Application is a stateless UI application with no persistent data layer

**File Storage:**
- Local filesystem only
- No cloud storage services configured

**Caching:**
- In-memory only (Flutter widget state)
- No external caching service

## Authentication & Identity

**Auth Provider:**
- Not applicable - No authentication configured
- Application is a public UI without user authentication

## Monitoring & Observability

**Error Tracking:**
- Not configured - No error tracking service integrated

**Logs:**
- Console only (via Flutter's debug output)
- No logging service configured

## CI/CD & Deployment

**Hosting:**
- Not configured - No deployment target specified
- Application is built locally only

**CI Pipeline:**
- Not configured - No CI/CD service integrated

**Build Commands:**
```bash
flutter build web    # Build for web
flutter build apk    # Build for Android
```

## Environment Configuration

**Required env vars:**
- None - No environment variables required

**Secrets location:**
- Not applicable - No API keys or secrets needed

## Webhooks & Callbacks

**Incoming:**
- Not applicable - Application is frontend-only, no server endpoints

**Outgoing:**
- Not applicable - No external service integration

## Platform-Specific Services

**Android:**
- Google Play Services: Not integrated (not required for basic app)
- Firebase: Not integrated
- Google Analytics: Not integrated

**Web:**
- No web analytics integrated
- No tracking services

**iOS:**
- Configuration present but platform not actively built
- No iOS-specific services integrated

---

*Integration audit: 2026-07-06*
