import { io, Socket } from "socket.io-client";
import { API_CONFIG } from "../config/api.config";

let socket: Socket | null = null;

export const getSocket = (): Socket => {
  if (!socket) {
    socket = io(API_CONFIG.SOCKET_URL, {
      path: "/socket.io",
      transports: ["websocket"],
      autoConnect: false,
      withCredentials: true,
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      timeout: 10000,
      auth: {
        token: localStorage.getItem("accessToken"),
      },
    });
  }
  return socket;
};

export const connectSocket = (): void => {
  const token = localStorage.getItem("accessToken");
  if (!token) return;

  const client = getSocket();
  client.auth = { token };

  if (!client.connected) {
    client.connect();
  }
};

export const disconnectSocket = (): void => {
  if (socket?.connected) {
    socket.disconnect();
  }
};
