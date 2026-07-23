exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({
    service: "simulith",
    managed_by: "terraform",
    greeting: process.env.GREETING || "",
    records: (event.Records || []).length,
  }),
});
