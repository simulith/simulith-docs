exports.handler = async () => {
  let config = {};
  try {
    config = JSON.parse(process.env.CONFIG_JSON || "{}");
  } catch {
    /* invalid JSON — return empty config */
  }
  return {
    statusCode: 200,
    body: JSON.stringify({
      service: "simulith",
      managed_by: "terraform",
      username: config.username || "",
      secret_source: "env-from-data-source",
    }),
  };
};
