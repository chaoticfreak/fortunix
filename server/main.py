from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from pydantic_models.chat_body import ChatBody
from services.rag import get_rag_response

app = FastAPI()


@app.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            query = data.get("query")

            if not query:
                await websocket.send_json({"error": "Query is required"})
                continue

            rag_response = get_rag_response(query)
            await websocket.send_json({"response": rag_response})
    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        await websocket.send_json({"error": f"Unexpected error: {str(e)}"})
        await websocket.close()


@app.post("/chat")
def chat_endpoint(body: ChatBody):
    return {"response": get_rag_response(body.query)}
