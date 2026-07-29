# LocalMind - Offline Local AI Chatbot System

LocalMind is a complete, production-grade offline AI Chatbot platform designed to operate across a Local Area Network (LAN). 
It features a **.NET 9 Web API** backend connected to an **Ollama Small Language Model (SLM)** host, EF Core SQLite conversation persistence, and a **Flutter Mobile App** supporting real-time Server-Sent Events (SSE) token streaming.

---

## 📂 Project Architecture & Folder Structure

```
MyChatMobile/
├── setup_server_env.ps1               # Server PC setup script (Ollama env & Firewall netsh)
├── README.md                          # Full setup & deployment guide
├── LocalMind.Backend/                 # .NET 9 Clean Architecture Solution
│   ├── LocalMind.sln
│   ├── LocalMind.Core/                # Domain Entities, DTOs & Service Interfaces
│   │   ├── Entities/                  # ChatSession.cs, ChatMessage.cs
│   │   ├── Dtos/                      # ChatDtos.cs
│   │   └── Interfaces/                # IOllamaClientService.cs, IChatRepository.cs
│   ├── LocalMind.Infrastructure/          # EF Core SQLite Context & Ollama SSE Stream Handler
│   │   ├── Data/                      # AppDbContext.cs, ChatRepository.cs
│   │   └── Services/                  # OllamaClientService.cs
│   └── LocalMind.Api/                 # ASP.NET Core 9 Web API Controllers & Program.cs
│       ├── Controllers/               # ChatController.cs (POST /api/chat/stream)
│       ├── Program.cs                 # Services, CORS, Kestrel 0.0.0.0:5000 setup
│       └── appsettings.json           # Connection string & Ollama BaseUrl config
└── lib/                               # Flutter Cross-Platform Mobile Client
    ├── main.dart                      # App entry point
    ├── core/                          # Services & Constants
    │   ├── constants/                 # app_constants.dart
    │   └── services/                  # api_service.dart (SSE chunk parser), storage_service.dart
    ├── models/                        # chat_message.dart, chat_session.dart
    ├── providers/                     # chat_provider.dart, settings_provider.dart
    └── ui/                            # ChatGPT-Style Typewriter UI
        ├── screens/                   # chat_screen.dart, settings_screen.dart
        └── widgets/                   # chat_bubble.dart, message_input.dart, drawer_menu.dart
```

---

## 🚀 Step-by-Step Deployment & Execution Guide

### 1. SERVER MACHINE SETUP (2. PC - LAN IP: 192.168.1.50)

#### Step A: Configure Ollama & Windows Firewall Rules
Open **PowerShell as Administrator** on the Server PC and run:
```powershell
.\setup_server_env.ps1
```
*This sets `OLLAMA_HOST=0.0.0.0:11434` and opens inbound firewall ports 11434 (Ollama) and 5000 (.NET Web API).*

#### Step B: Pull Your Preferred Small Language Model
Run the following command in terminal:
```cmd
ollama pull llama3.2:3b
```
*(Or use `ollama pull phi3:mini`)*

#### Step C: Host & Run the .NET 9 Web API Service
Navigate to the Backend directory and run:
```cmd
cd LocalMind.Backend\LocalMind.Api
dotnet run --urls "http://0.0.0.0:5000"
```
The API will start listening on port 5000 and automatically generate the `localmind.db` SQLite database.

---

### 2. DEVELOPMENT / MOBILE CLIENT MACHINE SETUP (Main PC)

#### Step A: Run Flutter Client in Debug / Emulator Mode
Ensure Flutter SDK and Android Studio are installed:
```cmd
flutter pub get
flutter run
```

#### Step B: Configure Server IP in App Settings
1. Open the app drawer menu or tap the ⚙️ **Settings icon**.
2. Set the **Server Base URL** to `http://192.168.1.50:5000`.
3. Tap **Test Ping** to confirm connection.
4. Tap **Save Configuration**.

---

### 3. GENERATING THE PRODUCTION RELEASE APK

To generate the standalone release APK for installation on physical Android devices:

```cmd
flutter build apk --release
```

The compiled APK file will be located at:
`build\app\outputs\flutter-apk\app-release.apk`

Transfer this APK to any Android phone on the same Wi-Fi/LAN network to use **LocalMind** offline!

---

## 🛠️ Technology Stack & API Endpoints

- **Server Language Model:** Ollama (`llama3.2:3b` / `phi3:mini`)
- **Backend:** .NET 9 Web API, Entity Framework Core 9, SQLite
- **Streaming:** Server-Sent Events (SSE) via `IAsyncEnumerable<string>` & HTTP Chunked Transfer Encoding
- **Client App:** Flutter, Provider, `http` chunked reader, Material 3 Dark Theme

### API Endpoints
- `POST /api/chat/stream`: Accepts user message and streams token chunks real-time.
- `GET /api/chat/history/{sessionId}`: Fetches past messages for a conversation session.
- `GET /api/chat/sessions`: Lists all active conversation sessions.
- `POST /api/chat/sessions`: Creates a new session.
- `DELETE /api/chat/sessions/{sessionId}`: Deletes a session.
- `GET /api/chat/health`: Server & Ollama health check status.
