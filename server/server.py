import asyncio
import json
import cv2
import numpy as np
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import mediapipe as mp

app = FastAPI()

# CORS configuration for local development
origins = [
    "http://localhost:5500",
    "http://localhost:5501",
    "http://127.0.0.1:5500",
    # Add more origins as needed
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # Adjust as necessary
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize MediaPipe Pose
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        print(f"Client connected: {websocket.client}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            print(f"Client disconnected: {websocket.client}")

    async def broadcast(self, message: str):
        """Send a message to all connected clients."""
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                print(f"Error sending to client: {e}")
                self.disconnect(connection)

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            try:
                # Handle text messages (e.g., "ping")
                data = await websocket.receive_text()
                if data == "ping":
                    # Respond with a "pong" message
                    response = json.dumps({"message": "pong"})
                    await manager.broadcast(response)
                    print("Pong broadcasted")
                else:
                    print(f"Received unexpected text message: {data}")
            except WebSocketDisconnect:
                manager.disconnect(websocket)
                break
            except Exception:
                # Handle binary data (image frames)
                try:
                    data = await websocket.receive_bytes()
                    # Decode the image
                    nparr = np.frombuffer(data, np.uint8)
                    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                    if img is None:
                        print("Failed to decode image")
                        continue

                    # Convert to RGB for MediaPipe
                    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                    results = pose.process(img_rgb)

                    if results.pose_landmarks:
                        landmarks = []
                        for landmark in results.pose_landmarks.landmark:
                            landmarks.append({
                                "x": landmark.x,
                                "y": landmark.y,
                                "z": landmark.z,
                                "visibility": landmark.visibility
                            })
                        # Send landmarks to all clients
                        response = json.dumps({"landmarks": landmarks})
                        await manager.broadcast(response)
                    else:
                        # Send empty landmarks to all clients
                        response = json.dumps({"landmarks": []})
                        await manager.broadcast(response)
                        print("Empty landmarks broadcasted")
                except WebSocketDisconnect:
                    manager.disconnect(websocket)
                    break
                except Exception as e_inner:
                    print(f"Error processing message: {e_inner}")
                    manager.disconnect(websocket)
                    break
    except Exception as e:
        print(f"Unexpected error: {e}")
        manager.disconnect(websocket)
