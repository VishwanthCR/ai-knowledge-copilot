# 🤖 AI Knowledge Copilot

A full-stack **Retrieval-Augmented Generation (RAG)** application that lets users upload PDF documents and interact with them through a modern conversational AI interface.

The system processes the uploaded document locally, creates vector embeddings, retrieves the most relevant sections, and uses **Groq-hosted LLMs** to generate answers grounded in the document.

---

## ✨ Features

* 📄 **PDF Upload** — Upload documents directly from the Flutter application
* 🧠 **RAG Pipeline** — Retrieve relevant document context before generating answers
* 🔎 **Semantic Search** — Find relevant content using vector similarity
* 💾 **FAISS Vector Store** — Store and search document embeddings locally
* 🤗 **Local Embeddings** — Uses `all-MiniLM-L6-v2` through Hugging Face
* ⚡ **Groq LLM** — Fast AI-powered answer generation
* 💬 **Chat Interface** — Conversational interface for document Q&A
* 🌙 **Dark / Light Mode** — Theme switching
* ✨ **Animations & Transitions** — Modern interactive UI
* 📱 **Responsive Flutter UI** — Designed for different screen sizes
* 📚 **Source Retrieval** — Displays the document chunks used to answer questions
* 🔐 **Environment-based API Key** — API credentials are stored outside the source code

---

## 🏗️ Architecture

```text
                    ┌──────────────────────┐
                    │   Flutter Frontend   │
                    │                      │
                    │  PDF Upload          │
                    │  Chat Interface      │
                    │  Theme Switching     │
                    │  Animations          │
                    └──────────┬───────────┘
                               │
                               │ HTTP
                               ▼
                    ┌──────────────────────┐
                    │    FastAPI Backend   │
                    │                      │
                    │  /upload             │
                    │  /ask                │
                    └──────────┬───────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │      RAG Pipeline       │
                  │                         │
                  │  PDF → Text Extraction  │
                  │       ↓                 │
                  │  Chunking               │
                  │       ↓                 │
                  │  Embeddings             │
                  │       ↓                 │
                  │  FAISS                  │
                  │       ↓                 │
                  │  Similarity Retrieval   │
                  └──────────┬──────────────┘
                             │
                             ▼
                    ┌──────────────────────┐
                    │       Groq LLM       │
                    │                      │
                    │  Context + Question  │
                    │          ↓           │
                    │        Answer        │
                    └──────────────────────┘
```

---

## 📂 Project Structure

```text
ai-knowledge-copilot/
│
├── backend/
│   ├── api.py
│   ├── rag_pipeline.py
│   ├── requirements.txt
│   ├── documents/
│   └── vectorstore/
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
│   ├── web/
│   ├── windows/
│   ├── test/
│   └── pubspec.yaml
│
├── .gitignore
└── README.md
```

---

# 🧠 How RAG Works

The application follows a Retrieval-Augmented Generation workflow.

### 1. Upload

The user uploads a PDF through the Flutter frontend.

### 2. Text Extraction

The backend extracts text from the PDF using `PyPDFLoader`.

### 3. Chunking

The extracted text is divided into smaller overlapping chunks using `RecursiveCharacterTextSplitter`.

```text
PDF
 ↓
Extracted Text
 ↓
1000-character chunks
 ↓
200-character overlap
```

### 4. Embeddings

Each chunk is converted into a vector representation using:

```text
sentence-transformers/all-MiniLM-L6-v2
```

### 5. Vector Storage

The embeddings are stored in a local **FAISS** vector database.

### 6. Retrieval

When the user asks a question, the system performs similarity search and retrieves the most relevant chunks.

The current configuration retrieves:

```text
TOP_K = 4
```

### 7. Generation

The retrieved context and user's question are passed to the Groq LLM.

The model is instructed to answer using the provided document context rather than inventing information.

---

# 🛠️ Tech Stack

## Backend

| Technology            | Purpose                  |
| --------------------- | ------------------------ |
| Python                | Backend & RAG pipeline   |
| FastAPI               | REST API                 |
| LangChain             | RAG orchestration        |
| PyPDF                 | PDF processing           |
| Hugging Face          | Local embeddings         |
| Sentence Transformers | Embedding model          |
| FAISS                 | Vector similarity search |
| Groq                  | LLM inference            |
| Uvicorn               | ASGI server              |

## Frontend

| Technology | Purpose               |
| ---------- | --------------------- |
| Flutter    | Cross-platform UI     |
| Dart       | Application language  |
| HTTP       | Backend communication |

---

# 🚀 Getting Started

## Prerequisites

Install:

* Python 3.10+
* Flutter SDK
* Git
* A Groq API key

---

# ⚙️ Backend Setup

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
.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

---

## 🔑 Environment Variables

Create:

```text
backend/.env
```

Add:

```env
GROQ_API_KEY=your_groq_api_key_here
```

**Never commit `.env` to GitHub.**

The API key is intentionally excluded through `.gitignore`.

---

# ▶️ Run the Backend

From the `backend` directory:

```bash
uvicorn api:app --reload
```

The API will run at:

```text
http://127.0.0.1:8000
```

You can verify that it is running by opening the API root endpoint.

---

# 📱 Frontend Setup

Open another terminal:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Check available devices:

```bash
flutter devices
```

Run on Chrome:

```bash
flutter run -d chrome
```

Or run on another available Flutter device:

```bash
flutter run
```

---

# 🔗 API Endpoints

## `GET /`

Checks whether the backend is running.

### Response

```json
{
  "message": "AI Knowledge Copilot API is running",
  "status": "online"
}
```

---

## `POST /upload`

Uploads and processes a PDF.

### Processing flow

```text
PDF
 ↓
Text Extraction
 ↓
Chunking
 ↓
Embedding Generation
 ↓
FAISS Vector Store
```

---

## `POST /ask`

Accepts a question about the uploaded document.

### Request

```json
{
  "question": "What is the main purpose of this document?"
}
```

### Response

```json
{
  "success": true,
  "question": "What is the main purpose of this document?",
  "answer": "...",
  "sources": []
}
```

---

# 🔐 Security

The project follows several basic security practices:

* API keys are stored in environment variables.
* `.env` files are excluded from Git.
* Uploaded PDFs are excluded from Git.
* FAISS vector-store files are excluded from Git.
* Python virtual environments are excluded from Git.
* Flutter build/generated files are excluded from Git.

For production deployment, additional protections should be added, including:

* Authentication
* File-size limits
* Strong PDF/content validation
* Restricted CORS origins
* Rate limiting
* Secure deployment configuration

---

# 🧪 Development

Run backend:

```bash
cd backend
uvicorn api:app --reload
```

Run frontend:

```bash
cd frontend
flutter run -d chrome
```

Run Flutter analysis:

```bash
flutter analyze
```

Run Flutter tests:

```bash
flutter test
```

---

# 📌 Current Model Configuration

### Embedding Model

```text
sentence-transformers/all-MiniLM-L6-v2
```

Embeddings are generated locally, so the application does not require a paid embedding API.

### LLM

```text
openai/gpt-oss-120b
```

served through Groq.

---

# 🎯 Project Goals

AI Knowledge Copilot was built to demonstrate practical implementation of:

* Retrieval-Augmented Generation
* Vector databases
* Semantic search
* Local embedding models
* LLM integration
* REST API development
* Flutter frontend development
* Full-stack AI application architecture

---

# 🔮 Future Improvements

* [ ] Multi-document support
* [ ] Persistent user sessions
* [ ] Conversation history
* [ ] Streaming LLM responses
* [ ] Document management
* [ ] User authentication
* [ ] Cloud vector database
* [ ] Production deployment
* [ ] Better document metadata and citations
* [ ] Support for additional document formats
* [ ] Voice-based questions

---

# 👨‍💻 Author

**Vishwanth CR**

GitHub: [VishwanthCR](https://github.com/VishwanthCR?utm_source=chatgpt.com)

LinkedIn: [Vishwanth CR](https://www.linkedin.com/in/vishwanth-cr?utm_source=chatgpt.com)

---

## ⭐ If you find this project useful

Give the repository a ⭐ on GitHub and feel free to explore the implementation.

[AI Knowledge Copilot on GitHub](https://github.com/VishwanthCR/ai-knowledge-copilot?utm_source=chatgpt.com)
