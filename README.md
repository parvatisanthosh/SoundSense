# Dhwani 🔊

An AI-powered accessibility app designed to help deaf and hard-of-hearing users navigate their environment through real-time sound detection, speaker recognition, and speech-to-text capabilities.

> **Microsoft Imagine Cup 2026 Submission**

## Features

- **Real-time Sound Detection** — Identifies environmental sounds (doorbell, alarm, dog barking, etc.) using YAMNet
- **Custom Sound Training** — Train the app to recognize your specific doorbell, speakers, and other personalized sounds
- **Speaker Recognition** — Distinguishes between different speakers using Pyannote diarization
- **Speech-to-Text** — Converts spoken words to text using Azure Speech Services
- **AI Chatbot** — Built-in assistant to help users navigate the app and get support
- **Interactive Dashboard** — Clean, intuitive dashboard to view sound history, alerts, and manage settings
- **Visual & Haptic Alerts** — Notifies users through on-screen alerts and vibration patterns
- **Emergency SOS** — Quick access to emergency contacts and services during critical situations
- **Sleep Guardian** — Monitors important sounds while the user sleeps and wakes them with alerts

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter, Dart |
| Sound Classification | YAMNet (TensorFlow) |
| Speaker Diarization | Pyannote |
| Speech-to-Text | Azure Speech Services |
| Backend | Python, Flask |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  Python Backend  │────▶│  ML Models      │
│  (Mobile UI)    │◀────│  (Flask API)     │◀────│  YAMNet/Pyannote│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │
                                ▼
                        ┌──────────────────┐
                        │  Azure Speech    │
                        │  Services        │
                        └──────────────────┘
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Python 3.9+
- Azure account (for Speech Services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/parvatisanthosh/dhwani.git
   cd dhwani
   ```

2. **Set up the Flutter app**
   ```bash
   cd app
   flutter pub get
   ```

3. **Set up the Python backend**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Add your Azure Speech Services key
   ```

5. **Run the backend**
   ```bash
   python app.py
   ```

6. **Run the Flutter app**
   ```bash
   cd app
   flutter run
   ```

## How It Works

### Sound Detection (YAMNet)
YAMNet is a pre-trained deep neural network that classifies audio into 521 categories. We filter these to focus on sounds relevant to safety and daily life.

### Speaker Recognition (Pyannote)
Pyannote performs speaker diarization — it identifies "who spoke when" in an audio stream, allowing users to distinguish between different people in a conversation.

### Speech-to-Text (Azure)
Azure Speech Services provides accurate, real-time transcription with support for multiple languages.

## Team

- **Vedant Sahu**
- **Parvathy GS**
- **Ananya Garg**
- **Suryansh Verma**

## Acknowledgments

- [YAMNet](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet) for audio classification
- [Pyannote](https://github.com/pyannote/pyannote-audio) for speaker diarization
- [Azure Speech Services](https://azure.microsoft.com/en-us/services/cognitive-services/speech-services/) for speech-to-text
