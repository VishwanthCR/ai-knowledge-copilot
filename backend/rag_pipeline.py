import os
from typing import List, Tuple

import numpy as np
from dotenv import load_dotenv
from sklearn.feature_extraction.text import TfidfVectorizer

from langchain_community.document_loaders import PyPDFLoader
from langchain_core.documents import Document
from langchain_groq import ChatGroq
from langchain_text_splitters import RecursiveCharacterTextSplitter


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")

if not GROQ_API_KEY:
    raise RuntimeError(
        "GROQ_API_KEY is not configured."
    )


# ============================================================
# CONFIGURATION
# ============================================================

CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200
TOP_K = 4


# ============================================================
# LIGHTWEIGHT VECTOR STORE
# ============================================================

class TFIDFVectorStore:
    """
    Lightweight local vector store using TF-IDF.

    This replaces the Hugging Face / Gemini embedding
    dependency and is suitable for low-memory deployments.
    """

    def __init__(
        self,
        documents: List[Document],
    ) -> None:

        self.documents = documents

        self.vectorizer = TfidfVectorizer(
            lowercase=True,
            stop_words="english",
            max_features=20000,
            ngram_range=(1, 2),
        )

        texts = [
            document.page_content
            for document in documents
        ]

        self.vectors = self.vectorizer.fit_transform(
            texts
        )

    def similarity_search(
        self,
        query: str,
        k: int = TOP_K,
    ) -> List[Document]:
        """
        Retrieve the most relevant document chunks.
        """

        if not self.documents:
            return []

        query_vector = self.vectorizer.transform(
            [query]
        )

        # TF-IDF vectors are L2-normalized by default,
        # therefore dot product gives cosine similarity.
        scores = (
            self.vectors @ query_vector.T
        ).toarray().flatten()

        # Don't request more documents than available.
        k = min(
            k,
            len(self.documents)
        )

        # Highest scores first.
        top_indices = np.argsort(
            scores
        )[::-1][:k]

        return [
            self.documents[index]
            for index in top_indices
        ]


# ============================================================
# LOAD PDF
# ============================================================

def load_pdf(
    pdf_path: str,
) -> List[Document]:
    """Load a PDF and extract its text."""

    loader = PyPDFLoader(
        pdf_path
    )

    documents = loader.load()

    return documents


# ============================================================
# SPLIT DOCUMENTS
# ============================================================

def split_documents(
    documents: List[Document],
) -> List[Document]:
    """Split PDF content into smaller chunks."""

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
) -> TFIDFVectorStore:
    """Create a lightweight TF-IDF vector store."""

    print(
        f"Creating TF-IDF vectors for "
        f"{len(chunks)} chunks..."
    )

    vectorstore = TFIDFVectorStore(
        chunks
    )

    print(
        "TF-IDF vector store created successfully."
    )

    return vectorstore


# ============================================================
# PROCESS PDF
# ============================================================

def process_pdf(
    pdf_path: str,
) -> TFIDFVectorStore:
    """
    Complete PDF processing pipeline.

    PDF
      ↓
    Text extraction
      ↓
    Chunking
      ↓
    TF-IDF vectors
      ↓
    Lightweight vector store
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

    return vectorstore


# ============================================================
# RETRIEVAL
# ============================================================

def retrieve_documents(
    vectorstore: TFIDFVectorStore,
    question: str,
) -> List[Document]:
    """Retrieve the most relevant chunks."""

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

PROMPT = """
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

USER QUESTION:

{question}
"""


# ============================================================
# GENERATE ANSWER
# ============================================================

def generate_answer(
    question: str,
    documents: List[Document],
) -> str:
    """Generate an answer using Groq."""

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
    # Build prompt
    # --------------------------------------------------------

    formatted_prompt = PROMPT.format(
        context=context,
        question=question,
    )

    # --------------------------------------------------------
    # Generate answer
    # --------------------------------------------------------

    llm = get_llm()

    response = llm.invoke(
        formatted_prompt
    )

    if isinstance(
        response.content,
        str,
    ):
        return response.content

    return str(
        response.content
    )