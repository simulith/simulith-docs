exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({
    service: "simulith",
    managed_by: "terraform",
    records: (event.Records || []).length,
  }),
});
