require("dotenv").config();
const mongoose = require("mongoose");
const Schedule = require("../../src/models/Schedule");

async function run() {
  if (!process.env.MONGODB_URI) {
    throw new Error("MONGODB_URI is missing in environment");
  }

  await mongoose.connect(process.env.MONGODB_URI);

  // 1) Non-servo_feed schedules must not carry executionCount.
  const nonServoCleanup = await Schedule.updateMany(
    {
      deviceName: { $ne: "servo_feed" },
      executionCount: { $ne: null },
    },
    { $set: { executionCount: null } },
  );

  // 2) Convert numeric strings for servo_feed into integers.
  const servoStringDocs = await Schedule.find(
    {
      deviceName: "servo_feed",
      executionCount: { $type: "string" },
    },
    { _id: 1, executionCount: 1 },
  );

  let converted = 0;
  let nulled = 0;

  for (const doc of servoStringDocs) {
    const parsed = Number(doc.executionCount);
    if (Number.isInteger(parsed) && parsed >= 0) {
      doc.executionCount = parsed;
      converted += 1;
    } else {
      doc.executionCount = null;
      nulled += 1;
    }
    await doc.save();
  }

  console.log(
    JSON.stringify(
      {
        nonServoCleanup: {
          matched: nonServoCleanup.matchedCount,
          modified: nonServoCleanup.modifiedCount,
        },
        servoStringDocs: servoStringDocs.length,
        converted,
        nulled,
      },
      null,
      2,
    ),
  );
}

run()
  .catch((error) => {
    console.error("Migration failed:", error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      await mongoose.disconnect();
    } catch {
      // no-op
    }
  });
