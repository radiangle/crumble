# Crumble — macOS AI Meeting Notes

A native macOS menubar app that records system audio + microphone, transcribes via OpenAI Whisper, and generates structured meeting notes using Claude.

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+
- OpenAI API key (for Whisper transcription)
- Anthropic API key (for Claude note generation)

## Setup

### 1. Open in Xcode

Open the `Crumble/` directory as a Swift Package in Xcode:

```
File → Open → select the Crumble/ folder
```

### 2. Configure Signing & Capabilities

1. In the Project navigator, click the `Crumble` package
2. Under **Targets → Crumble**, go to **Signing & Capabilities**
3. Set a **Development Team** (required for microphone + screen recording APIs)
4. Add the entitlements file: drag `Crumble.entitlements` from the file list, or click **+ Capability** and add:
   - **Audio Input** (microphone access)
   - Manually ensure `Crumble.entitlements` is set in Build Settings → Code Signing Entitlements

### 3. Add Info.plist Keys

Create an `Info.plist` in `Sources/Crumble/` (or add via target settings) with:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Crumble records microphone audio for meeting transcription.</string>
<key>NSScreenCaptureUsageDescription</key>
<string>Crumble captures system audio from other apps for meeting transcription.</string>
```

### 4. Build & Run

Press **⌘R** to build and run. The Crumble waveform icon will appear in your menubar.

### 5. Add API Keys

1. Click the menubar icon → click the **gear** icon to open Settings
2. Enter your **OpenAI API Key** (starts with `sk-...`)
3. Enter your **Anthropic API Key** (starts with `sk-ant-...`)
4. Click **Save Keys** — they are stored securely in macOS Keychain

## Usage

1. Click the **Crumble** menubar icon
2. Click **Start Recording** — grant microphone and screen recording permissions when prompted
3. Conduct your meeting
4. Click **Stop Recording**
5. Crumble transcribes the audio and generates structured notes
6. Click **All Meetings** to view the full notes window

## Architecture

| Component | Technology |
|---|---|
| Microphone capture | `AVAudioEngine` |
| System audio capture | `ScreenCaptureKit` (SCStream) |
| Transcription | OpenAI Whisper API (`whisper-1`) |
| Note generation | Anthropic Claude (`claude-sonnet-4-6`) |
| API key storage | macOS Keychain |
| Meeting persistence | JSON in `~/Library/Application Support/Crumble/` |
| UI | SwiftUI, MenuBarExtra |

## Project Structure

```
Sources/Crumble/
├── CrumbleApp.swift          # @main, MenuBarExtra, windows
├── AppState.swift            # Central state, recording → transcription → notes pipeline
├── Audio/
│   ├── AudioCaptureManager.swift   # Orchestrates mic + system audio
│   └── SystemAudioCapture.swift    # ScreenCaptureKit system audio
├── Services/
│   ├── TranscriptionService.swift  # Whisper API
│   ├── NoteGenerationService.swift # Claude API
│   └── KeychainService.swift       # Keychain CRUD
├── Models/
│   ├── Meeting.swift         # Codable meeting model
│   └── MeetingNote.swift     # Codable notes model
├── Storage/
│   └── MeetingStore.swift    # JSON persistence
└── Views/
    ├── MenubarView.swift      # Menubar popover
    ├── MeetingsListView.swift # Full meetings window
    ├── MeetingDetailView.swift# Notes + transcript view
    ├── RecordingView.swift    # Live recording UI
    └── SettingsView.swift     # API key settings
```

## Privacy

- Audio is processed locally as WAV files in the system temp directory and deleted after transcription
- Transcripts are sent to OpenAI's Whisper API over HTTPS
- Notes are generated via Anthropic's Claude API over HTTPS
- API keys are stored in macOS Keychain, never on disk in plaintext
- Meeting notes are stored locally in `~/Library/Application Support/Crumble/`
