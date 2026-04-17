const mongoose = require("mongoose");

const ScheduleSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    deviceName: {
      type: String,
      required: true,
    },
    // Hành động áp dụng tại thời điểm bắt đầu (thường là ON/AUTO)
    action: {
      type: String,
      required: true,
      enum: ["ON", "OFF", "RUN", "AUTO"],
    },
    // Thời gian bắt đầu (HH:mm)
    startTime: {
      type: String,
      required: true,
      match: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/,
    },
    // Thời gian kết thúc (HH:mm)
    endTime: {
      type: String,
      required: true,
      match: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/,
    },
    daysOfWeek: {
      type: [Number],
      default: [0, 1, 2, 3, 4, 5, 6], // 0=CN, 1=T2...
      validate: {
        validator: function (v) {
          return v.every((day) => day >= 0 && day <= 6);
        },
        message: "Ngày trong tuần phải từ 0-6",
      },
    },
    enabled: {
      type: Boolean,
      default: true,
    },
    // Số lần thực hiện trong khung giờ (chỉ áp dụng cho servo_feed)
    // null => hành vi cũ: lặp liên tục trong khung giờ
    executionCount: {
      type: Number,
      default: null,
      min: 0,
      max: 1440,
      validate: {
        validator: function (value) {
          return (
            value === null || value === undefined || Number.isInteger(value)
          );
        },
        message: "Số lần thực hiện phải là số nguyên",
      },
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Schedule", ScheduleSchema);
