# 🤖 AI Knowledge Copilot

A modern **AI-powered document question-answering application** that allows users to upload PDF documents and interact with them through a conversational chat interface.

The project combines a **Flutter Android frontend**, **FastAPI backend**, lightweight **TF-IDF document retrieval**, **FAISS-style vector retrieval**, and **Groq LLM inference** to provide answers based on uploaded documents.

---

## ✨ Features

* 📄 **PDF Upload**

  * Upload PDF documents directly from the mobile app.
  * Automatic text extraction and document chunking.

* 💬 **Conversational AI**

  * Ask questions about uploaded documents.
  * Chat-style question and answer interface.
  * Press **Enter** to send questions.

* 🧠 **RAG-based Question Answering**

  * Relevant document chunks are retrieved before generating an answer.
  * Answers are grounded in the uploaded document context.

* 🔎 **Lightweight TF-IDF Retrieval**

  * Uses TF-IDF for document similarity.
  * Avoids heavyweight local embedding models.
  * Suitable for low-memory cloud deployment.

* ⚡ **Groq-powered AI**

  * Uses Groq for fast response generation.

* 🎨 **Modern Flutter UI**

  * Responsive layout.
  * Light and dark themes.
  * Animated chat interactions.
  * Upload and processing animations.
  * AI "thinking" indicator.
  * Smooth message transitions.

* 📱 **Android Standalone App**

  * Can be compiled into a release APK.
  * Communicates directly with the deployed Render backend.

* ☁️ **Cloud Backend**

  * FastAPI backend deployed on Render.
  * HTTPS communication between the Android app and backend.

* 🌐 **CORS Support**

  * Configured for frontend communication.

---

# 🏗️ Architecture

```text
                    ┌──────────────────────┐
                    │   Flutter Android    │
                    │      Frontend        │
                    └──────────┬───────────┘
                               │
                               │ HTTPS
                               ▼
                    ┌──────────────────────┐
                    │    Render Cloud      │
                    │     FastAPI API      │
                    └──────────┬───────────┘
                               │
                     ┌─────────┴─────────┐
                     │                   │
                     ▼                   ▼
              ┌─────────────┐     ┌─────────────┐
              │ PDF Loader  │     │    Groq     │
              │  & Parser   │     │     LLM     │
              └──────┬──────┘     └──────▲──────┘
                     │                   │
                     ▼                   │
              ┌─────────────┐            │
              │   Chunking  │            │
              └──────┬──────┘            │
                     │                   │
                     ▼                   │
              ┌─────────────┐            │
              │ TF-IDF      │            │
              │ Retrieval   │────────────┘
              └─────────────┘
```

---

# 🔄 Application Flow

### 1. Upload

```text
User selects PDF
       ↓
Flutter sends multipart request
       ↓
FastAPI /upload
       ↓
PDF text extraction
       ↓
Document chunking
       ↓
TF-IDF vectorization
       ↓
Vector store created
```

### 2. Ask

```text
User enters question
       ↓
Flutter sends POST /ask
       ↓
FastAPI receives question
       ↓
TF-IDF similarity search
       ↓
Relevant chunks retrieved
       ↓
Context + question sent to Groq
       ↓
AI-generated answer
       ↓
Flutter displays response
```

---

# 📂 Project Structure

```text
ai-knowledge-copilot/
│
├── backend/
│   ├── api.py
│   ├── rag_pipeline.py
│   ├── requirements.txt
│   └── .env
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   │
│   ├── android/
│   ├── ios/
│   ├── linux/
│   ├── macos/
│   ├── windows/
│   ├── web/
│   ├── pubspec.yaml
│   └── ...
│
├── .gitignore
└── README.md
```

---

# 🛠️ Technology Stack

| Component        | Technology                     |
| ---------------- | ------------------------------ |
| Frontend         | Flutter / Dart                 |
| Backend          | Python / FastAPI               |
| PDF Processing   | PyPDF                          |
| Text Chunking    | LangChain                      |
| Retrieval        | TF-IDF                         |
| Vector Search    | Lightweight local vector store |
| LLM              | Groq                           |
| Cloud Deployment | Render                         |
| Mobile Platform  | Android                        |
| API Format       | REST                           |
| Communication    | HTTPS                          |

---

# 🚀 Running the Backend Locally

Navigate to the backend:

```bash
cd backend
```

Create a virtual environment:

```bash
python -m venv .venv
```

Activate it on Windows:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Create:

```text
backend/.env
```

Add:

```env
GROQ_API_KEY=your_groq_api_key
```

Start FastAPI:

```bash
uvicorn api:app --reload
```

The API will be available at:

```text
http://127.0.0.1:8000
```

Swagger documentation:

```text
http://127.0.0.1:8000/docs
```

---

# 📱 Running the Flutter Frontend

Navigate to:

```bash
cd frontend
```

Install dependencies:

```bash
flutter pub get
```

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

---

# 🔗 Backend Configuration

The Flutter application should point to the deployed Render backend:

```dart
const String baseUrl =
    'https://YOUR-RENDER-SERVICE.onrender.com';
```

For local development, you can use:

```dart
const String baseUrl =
    'http://127.0.0.1:8000';
```

For the Android standalone APK, use the **Render HTTPS URL**.

---

# 📱 Build Standalone APK

From the `frontend` directory:

```bash
flutter clean
```

```bash
flutter pub get
```

Build:

```bash
flutter build apk --release
```

The generated APK will be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For architecture-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

---

# ☁️ Render Deployment

The backend is designed to run as a Render Web Service.

### Root Directory

```text
backend
```

### Build Command

```bash
pip install -r requirements.txt
```

### Start Command

```bash
uvicorn api:app --host 0.0.0.0 --port $PORT
```

### Environment Variable

```text
GROQ_API_KEY
```

The API can then be accessed through the Render HTTPS URL.

---

# 🔐 Security

API keys should **never be stored in the Flutter application or committed to GitHub**.

Use environment variables:

```env
GROQ_API_KEY=your_key
```

Ensure `.env` is included in `.gitignore`.

Example:

```gitignore
.env
.venv/
__pycache__/
build/
.dart_tool/
```

---

# 🧪 API Endpoints

## Health Check

```http
GET /
```

Response:

```json
{
  "message": "AI Knowledge Copilot API is running",
  "status": "online"
}
```

---

## Upload PDF

```http
POST /upload
```

Form field:

```text
file
```

Example response:

```json
{
  "success": true,
  "message": "PDF processed successfully",
  "filename": "document.pdf"
}
```

---

## Ask Question

```http
POST /ask
```

Request:

```json
{
  "question": "What is this document about?"
}
```

Response:

```json
{
  "success": true,
  "question": "What is this document about?",
  "answer": "..."
}
```

---

# 🎯 Current Version

**AI Knowledge Copilot — v1.0.0**

Current version includes:

* Flutter Android frontend
* Responsive modern chat UI
* PDF upload
* Document processing
* TF-IDF retrieval
* Groq-powered answers
* Render cloud backend
* Standalone Android APK support
* Light/dark theme
* Animated interactions

---

# ⚠️ Current Limitations

This version is primarily intended as a **portfolio/demo application**.

The current backend maintains the processed document's retrieval data in memory. Therefore:

* Restarting the Render service clears the current document.
* The current vector store isn't persistent.
* The architecture is not yet designed for multiple simultaneous users.
* TF-IDF retrieval is lexical rather than transformer-based semantic retrieval.

These can be addressed in a future production version with persistent storage, user/session isolation, and a dedicated vector database.

---

# 🔮 Future Improvements

* [ ] Persistent document storage
* [ ] Multi-user support
* [ ] User authentication
* [ ] Conversation history
* [ ] Multiple PDF support
* [ ] Persistent vector database
* [ ] Semantic embeddings
* [ ] Streaming AI responses
* [ ] Document management
* [ ] Source highlighting
* [ ] Page-level citations
* [ ] Production monitoring
* [ ] Google Play Store deployment

---

# 👨‍💻 Author

**Vishwanth CR**

Computer Science Engineering Student

GitHub: [VishwanthCR](https://github.com/VishwanthCR)

LinkedIn: [Vishwanth CR](https://www.linkedin.com/in/vishwanth-cr)

---

## ⭐ Project

If you find this project useful, consider giving it a ⭐ on GitHub.
