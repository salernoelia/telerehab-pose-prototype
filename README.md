# Telerehab Prototype

A Python-based WebSocket server using FastAPI to process real-time video frames from a client, estimate human poses using MediaPipe, and send back pose landmark data. This project is designed to offload computational tasks from the client to the server and broadcast it to a Godot instance.

---

## Features

- One-way video stream from client to server.
- Server processes frames using MediaPipe Pose.
- Real-time pose landmark extraction and transmission back to the client.

---

## Setup Instructions

Tested only on macOS so far.

### Prerequisites

- Python 3.10.14 (or the version you used)
- Virtual environment tool (optional but recommended)

### Steps to Set Up the Project

1. Clone the repository:

   ```bash
   git clone <repo-url>
   cd <repo-directory>
   ```

2. Create and activate a virtual environment:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Run the server:

   ```bash
   cd server
   uvicorn server:app --host 0.0.0.0 --port 8000
   ```

5. Serve the client:

   ```bash
   cd ../client
   python3 -m http.server 5500
   # or with live server
   ```

---

# Interpret the data

Based on Mediapipe documentation:

![pose-landmakrs](https://camo.githubusercontent.com/d3afebfc801ee1a094c28604c7a0eb25f8b9c9925f75b0fff4c8c8b4871c0d28/68747470733a2f2f6d65646961706970652e6465762f696d616765732f6d6f62696c652f706f73655f747261636b696e675f66756c6c5f626f64795f6c616e646d61726b732e706e67)

---

## MIT License

This project is licensed under the MIT License. See the LICENSE file for more information.
