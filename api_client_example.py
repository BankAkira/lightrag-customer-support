"""
Customer Support Chat API Client
Simple example to interact with LightRAG for customer support
"""

import requests
import json
from typing import List, Optional

class CustomerSupportRAG:
    def __init__(self, base_url: str = "http://localhost:9621"):
        self.base_url = base_url
        self.api_url = f"{base_url}/v1"
        
    def health_check(self) -> bool:
        """Check if LightRAG server is healthy"""
        try:
            response = requests.get(f"{self.base_url}/health")
            return response.status_code == 200
        except Exception as e:
            print(f"Health check failed: {e}")
            return False
    
    def index_documents(self, documents: List[str], doc_ids: Optional[List[str]] = None) -> dict:
        """
        Index documents into LightRAG

        Args:
            documents: List of document texts (Thai/English supported)
            doc_ids: Optional list of document IDs

        Returns:
            Response from the API

        Raises:
            ValueError: If documents list is empty
            requests.HTTPError: If API request fails
        """
        if not documents:
            raise ValueError("Documents list cannot be empty")

        if doc_ids and len(doc_ids) != len(documents):
            raise ValueError(f"Number of doc_ids ({len(doc_ids)}) must match number of documents ({len(documents)})")

        payload = {
            "documents": documents
        }
        if doc_ids:
            payload["doc_ids"] = doc_ids

        try:
            response = requests.post(
                f"{self.api_url}/documents/index",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=300
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
            print(f"Response: {response.text}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def query(
        self,
        question: str,
        mode: str = "hybrid",
        language: str = "auto",
        conversation_history: Optional[List[dict]] = None
    ) -> dict:
        """
        Query LightRAG for customer support

        Args:
            question: Customer question in Thai or English
            mode: Query mode (local/global/hybrid/mix/naive)
            language: Response language preference
            conversation_history: Previous conversation context

        Returns:
            Answer and context

        Raises:
            ValueError: If question is empty or mode is invalid
            requests.HTTPError: If API request fails
        """
        if not question or not question.strip():
            raise ValueError("Question cannot be empty")

        valid_modes = ["local", "global", "hybrid", "mix", "naive"]
        if mode not in valid_modes:
            raise ValueError(f"Invalid mode '{mode}'. Must be one of: {valid_modes}")

        payload = {
            "query": question,
            "mode": mode,
            "top_k": 60,
            "chunk_top_k": 20,
            "enable_rerank": True,
            "response_type": "Multiple Paragraphs"
        }

        if conversation_history:
            payload["conversation_history"] = conversation_history

        try:
            response = requests.post(
                f"{self.api_url}/query",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=120
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
            print(f"Response: {response.text}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def stream_query(
        self,
        question: str,
        mode: str = "hybrid"
    ):
        """
        Stream query response from LightRAG

        Args:
            question: Customer question
            mode: Query mode

        Yields:
            Chunks of response text

        Raises:
            ValueError: If question is empty or mode is invalid
            requests.HTTPError: If API request fails
        """
        if not question or not question.strip():
            raise ValueError("Question cannot be empty")

        valid_modes = ["local", "global", "hybrid", "mix", "naive"]
        if mode not in valid_modes:
            raise ValueError(f"Invalid mode '{mode}'. Must be one of: {valid_modes}")

        payload = {
            "query": question,
            "mode": mode,
            "stream": True,
            "enable_rerank": True
        }

        try:
            response = requests.post(
                f"{self.api_url}/query",
                json=payload,
                headers={"Content-Type": "application/json"},
                stream=True,
                timeout=120
            )
            response.raise_for_status()

            for line in response.iter_lines():
                if line:
                    yield line.decode('utf-8')
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
            if hasattr(response, 'text'):
                print(f"Response: {response.text}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise
    
    def get_entities(self, entity_name: Optional[str] = None) -> dict:
        """
        Get entities from knowledge graph

        Args:
            entity_name: Optional entity name filter

        Returns:
            Dictionary containing entities

        Raises:
            requests.HTTPError: If API request fails
        """
        params = {"entity_name": entity_name} if entity_name else {}
        try:
            response = requests.get(
                f"{self.api_url}/entities",
                params=params,
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
            print(f"Response: {response.text}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise

    def delete_document(self, doc_id: str) -> dict:
        """
        Delete a document by ID

        Args:
            doc_id: Document ID to delete

        Returns:
            Response from the API

        Raises:
            ValueError: If doc_id is empty
            requests.HTTPError: If API request fails
        """
        if not doc_id or not doc_id.strip():
            raise ValueError("Document ID cannot be empty")

        try:
            response = requests.delete(
                f"{self.api_url}/documents/{doc_id}",
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e}")
            print(f"Response: {response.text}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            raise


# Example Usage
if __name__ == "__main__":
    # Initialize client
    client = CustomerSupportRAG("http://localhost:9621")
    
    # Check health
    if not client.health_check():
        print("❌ LightRAG server is not available")
        exit(1)
    
    print("✅ Connected to LightRAG server")
    
    # Example 1: Index product documentation (Thai + English)
    print("\n📚 Indexing product documents...")
    documents = [
        """
        สินค้า: โปรแกรม AI Chat Support Pro
        ฟีเจอร์หลัก:
        - รองรับภาษาไทยและอังกฤษ
        - ใช้เทคโนโลยี RAG (Retrieval-Augmented Generation)
        - ตอบคำถามลูกค้าอัตโนมัติ 24/7
        - รองรับการค้นหาข้อมูลจากเอกสารหลายรูปแบบ
        
        ราคา: 
        - แพ็กเกจ Starter: 9,900 บาท/เดือน
        - แพ็กเกจ Professional: 19,900 บาท/เดือน  
        - แพ็กเกจ Enterprise: ติดต่อเรา
        
        การติดตั้ง:
        1. ดาวน์โหลดไฟล์ Docker Compose
        2. รัน docker-compose up -d
        3. เข้าสู่ระบบที่ http://localhost:9621
        """,
        
        """
        Product: AI Chat Support Pro
        Main Features:
        - Supports Thai and English languages
        - Uses RAG (Retrieval-Augmented Generation) technology
        - Automated customer support 24/7
        - Multi-format document search support
        
        Pricing:
        - Starter Package: 9,900 THB/month
        - Professional Package: 19,900 THB/month
        - Enterprise Package: Contact us
        
        Installation:
        1. Download Docker Compose file
        2. Run docker-compose up -d
        3. Access at http://localhost:9621
        
        Common Issues:
        - GPU not detected: Make sure NVIDIA Docker runtime is installed
        - Connection timeout: Check if all services are healthy
        - Out of memory: Reduce gpu-memory-utilization in docker-compose.yml
        """
    ]
    
    result = client.index_documents(
        documents=documents,
        doc_ids=["product-doc-th-001", "product-doc-en-001"]
    )
    print(f"Indexed: {result}")
    
    # Example 2: Customer query in Thai
    print("\n💬 Customer Question (Thai):")
    question_th = "ราคาแพ็กเกจ Professional เท่าไหร่คะ?"
    print(f"Q: {question_th}")
    
    answer = client.query(
        question=question_th,
        mode="hybrid"
    )
    print(f"A: {answer.get('response', 'No response')}")
    
    # Example 3: Customer query in English
    print("\n💬 Customer Question (English):")
    question_en = "How do I install the AI Chat Support Pro?"
    print(f"Q: {question_en}")
    
    answer = client.query(
        question=question_en,
        mode="hybrid"
    )
    print(f"A: {answer.get('response', 'No response')}")
    
    # Example 4: Conversational query with context
    print("\n💬 Follow-up Question:")
    conversation_history = [
        {"role": "user", "content": "What are the pricing options?"},
        {"role": "assistant", "content": "We offer three packages: Starter (9,900 THB/month), Professional (19,900 THB/month), and Enterprise (contact us)."}
    ]
    
    followup = "What features are included in the Professional package?"
    print(f"Q: {followup}")
    
    answer = client.query(
        question=followup,
        mode="hybrid",
        conversation_history=conversation_history
    )
    print(f"A: {answer.get('response', 'No response')}")
    
    # Example 5: Stream response
    print("\n🌊 Streaming Response:")
    question_stream = "อธิบายขั้นตอนการติดตั้งแบบละเอียด"
    print(f"Q: {question_stream}")
    print("A: ", end="", flush=True)
    
    for chunk in client.stream_query(question_stream, mode="hybrid"):
        print(chunk, end="", flush=True)
    print()
