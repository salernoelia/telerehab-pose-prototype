// client/script.js

const video = document.getElementById("video");
const canvas = document.getElementById("canvas");
const coordsDisplay = document.getElementById("coords");

const ws = new WebSocket("ws://localhost:8000/ws");

ws.binaryType = "arraybuffer";

ws.onopen = () => {
  console.log("WebSocket connection established");
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  coordsDisplay.textContent = JSON.stringify(data.landmarks, null, 2);
};

ws.onerror = (error) => {
  console.error("WebSocket error:", error);
};

ws.onclose = () => {
  console.log("WebSocket connection closed");
};

navigator.mediaDevices
  .getUserMedia({ video: true, audio: false })
  .then((stream) => {
    video.srcObject = stream;
    video.play();
  })
  .catch((err) => {
    console.error("Error accessing webcam:", err);
  });

video.addEventListener("play", () => {
  const context = canvas.getContext("2d");

  const sendFrame = () => {
    if (video.paused || video.ended) {
      return;
    }

    context.drawImage(video, 0, 0, canvas.width, canvas.height);

    canvas.toBlob(
      (blob) => {
        if (blob) {
          const reader = new FileReader();
          reader.onload = () => {
            const arrayBuffer = reader.result;
            ws.send(arrayBuffer);
          };
          reader.readAsArrayBuffer(blob);
        }
      },
      "image/jpeg",
      0.7
    );

    setTimeout(sendFrame, 25);
  };

  sendFrame();
});
