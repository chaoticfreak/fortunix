import os
import uuid
from dotenv import load_dotenv

import google.generativeai as genai
from langchain_google_genai import GoogleGenerativeAIEmbeddings
import pymupdf as fitz
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFDirectoryLoader
from langchain_chroma import Chroma

from langchain_core.messages import HumanMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.stores import InMemoryStore
from langchain_core.documents import Document
from langchain_core.runnables import RunnableLambda, RunnablePassthrough

from langchain.retrievers.multi_vector import MultiVectorRetriever

# Load environment variables
load_dotenv()
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
MODEL_NAME = "gemini-2.0-flash"
embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")

rag_chain = None  # global chain

def data_ingestion():
    loader = PyPDFDirectoryLoader("data")
    documents = loader.load()
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=10000, chunk_overlap=1000)
    return text_splitter.split_documents(documents)

def extract_data(file_path):
    texts = []
    tables = []
    try:
        doc = fitz.open(file_path)
        for page_num in range(len(doc)):
            page = doc[page_num]

    # Extract text
            page_text = page.get_text()
            if page_text.strip():
                texts.append(page_text)
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
    finally:
        if 'doc' in locals():
            doc.close()
    return texts, tables

def make_prompt(element):
    return f"""You are an assistant tasked with summarising tables and text for retrieval.\
     These summaries will be embedded and used to retrieve the raw text or table elements.\
     Give a concise summary of the table or text that is well optimized for retrieval. Table or text : {element} """

def generate_text_summaries(texts, tables, summarize_texts=False):
    text_summaries, table_summaries = [], []
    model = genai.GenerativeModel(model_name=MODEL_NAME)
    if texts and summarize_texts:
        text_summaries = [model.generate_content(make_prompt(text)).text for text in texts]
    elif texts:
        text_summaries = texts
    if tables:
        table_summaries = [model.generate_content(make_prompt(table)).text for table in tables]
    return text_summaries, table_summaries

def create_multi_vector_retriever(vectorstore, text_summaries, texts, table_summaries, tables):
    store = InMemoryStore()
    id_key = "doc_id"
    retriever = MultiVectorRetriever(
        vectorstore=vectorstore,
        docstore=store,
        id_key=id_key,
    )
    def add_documents(retriever, doc_summaries, doc_contents):
        if not doc_summaries or not doc_contents:
            return
        doc_ids = [str(uuid.uuid4()) for _ in doc_contents]
        summary_docs = [
            Document(page_content=s, metadata={id_key: doc_ids[i]})
            for i, s in enumerate(doc_summaries)
        ]
        retriever.vectorstore.add_documents(summary_docs)
        retriever.docstore.mset(list(zip(doc_ids, doc_contents)))
    if text_summaries:
        add_documents(retriever, text_summaries, texts)
    if table_summaries:
        add_documents(retriever, table_summaries, tables)
    return retriever

def process_texts(docs):
    return {
        "texts": [
            doc.page_content if isinstance(doc, Document) else doc
            for doc in docs
        ]
    }

def text_prompt_func(data_dict):
    formatted_texts = "\n".join(data_dict["context"]["texts"])
    return [HumanMessage(content=(
        "You are financial analyst tasking with providing investment advice.\n"
        "You will be given text and tables if not then use the data present.\n"
        "Use this information to provide investment advice related to the user question.\n"
        f"User-provided question: {data_dict['question']}\n\n"
        "Text and / or tables:\n"
        f"{formatted_texts}"
    ))]

def text_rag_chain(retriever):
    from langchain_google_genai import ChatGoogleGenerativeAI
    model = ChatGoogleGenerativeAI(
        model=MODEL_NAME,
        temperature=0.7
    )
    chain = (
            {
                "context": retriever | RunnableLambda(process_texts),
                "question": RunnablePassthrough(),
            }
            | RunnableLambda(text_prompt_func)
            | model
            | StrOutputParser()
    )
    return chain

def initialize_rag_system():
    global rag_chain
    if os.path.exists("chroma_db"):
        print("Using existing Chroma vectorstore")
        vectorstore = Chroma(
            embedding_function=embeddings,
            persist_directory="chroma_db"
        )
        retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
        rag_chain = text_rag_chain(retriever)
        return

    docs = data_ingestion()
    all_texts, all_tables = [], []
    for doc in docs:
        texts, tables = extract_data(doc.metadata['source'])
        all_texts.extend(texts)
        all_tables.extend(tables)

    text_summaries, table_summaries = generate_text_summaries(all_texts, all_tables)

    vectorstore = Chroma(
        embedding_function=embeddings,
        persist_directory="chroma_db"
    )
    retriever = create_multi_vector_retriever(
        vectorstore=vectorstore,
        text_summaries=text_summaries,
        texts=all_texts,
        table_summaries=table_summaries,
        tables=all_tables
    )
    rag_chain = text_rag_chain(retriever)

def get_rag_response(query: str) -> str:
    global rag_chain
    if rag_chain is None:
        try:
            initialize_rag_system()
        except Exception as e:
            return f"RAG system error: {str(e)}"
    try:
        return rag_chain.invoke(query)
    except Exception as e:
        return f"Error during query processing: {str(e)}"


# Standalone CLI test
if __name__ == "__main__":
    query = input("Ask a financial question: ")
    print("Generating response...")
    print(get_rag_response(query))
