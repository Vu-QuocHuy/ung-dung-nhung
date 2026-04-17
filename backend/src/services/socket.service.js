const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const SensorData = require("../models/SensorData");
const DeviceControl = require("../models/DeviceControl");
const ESP32Status = require("../models/ESP32Status");

let io = null;

const DEVICE_NAMES = [
  "pump",
  "fan",
  "light",
  "servo_door",
  "servo_feed",
  "led_farm",
  "led_animal",
  "led_hallway",
];

async function getLatestSensorSnapshot() {
  const sensorTypes = [
    "temperature",
    "humidity",
    "soil_moisture",
    "water_level",
    "light",
  ];
  const latestData = {};

  for (const type of sensorTypes) {
    const data = await SensorData.findOne({ sensorType: type })
      .sort({ createdAt: -1 })
      .limit(1);
    latestData[type] = data;
  }

  return latestData;
}

async function getDeviceStatusSnapshot() {
  const status = {};
  for (const device of DEVICE_NAMES) {
    const latest = await DeviceControl.findOne({ deviceName: device })
      .sort({ createdAt: -1 })
      .limit(1);
    status[device] = latest ? latest.status : "OFF";
  }

  const group = [status.led_farm, status.led_animal, status.led_hallway];
  const unique = Array.from(new Set(group));
  if (unique.length === 1) {
    status.light = unique[0];
  }

  return status;
}

async function getESP32StatusSnapshot() {
  let status = await ESP32Status.findOne({ deviceId: "esp32_main" });
  if (!status) {
    status = await ESP32Status.create({
      deviceId: "esp32_main",
      status: "offline",
      lastSeen: new Date(0),
    });
  }

  const isOnline = status.isOnline();
  const now = new Date();
  const lastSeenSeconds = Math.floor((now - status.lastSeen) / 1000);

  return {
    deviceId: status.deviceId,
    status: isOnline ? "online" : "offline",
    isOnline,
    lastSeen: status.lastSeen,
    lastSeenSeconds,
    ipAddress: status.ipAddress,
    updatedAt: status.updatedAt,
  };
}

async function emitInitialData(socket) {
  const [sensorData, deviceStatus, esp32Status] = await Promise.all([
    getLatestSensorSnapshot(),
    getDeviceStatusSnapshot(),
    getESP32StatusSnapshot(),
  ]);

  socket.emit("sensor:update", sensorData);
  socket.emit("device:status", deviceStatus);
  socket.emit("esp32:status", esp32Status);
}

function initSocket(httpServer) {
  if (io) {
    return io;
  }

  io = new Server(httpServer, {
    cors: {
      origin: process.env.FRONTEND_URL,
      credentials: true,
    },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
      return next(new Error("Unauthorized"));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      return next();
    } catch (error) {
      return next(new Error("Invalid token"));
    }
  });

  io.on("connection", async (socket) => {
    try {
      await emitInitialData(socket);
    } catch (error) {
      // Keep connection alive even if first snapshot fails.
      console.error("Failed to emit initial socket snapshot:", error);
    }
  });

  return io;
}

function getIO() {
  return io;
}

function emitSensorUpdate(payload) {
  if (io) {
    io.emit("sensor:update", payload);
  }
}

function emitDeviceStatus(payload) {
  if (io) {
    io.emit("device:status", payload);
  }
}

function emitESP32Status(payload) {
  if (io) {
    io.emit("esp32:status", payload);
  }
}

module.exports = {
  initSocket,
  getIO,
  emitSensorUpdate,
  emitDeviceStatus,
  emitESP32Status,
  getLatestSensorSnapshot,
  getDeviceStatusSnapshot,
  getESP32StatusSnapshot,
};
