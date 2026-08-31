import os
import tempfile

import streamlit as st

from rag_pipeline import (
    load_pdf,
    split_documents,
    create_vectorstore,
    load_vectorstore,
    retrieve_documents,
    generate_answer,
    VECTORSTORE_PATH
)


# ============================================================
# PAGE CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="AI Knowledge Copilot",
    page_icon="🤖",
    layout="wide"
)


# ============================================================
# TITLE
# ============================================================

st.title("🤖 AI Knowledge Copilot")

st.write(
    "Upload a PDF and ask questions about its contents."
)


# ============================================================
# SIDEBAR - PDF UPLOAD
# ============================================================

with st.sidebar:

    st.header("📄 Upload Document")

    uploaded_file = st.file_uploader(
        "Choose a PDF",
        type=["pdf"]
    )

    if uploaded_file:

        st.success(
            f"Selected: {uploaded_file.name}"
        )

        if st.button(
            "Process PDF",
            use_container_width=True
        ):

            with st.spinner(
                "Processing PDF..."
            ):

                # ------------------------------------------------
                # Save uploaded PDF temporarily
                # ------------------------------------------------

                with tempfile.NamedTemporaryFile(
                    delete=False,
                    suffix=".pdf"
                ) as temp_file:

                    temp_file.write(
                        uploaded_file.getvalue()
                    )

                    pdf_path = temp_file.name

                try:

                    # ------------------------------------------------
                    # 1. Extract text from PDF
                    # ------------------------------------------------

                    documents = load_pdf(
                        pdf_path
                    )

                    # ------------------------------------------------
                    # 2. Split text into chunks
                    # ------------------------------------------------

                    chunks = split_documents(
                        documents
                    )

                    # ------------------------------------------------
                    # 3. Create embeddings + FAISS
                    # ------------------------------------------------

                    vectorstore = create_vectorstore(
                        chunks
                    )

                    # Store vectorstore in session
                    st.session_state[
                        "vectorstore"
                    ] = vectorstore

                    st.session_state[
                        "document_name"
                    ] = uploaded_file.name

                    st.success(
                        f"Processed {len(chunks)} chunks!"
                    )

                except Exception as e:

                    st.error(
                        f"Error processing PDF: {e}"
                    )

                finally:

                    # Delete temporary file
                    if os.path.exists(pdf_path):

                        os.remove(
                            pdf_path
                        )


# ============================================================
# LOAD EXISTING VECTOR STORE
# ============================================================

index_file = os.path.join(
    VECTORSTORE_PATH,
    "index.faiss"
)

pickle_file = os.path.join(
    VECTORSTORE_PATH,
    "index.pkl"
)


if (
    "vectorstore" not in st.session_state
    and os.path.exists(index_file)
    and os.path.exists(pickle_file)
):

    try:

        st.session_state[
            "vectorstore"
        ] = load_vectorstore()

    except Exception as e:

        st.warning(
            f"Could not load existing vector store: {e}"
        )


# ============================================================
# CURRENT DOCUMENT
# ============================================================

if "document_name" in st.session_state:

    st.info(
        f"📄 Current document: "
        f"{st.session_state['document_name']}"
    )


# ============================================================
# QUESTION
# ============================================================

st.subheader("Ask a Question")

question = st.text_input(
    "Ask a question about your document:"
)


# ============================================================
# ASK BUTTON
# ============================================================

if st.button(
    "Ask",
    type="primary",
    use_container_width=True
):

    # --------------------------------------------------------
    # Validate question
    # --------------------------------------------------------

    if not question.strip():

        st.warning(
            "Please enter a question."
        )

    # --------------------------------------------------------
    # Check vector store
    # --------------------------------------------------------

    elif "vectorstore" not in st.session_state:

        st.warning(
            "Please upload and process a PDF first."
        )

    else:

        vectorstore = st.session_state[
            "vectorstore"
        ]

        # ----------------------------------------------------
        # RAG
        # ----------------------------------------------------

        with st.spinner(
            "Searching document and generating answer..."
        ):

            try:

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

                # ------------------------------------------------
                # ANSWER
                # ------------------------------------------------

                st.subheader("💡 Answer")

                st.write(answer)

                # ------------------------------------------------
                # SOURCES
                # ------------------------------------------------

                st.subheader("📚 Retrieved Sources")

                if documents:

                    for i, document in enumerate(
                        documents,
                        start=1
                    ):

                        # PyPDFLoader uses zero-based
                        # page numbers
                        page = document.metadata.get(
                            "page"
                        )

                        if page is not None:

                            page += 1

                        with st.expander(
                            f"Source {i} — Page {page}"
                        ):

                            st.write(
                                document.page_content
                            )

                            st.caption(
                                f"Source: "
                                f"{document.metadata.get(
                                    'source',
                                    'Unknown'
                                )}"
                            )

                else:

                    st.info(
                        "No relevant sources found."
                    )

            except Exception as e:

                st.error(
                    f"Error: {e}"
                )


# ============================================================
# FOOTER
# ============================================================

st.divider()

st.caption(
    "AI Knowledge Copilot • "
    "RAG + FAISS + Local Embeddings + Groq"
)