exports.handler = async (event) => ({
  statusCode: 200,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    service: "simulith",
    managed_by: "terraform",
    path: event.path,
    httpMethod: event.httpMethod,
  }),
});
