import os
import shutil
import tempfile
import traceback

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

from rag_pipeline import (
    process_pdf,
    retrieve_documents,
    generate_answer
)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="AI Knowledge Copilot API",
    description="RAG API for PDF question answering",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# GLOBAL VECTOR STORE
# ============================================================

vectorstore = None


# ============================================================
# REQUEST MODEL
# ============================================================

class QuestionRequest(BaseModel):

    question: str


# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():

    return {
        "message": "AI Knowledge Copilot API is running",
        "status": "online"
    }


# ============================================================
# UPLOAD PDF
# ============================================================

@app.post("/upload")
async def upload_pdf(
    file: UploadFile = File(...)
):

    global vectorstore

    # --------------------------------------------------------
    # Validate file
    # --------------------------------------------------------

    if not file.filename:

        raise HTTPException(
            status_code=400,
            detail="No file selected."
        )

    if not file.filename.lower().endswith(".pdf"):

        raise HTTPException(
            status_code=400,
            detail="Only PDF files are supported."
        )

    temp_path = None

    try:

        print("\n" + "=" * 60)

        print(
            f"Uploading PDF: {file.filename}"
        )

        print("=" * 60)

        # ----------------------------------------------------
        # Save uploaded PDF temporarily
        # ----------------------------------------------------

        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=".pdf"
        ) as temp_file:

            temp_path = temp_file.name

            shutil.copyfileobj(
                file.file,
                temp_file
            )

        print(
            f"Temporary file created: {temp_path}"
        )

        # ----------------------------------------------------
        # Process PDF
        #
        # PDF
        # ↓
        # Text extraction
        # ↓
        # Chunking
        # ↓
        # Embeddings
        # ↓
        # FAISS
        # ----------------------------------------------------

        vectorstore = process_pdf(
            temp_path
        )

        print(
            "PDF processed successfully."
        )

        print(
            "=" * 60
        )

        return {
            "success": True,
            "message": "PDF processed successfully",
            "filename": file.filename
        }

    except Exception as e:

        print("\nERROR DURING PDF PROCESSING")

        traceback.print_exc()

        raise HTTPException(
            status_code=500,
            detail=f"{type(e).__name__}: {str(e)}"
        )

    finally:

        # ----------------------------------------------------
        # Delete temporary file
        # ----------------------------------------------------

        if (
            temp_path
            and
            os.path.exists(temp_path)
        ):

            os.remove(
                temp_path
            )

            print(
                "Temporary file deleted."
            )


# ============================================================
# ASK QUESTION
# ============================================================

@app.post("/ask")
async def ask_question(
    request: QuestionRequest
):

    global vectorstore

    # --------------------------------------------------------
    # Check vector store
    # --------------------------------------------------------

    if vectorstore is None:

        raise HTTPException(
            status_code=400,
            detail="Please upload and process a PDF first."
        )

    # --------------------------------------------------------
    # Validate question
    # --------------------------------------------------------

    question = request.question.strip()

    if not question:

        raise HTTPException(
            status_code=400,
            detail="Question cannot be empty."
        )

    try:

        print("\n" + "=" * 60)

        print(
            f"QUESTION: {question}"
        )

        print("=" * 60)

        # ----------------------------------------------------
        # STEP 1: RETRIEVE RELEVANT CHUNKS
        # ----------------------------------------------------

        print(
            "\n[1/2] Retrieving relevant chunks..."
        )

        documents = retrieve_documents(

            vectorstore,

            question
        )

        print(
            f"Retrieved {len(documents)} chunks."
        )

        # ----------------------------------------------------
        # STEP 2: GENERATE ANSWER
        # ----------------------------------------------------

        print(
            "\n[2/2] Generating answer with Groq..."
        )

        answer = generate_answer(

            question,

            documents
        )

        print(
            "Answer generated successfully."
        )

        # ----------------------------------------------------
        # BUILD SOURCES
        # ----------------------------------------------------

        sources = []

        for i, document in enumerate(
            documents,
            start=1
        ):

            page = document.metadata.get(
                "page"
            )

            # PyPDFLoader uses zero-based pages
            if page is not None:

                page += 1

            source = document.metadata.get(
                "source",
                "Unknown"
            )

            sources.append({

                "source_number": i,

                "page": page,

                "content": document.page_content,

                "source": source

            })

        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        response = {

            "success": True,

            "question": question,

            "answer": answer,

            "sources": sources

        }

        print(
            "\nRequest completed successfully."
        )

        print("=" * 60)

        return response

    except Exception as e:

        # ----------------------------------------------------
        # IMPORTANT:
        # Print complete traceback to FastAPI terminal
        # ----------------------------------------------------

        print("\n" + "=" * 60)

        print(
            "ERROR DURING QUESTION ANSWERING"
        )

        print("=" * 60)

        traceback.print_exc()

        print("=" * 60)

        raise HTTPException(

            status_code=500,

            detail={
                "error": type(e).__name__,
                "message": str(e)
            }
        )