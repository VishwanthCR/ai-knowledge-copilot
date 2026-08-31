# 🤖 AI Knowledge Copilot

An AI-powered document question-answering system built using **Retrieval-Augmented Generation (RAG)**.

Upload a PDF, ask questions about its contents, and get answers grounded in the document with retrieved source chunks and page references.

## ✨ Features

* 📄 PDF document ingestion
* ✂️ Intelligent text chunking
* 🧠 Local Hugging Face embeddings
* 🔎 FAISS vector similarity search
* 🤖 Groq LLM for answer generation
* 📚 Retrieved source chunks with page numbers
* 🖥️ Streamlit web interface
* 🔐 API keys stored securely using environment variables

## 🏗️ Architecture

```text
                    PDF
                     │
                     ▼
              PyPDFLoader
                     │
                     ▼
             Text Chunking
                     │
                     ▼
       Hugging Face Embeddings
              (Local / Free)
                     │
                     ▼
                 FAISS
            Vector Database
                     │
                     │
              User Question
                     │
                     ▼
            Similarity Search
                     │
                     ▼
          Top Relevant Chunks
                     │
                     ▼
                 Groq LLM
                     │
                     ▼
                  Answer
                     │
                     ▼
             Source References
```

## 🛠️ Tech Stack

| Technology                         | Purpose                              |
| ---------------------------------- | ------------------------------------ |
| Python                             | Backend / RAG pipeline               |
| LangChain                          | RAG orchestration                    |
| PyPDF                              | PDF text extraction                  |
| Hugging Face Sentence Transformers | Local embeddings                     |
| FAISS                              | Vector storage and similarity search |
| Groq                               | LLM inference                        |
| Streamlit                          | Web interface                        |

## 📁 Project Structure

```text
ai-knowledge-copilot/
│
├── app.py
├── rag_pipeline.py
├── requirements.txt
├── .gitignore
│
└── documents/
    └── .gitkeep
```

The following are intentionally excluded from Git:

```text
.env
.venv/
vectorstore/
documents/*.pdf
```

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/VishwanthCR/ai-knowledge-copilot.git
cd ai-knowledge-copilot
```

### 2. Create a virtual environment

```bash
python -m venv .venv
```

Activate it on Windows:

```bash
.venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure the Groq API key

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key_here
```

Do **not** commit `.env` to GitHub.

### 5. Add a PDF

Place a PDF inside:

```text
documents/
```

For example:

```text
documents/
└── example.pdf
```

### 6. Run the application

```bash
streamlit run app.py
```

The application will open locally at:

```text
http://localhost:8501
```

## 💬 Example

Upload a document and ask:

```text
What is the main purpose of this document?
```

The system:

1. Extracts text from the PDF
2. Splits the text into chunks
3. Generates local embeddings
4. Stores them in FAISS
5. Retrieves the most relevant chunks
6. Sends the retrieved context to Groq
7. Generates a grounded answer
8. Displays the retrieved source chunks and page numbers

## 🔐 Security

API credentials are loaded from environment variables:

```python
os.getenv("GROQ_API_KEY")
```

Sensitive files are excluded using `.gitignore`.

Never commit:

```text
.env
API keys
private documents
vectorstore files
```

If an API key is accidentally exposed, revoke it immediately and generate a replacement.

## 📌 Current Status

### Implemented

* PDF text extraction
* Recursive text chunking
* Local sentence-transformer embeddings
* FAISS vector database
* Similarity-based retrieval
* Groq-powered answer generation
* Streamlit interface
* Source chunk display

### Planned

* Flutter frontend
* FastAPI backend
* Multi-document support
* Chat history
* Improved source citations
* RAG evaluation
* Production deployment

## 🔮 Roadmap

```text
Current
   │
   ▼
Streamlit RAG Prototype
   │
   ▼
FastAPI Backend
   │
   ▼
Flutter Frontend
   │
   ▼
Multi-document RAG
   │
   ▼
Conversation History
   │
   ▼
Evaluation & Optimization
   │
   ▼
Production Deployment
```

## 🎯 Learning Goals

This project was built to gain practical experience with:

* Retrieval-Augmented Generation
* Embeddings and vector search
* LangChain
* LLM integration
* Document processing
* REST API architecture
* Frontend/backend separation
* AI application development

## 📄 License

This project is intended for educational and portfolio purposes.
