const fs = require("fs");
const path = require("path");

exports.handler = async (event) => {
  const rec = (event.Records || [])[0];
  if (!rec) {
    return { ok: false, reason: "no Records" };
  }
  const key = rec.s3?.object?.key || "unknown";
  const eventName = rec.eventName || "unknown";
  const markerDir = process.env.MARKER_DIR || "/tmp/simulith-s3-lambda";
  fs.mkdirSync(markerDir, { recursive: true });
  const safe = key.replace(/\//g, "_");
  const markerPath = path.join(markerDir, `${safe}.done`);
  fs.writeFileSync(
    markerPath,
    JSON.stringify({ key, eventName, bucket: rec.s3?.bucket?.name }),
  );
  return { ok: true, key, eventName, markerPath };
};
