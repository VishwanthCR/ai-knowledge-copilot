import os
from pathlib import Path

from dotenv import load_dotenv

from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_groq import ChatGroq

from langchain_core.prompts import ChatPromptTemplate


load_dotenv()


# ============================================================
# CONFIGURATION
# ============================================================

VECTORSTORE_PATH = "vectorstore"

EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

# Groq model
GROQ_MODEL = "openai/gpt-oss-120b"
CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200

TOP_K = 4


# ============================================================
# API KEY
# ============================================================

def validate_api_key():

    api_key = os.getenv("GROQ_API_KEY")

    if not api_key:
        raise ValueError(
            "GROQ_API_KEY not found.\n"
            "Add your Groq API key to the .env file."
        )

    return api_key


# ============================================================
# PDF LOADING
# ============================================================

def load_pdf(pdf_path):

    pdf_path = Path(pdf_path)

    if not pdf_path.exists():
        raise FileNotFoundError(
            f"PDF not found: {pdf_path}"
        )

    if pdf_path.suffix.lower() != ".pdf":
        raise ValueError(
            "The file must be a PDF."
        )

    print(f"Loading PDF: {pdf_path}")

    loader = PyPDFLoader(
        str(pdf_path)
    )

    documents = loader.load()

    print(
        f"Extracted {len(documents)} pages."
    )

    return documents


# ============================================================
# CHUNKING
# ============================================================

def split_documents(documents):

    splitter = RecursiveCharacterTextSplitter(

        chunk_size=CHUNK_SIZE,

        chunk_overlap=CHUNK_OVERLAP,

        length_function=len,

        separators=[
            "\n\n",
            "\n",
            ". ",
            " ",
            ""
        ]
    )

    chunks = splitter.split_documents(
        documents
    )

    print(
        f"Created {len(chunks)} chunks."
    )

    return chunks


# ============================================================
# LOCAL EMBEDDINGS
# ============================================================

def get_embeddings():

    print(
        "Loading local embedding model..."
    )

    embeddings = HuggingFaceEmbeddings(

        model_name=EMBEDDING_MODEL,

        model_kwargs={
            "device": "cpu"
        },

        encode_kwargs={
            "normalize_embeddings": True
        }
    )

    return embeddings


# ============================================================
# CREATE VECTOR STORE
# ============================================================

def create_vectorstore(chunks):

    embeddings = get_embeddings()

    print(
        "Creating local embeddings..."
    )

    vectorstore = FAISS.from_documents(

        documents=chunks,

        embedding=embeddings
    )

    os.makedirs(
        VECTORSTORE_PATH,
        exist_ok=True
    )

    vectorstore.save_local(
        VECTORSTORE_PATH
    )

    print(
        "FAISS vector store created."
    )

    return vectorstore


# ============================================================
# LOAD VECTOR STORE
# ============================================================

def load_vectorstore():

    index_file = os.path.join(
        VECTORSTORE_PATH,
        "index.faiss"
    )

    pickle_file = os.path.join(
        VECTORSTORE_PATH,
        "index.pkl"
    )

    if not (
        os.path.exists(index_file)
        and
        os.path.exists(pickle_file)
    ):

        raise FileNotFoundError(
            "FAISS vector store not found. "
            "Process a PDF first."
        )

    print(
        "Loading existing FAISS vector store..."
    )

    embeddings = get_embeddings()

    vectorstore = FAISS.load_local(

        VECTORSTORE_PATH,

        embeddings,

        allow_dangerous_deserialization=True
    )

    return vectorstore


# ============================================================
# PROCESS PDF
# ============================================================

def process_pdf(pdf_path):

    print("\n" + "=" * 60)

    print(
        "DOCUMENT PROCESSING"
    )

    print("=" * 60)

    # Step 1: Extract text

    documents = load_pdf(
        pdf_path
    )

    # Step 2: Split into chunks

    chunks = split_documents(
        documents
    )

    # Step 3: Create embeddings

    # Step 4: Store vectors in FAISS

    vectorstore = create_vectorstore(
        chunks
    )

    print("=" * 60)

    print(
        "DOCUMENT PROCESSING COMPLETE"
    )

    print("=" * 60)

    return vectorstore


# ============================================================
# RETRIEVAL
# ============================================================

def retrieve_documents(
    vectorstore,
    question,
    k=TOP_K
):

    print(
        f"\nSearching for: {question}"
    )

    documents = vectorstore.similarity_search(

        question,

        k=k
    )

    print(
        f"Retrieved {len(documents)} chunks."
    )

    return documents


# ============================================================
# GROQ LLM
# ============================================================

def get_groq():

    validate_api_key()

    llm = ChatGroq(

        model=GROQ_MODEL,

        temperature=0,

        max_tokens=1024
    )

    return llm


# ============================================================
# FORMAT CONTEXT
# ============================================================

def format_context(documents):

    context = []

    for i, document in enumerate(
        documents,
        start=1
    ):

        page = document.metadata.get(
            "page"
        )

        if page is not None:
            page += 1

        source = document.metadata.get(
            "source",
            "Unknown"
        )

        context.append(

            f"""
--- SOURCE {i} ---

Page: {page}

Source: {source}

Content:

{document.page_content}
"""
        )

    return "\n".join(context)


# ============================================================
# GENERATE ANSWER
# ============================================================

def generate_answer(
    question,
    documents
):

    if not documents:

        return (
            "I couldn't find the answer "
            "in the uploaded documents."
        )

    context = format_context(
        documents
    )

    prompt = ChatPromptTemplate.from_messages(

        [

            (
                "system",

                """
You are an AI Knowledge Copilot.

Answer the user's question using ONLY
the provided document context.

Rules:

1. Do not invent information.

2. Do not use outside knowledge.

3. If the answer cannot be found in
   the context, say:

   "I couldn't find the answer in
   the uploaded documents."

4. Give a clear and concise answer.

5. When possible, mention the page
   number containing the information.

Context:

{context}
"""
            ),

            (
                "human",

                """
Question:

{question}

Answer using the provided context.
"""
            )

        ]
    )

    llm = get_groq()

    chain = prompt | llm

    response = chain.invoke(

        {
            "context": context,

            "question": question
        }
    )

    return response.content


# ============================================================
# ASK QUESTION
# ============================================================

def ask_question(
    question,
    vectorstore=None
):

    if not question.strip():

        raise ValueError(
            "Question cannot be empty."
        )

    if vectorstore is None:

        vectorstore = load_vectorstore()

    # Retrieve relevant chunks

    documents = retrieve_documents(

        vectorstore,

        question
    )

    # Generate answer using Groq

    answer = generate_answer(

        question,

        documents
    )

    return answer, documents


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":

    validate_api_key()

    pdf_path = "documents/example.pdf"

    # Check whether FAISS already exists

    index_file = os.path.join(
        VECTORSTORE_PATH,
        "index.faiss"
    )

    pickle_file = os.path.join(
        VECTORSTORE_PATH,
        "index.pkl"
    )

    vectorstore_exists = (
        os.path.exists(index_file)
        and
        os.path.exists(pickle_file)
    )

    # Create or load vector store

    if not vectorstore_exists:

        print(
            "\nNo vector store found."
        )

        vectorstore = process_pdf(
            pdf_path
        )

    else:

        vectorstore = load_vectorstore()

    # Start chatbot

    print("\n" + "=" * 60)

    print(
        "AI KNOWLEDGE COPILOT"
    )

    print("=" * 60)

    print(
        "RAG pipeline is ready."
    )

    print(
        "Type 'exit' to quit."
    )

    while True:

        question = input(
            "\nYou: "
        )

        if question.lower().strip() == "exit":

            print(
                "Goodbye!"
            )

            break

        try:

            answer, documents = ask_question(

                question,

                vectorstore
            )

            print(
                "\nGroq:"
            )

            print(
                answer
            )

            print(
                "\nSources:"
            )

            for i, document in enumerate(

                documents,

                start=1
            ):

                page = document.metadata.get(
                    "page"
                )

                if page is not None:
                    page += 1

                print(
                    f"  Source {i} - Page {page}"
                )

        except Exception as error:

            print(
                f"\nError: {error}"
            )