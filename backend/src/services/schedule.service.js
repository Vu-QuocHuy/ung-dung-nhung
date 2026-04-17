const cron = require("node-cron");
const Schedule = require("../models/Schedule");
const mqttService = require("./mqtt.service");

class ScheduleService {
  constructor() {
    this.cronJob = null;

    // Guards to avoid re-executing start/end multiple times within the same minute
    this._executedKeys = new Map();

    // Runtime state for servo_feed schedules
    this._servoFeedWindowState = new Map();

    // Log throttling (avoid printing the same HH:MM many times per minute)
    this._lastCheckLogTimeKey = null;

    // Config
    this._tickExpression = "*/1 * * * * *"; // every 1 second for precise feed scheduling
    const envRepeat = parseInt(process.env.SERVO_FEED_REPEAT_MS || "5000", 10);
    this._servoFeedRepeatMs = Number.isFinite(envRepeat)
      ? Math.max(envRepeat, 4500)
      : 5000;

    const envCycle = parseInt(process.env.SERVO_FEED_CYCLE_MS || "4000", 10);
    this._servoFeedCycleMs = Number.isFinite(envCycle)
      ? Math.max(envCycle, 3500)
      : 4000;

    this._endClearDelayMs = 1500; // delay before S_CLEAR so OFF is observable
    this._timeZone =
      process.env.SCHEDULE_TIMEZONE || process.env.TZ || "Asia/Ho_Chi_Minh";
  }

  // Khởi động schedule checker
  start() {
    console.log("Starting Schedule Service...");

    this.cronJob = cron.schedule(this._tickExpression, async () => {
      await this.checkAndExecuteSchedules();
    });

    console.log(
      `Schedule Service started - checking every 1 second (${this._tickExpression}), timezone=${this._timeZone}`,
    );
  }

  _getNowInTimeZone() {
    const parts = new Intl.DateTimeFormat("en-GB", {
      timeZone: this._timeZone,
      hour12: false,
      weekday: "short",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    }).formatToParts(new Date());

    const map = {};
    for (const p of parts) {
      if (p.type !== "literal") map[p.type] = p.value;
    }

    const weekdayMap = {
      Sun: 0,
      Mon: 1,
      Tue: 2,
      Wed: 3,
      Thu: 4,
      Fri: 5,
      Sat: 6,
    };

    const currentDay = weekdayMap[map.weekday] ?? new Date().getDay();
    const currentTime = `${map.hour}:${map.minute}`;
    const currentSecondOfDay =
      parseInt(map.hour, 10) * 3600 +
      parseInt(map.minute, 10) * 60 +
      parseInt(map.second, 10);
    const dateKey = `${map.year}-${map.month}-${map.day}`;

    return { currentDay, currentTime, currentSecondOfDay, dateKey };
  }

  _toSeconds(hhmm) {
    const [h, m] = hhmm.split(":").map((v) => parseInt(v, 10));
    return h * 3600 + m * 60;
  }

  _shouldExecuteOnce(scheduleId, dateKey, timeKey, phase) {
    const key = `${scheduleId}:${dateKey}:${timeKey}:${phase}`;
    if (this._executedKeys.has(key)) return false;
    this._executedKeys.set(key, Date.now());
    return true;
  }

  _cleanupState(maxAgeMs = 36 * 60 * 60 * 1000) {
    const now = Date.now();

    for (const [k, ts] of this._executedKeys.entries()) {
      if (now - ts > maxAgeMs) this._executedKeys.delete(k);
    }

    for (const [k, st] of this._servoFeedWindowState.entries()) {
      if (!st || now - st.createdAtMs > maxAgeMs) {
        this._servoFeedWindowState.delete(k);
      }
    }
  }

  _planServoFeedWindow(schedule) {
    const windowStartSec = this._toSeconds(schedule.startTime);
    const windowEndSec = this._toSeconds(schedule.endTime);
    const durationSec = windowEndSec - windowStartSec;
    const durationMs = durationSec * 1000;
    const cycleSec = Math.ceil(this._servoFeedCycleMs / 1000);
    const latestStartSec = windowEndSec - cycleSec;

    const requestedCount = Number.isInteger(schedule.executionCount)
      ? schedule.executionCount
      : 0;

    // Legacy behavior: if count is absent/invalid, keep repeating in-window
    if (requestedCount <= 0) {
      return {
        windowStartSec,
        windowEndSec,
        latestStartSec,
        requestedCount,
        plannedCount: 0,
        intervalMs: this._servoFeedRepeatMs,
        intervalSec: this._servoFeedRepeatMs / 1000,
        clamped: false,
      };
    }

    // Clamp to physically feasible maximum based on one feed cycle duration
    const feasibleMax = Math.max(
      1,
      Math.floor(durationMs / this._servoFeedCycleMs),
    );
    const plannedCount = Math.min(requestedCount, feasibleMax);

    // Spread run start times from window start to latest safe start.
    const intervalSec =
      plannedCount > 1
        ? (latestStartSec - windowStartSec) / (plannedCount - 1)
        : 0;
    const intervalMs = Math.max(
      this._servoFeedCycleMs,
      Math.floor(intervalSec * 1000),
    );

    return {
      windowStartSec,
      windowEndSec,
      latestStartSec,
      requestedCount,
      plannedCount,
      intervalMs,
      intervalSec,
      clamped: plannedCount !== requestedCount,
    };
  }

  _ensureServoFeedWindowState(schedule, dateKey) {
    const sid = schedule._id.toString();
    const stateKey = `${sid}:${dateKey}`;
    let st = this._servoFeedWindowState.get(stateKey);

    if (!st) {
      const plan = this._planServoFeedWindow(schedule);
      st = {
        ...plan,
        executedCount: 0,
        nextDueAtMs: Date.now(),
        lastIssuedAtMs: 0,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        createdAtMs: Date.now(),
      };
      this._servoFeedWindowState.set(stateKey, st);

      const countDesc =
        st.plannedCount > 0
          ? `${st.plannedCount} lần, mỗi ~${Math.max(1, Math.round(st.intervalSec))}s`
          : `lặp liên tục mỗi ${Math.round(st.intervalMs / 1000)}s`;
      const clampDesc = st.clamped
        ? ` (clamped từ ${st.requestedCount} xuống ${st.plannedCount})`
        : "";

      console.log(
        `[Schedule] Servo feed plan: ${schedule.name} -> ${countDesc}${clampDesc}`,
      );
    }

    return { sid, stateKey, st };
  }

  async checkAndExecuteSchedules() {
    try {
      const { currentDay, currentTime, currentSecondOfDay, dateKey } =
        this._getNowInTimeZone();

      this._cleanupState();

      const schedules = await Schedule.find({
        enabled: true,
        daysOfWeek: currentDay,
      });

      if (schedules.length > 0 && this._lastCheckLogTimeKey !== currentTime) {
        this._lastCheckLogTimeKey = currentTime;
        console.log(
          `[Schedule] Checking ${schedules.length} schedule(s) at ${currentTime}`,
        );
      }

      for (const schedule of schedules) {
        try {
          const isServoDoor = schedule.deviceName === "servo_door";
          const isServoFeed = schedule.deviceName === "servo_feed";

          const startSec = this._toSeconds(schedule.startTime);
          const endSec = this._toSeconds(schedule.endTime);
          const inWindow =
            currentSecondOfDay >= startSec && currentSecondOfDay < endSec;

          if (currentTime === schedule.startTime) {
            if (
              this._shouldExecuteOnce(
                schedule._id.toString(),
                dateKey,
                schedule.startTime,
                "start",
              )
            ) {
              console.log(
                `[Schedule] Start: ${schedule.name} - ${schedule.deviceName} ${schedule.action}`,
              );

              if (isServoDoor) {
                if (schedule.action === "RUN") {
                  mqttService.publishRawCommand(schedule.deviceName, "RUN");
                } else if (schedule.action === "ON") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_ON");
                } else if (schedule.action === "OFF") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_OFF");
                } else if (schedule.action === "AUTO") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_CLEAR");
                }
              } else if (!isServoFeed) {
                if (schedule.action === "AUTO") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_CLEAR");
                } else if (schedule.action === "ON") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_ON");
                } else if (schedule.action === "OFF") {
                  mqttService.publishRawCommand(schedule.deviceName, "S_OFF");
                }
              }

              console.log(`[Schedule] ✓ Start executed: ${schedule.name}`);
            }
          }

          if (isServoFeed && inWindow) {
            if (schedule.action === "RUN" || schedule.action === "ON") {
              const { st } = this._ensureServoFeedWindowState(
                schedule,
                dateKey,
              );

              if (
                st.startTime !== schedule.startTime ||
                st.endTime !== schedule.endTime
              ) {
                const sid = schedule._id.toString();
                this._servoFeedWindowState.delete(`${sid}:${dateKey}`);
                continue;
              }

              if (st.plannedCount > 0 && st.executedCount >= st.plannedCount) {
                continue;
              }

              const nowMs = Date.now();
              const cycleSec = Math.ceil(this._servoFeedCycleMs / 1000);
              const canFinishBeforeEnd =
                currentSecondOfDay + cycleSec <= st.windowEndSec;

              if (!canFinishBeforeEnd) {
                continue;
              }

              if (st.plannedCount > 0) {
                const targetStartSec =
                  st.windowStartSec + st.executedCount * st.intervalSec;
                const dueByTarget = currentSecondOfDay >= targetStartSec;
                const cooldownOk =
                  st.lastIssuedAtMs === 0 ||
                  nowMs - st.lastIssuedAtMs >= this._servoFeedCycleMs;

                if (dueByTarget && cooldownOk && nowMs >= st.nextDueAtMs) {
                  mqttService.publishRawCommand(schedule.deviceName, "RUN");
                  st.executedCount += 1;
                  st.lastIssuedAtMs = nowMs;
                  st.nextDueAtMs = nowMs + this._servoFeedCycleMs;

                  console.log(
                    `[Schedule] Servo feed RUN: ${schedule.name} (${st.executedCount}/${st.plannedCount})`,
                  );

                  if (st.executedCount >= st.plannedCount) {
                    console.log(
                      `[Schedule] Servo feed completed: ${schedule.name} (${st.executedCount}/${st.plannedCount})`,
                    );
                  }
                }
              } else {
                const cooldownOk =
                  st.lastIssuedAtMs === 0 ||
                  nowMs - st.lastIssuedAtMs >= st.intervalMs;

                if (cooldownOk && nowMs >= st.nextDueAtMs) {
                  mqttService.publishRawCommand(schedule.deviceName, "RUN");
                  st.executedCount += 1;
                  st.lastIssuedAtMs = nowMs;
                  st.nextDueAtMs = nowMs + st.intervalMs;

                  console.log(
                    `[Schedule] Servo feed RUN: ${schedule.name} (${st.executedCount}/∞)`,
                  );
                }
              }
            }
          } else if (isServoFeed && !inWindow) {
            const sid = schedule._id.toString();
            const stateKey = `${sid}:${dateKey}`;
            if (this._servoFeedWindowState.has(stateKey)) {
              this._servoFeedWindowState.delete(stateKey);
            }
          }

          if (currentTime === schedule.endTime) {
            if (isServoFeed) continue;

            if (
              this._shouldExecuteOnce(
                schedule._id.toString(),
                dateKey,
                schedule.endTime,
                "end",
              )
            ) {
              console.log(
                `[Schedule] End: ${schedule.name} - ${schedule.deviceName} (OFF then back to AUTO)`,
              );

              mqttService.publishRawCommand(schedule.deviceName, "S_OFF");
              setTimeout(() => {
                mqttService.publishRawCommand(schedule.deviceName, "S_CLEAR");
              }, this._endClearDelayMs);

              console.log(
                `[Schedule] ✓ End executed (S_OFF + delayed S_CLEAR): ${schedule.name}`,
              );
            }
          }
        } catch (error) {
          console.error(
            `[Schedule] ✗ Failed to execute ${schedule.name}:`,
            error.message,
          );
        }
      }
    } catch (error) {
      console.error("[Schedule] Error checking schedules:", error);
    }
  }

  stop() {
    if (this.cronJob) {
      this.cronJob.stop();
      console.log("Schedule Service stopped");
    }
  }
}

module.exports = new ScheduleService();
