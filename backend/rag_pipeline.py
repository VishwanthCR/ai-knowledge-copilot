import os
from typing import List

from dotenv import load_dotenv

from langchain_community.document_loaders import PyPDFLoader
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_groq import ChatGroq
from langchain_text_splitters import RecursiveCharacterTextSplitter


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")


if not GROQ_API_KEY:
    raise RuntimeError(
        "GROQ_API_KEY is not configured."
    )

if not GOOGLE_API_KEY:
    raise RuntimeError(
        "GOOGLE_API_KEY is not configured."
    )


# ============================================================
# CONFIGURATION
# ============================================================

CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200
TOP_K = 4


# ============================================================
# EMBEDDINGS
# ============================================================

def get_embeddings() -> GoogleGenerativeAIEmbeddings:
    """
    Create the Google Gemini embedding model.

    GOOGLE_API_KEY is automatically read from
    the environment by langchain-google-genai.
    """

    return GoogleGenerativeAIEmbeddings(
        model="models/gemini-embedding-001",
        task_type="RETRIEVAL_DOCUMENT",
    )


# ============================================================
# LOAD PDF
# ============================================================

def load_pdf(pdf_path: str) -> List[Document]:
    """Load and extract text from a PDF."""

    loader = PyPDFLoader(pdf_path)

    documents = loader.load()

    return documents


# ============================================================
# SPLIT DOCUMENTS
# ============================================================

def split_documents(
    documents: List[Document],
) -> List[Document]:
    """Split documents into overlapping chunks."""

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
    )

    chunks = splitter.split_documents(
        documents
    )

    return chunks


# ============================================================
# CREATE VECTOR STORE
# ============================================================

def create_vectorstore(
    chunks: List[Document],
) -> FAISS:
    """Create a FAISS vector store from document chunks."""

    print(
        f"Creating embeddings for {len(chunks)} chunks..."
    )

    embeddings = get_embeddings()

    vectorstore = FAISS.from_documents(
        chunks,
        embeddings,
    )

    return vectorstore


# ============================================================
# PROCESS PDF
# ============================================================

def process_pdf(pdf_path: str) -> FAISS:
    """
    Complete PDF processing pipeline.

    PDF
      ↓
    Text extraction
      ↓
    Chunking
      ↓
    Google Gemini embeddings
      ↓
    FAISS vector store
    """

    print(
        "\n[1/3] Loading PDF..."
    )

    documents = load_pdf(
        pdf_path
    )

    print(
        f"Loaded {len(documents)} pages."
    )

    print(
        "\n[2/3] Splitting document..."
    )

    chunks = split_documents(
        documents
    )

    print(
        f"Created {len(chunks)} chunks."
    )

    print(
        "\n[3/3] Creating vector store..."
    )

    vectorstore = create_vectorstore(
        chunks
    )

    print(
        "Vector store created successfully."
    )

    return vectorstore


# ============================================================
# RETRIEVAL
# ============================================================

def retrieve_documents(
    vectorstore: FAISS,
    question: str,
) -> List[Document]:
    """Retrieve the most relevant document chunks."""

    documents = vectorstore.similarity_search(
        question,
        k=TOP_K,
    )

    return documents


# ============================================================
# GROQ LLM
# ============================================================

def get_llm() -> ChatGroq:
    """Create the Groq LLM."""

    return ChatGroq(
        api_key=GROQ_API_KEY,
        model="openai/gpt-oss-120b",
        temperature=0,
    )


# ============================================================
# PROMPT
# ============================================================

PROMPT = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """
You are AI Knowledge Copilot.

Answer the user's question using ONLY
the provided document context.

If the answer cannot be found in the
context, clearly say that the information
is not available in the uploaded document.

Do not invent facts.

Be concise, accurate, and helpful.

DOCUMENT CONTEXT:

{context}
""",
        ),
        (
            "human",
            "{question}",
        ),
    ]
)


# ============================================================
# GENERATE ANSWER
# ============================================================

def generate_answer(
    question: str,
    documents: List[Document],
) -> str:
    """Generate an answer from retrieved document context."""

    # --------------------------------------------------------
    # Build context
    # --------------------------------------------------------

    context_parts: List[str] = []

    for document in documents:
        context_parts.append(
            document.page_content
        )

    context = "\n\n---\n\n".join(
        context_parts
    )

    # --------------------------------------------------------
    # Create prompt
    # --------------------------------------------------------

    prompt = PROMPT.invoke(
        {
            "context": context,
            "question": question,
        }
    )

    # --------------------------------------------------------
    # Generate answer
    # --------------------------------------------------------

    llm = get_llm()

    response = llm.invoke(
        prompt
    )

    # --------------------------------------------------------
    # Safely return response
    # --------------------------------------------------------

    if isinstance(
        response.content,
        str,
    ):
        return response.content

    return str(
        response.content
    )