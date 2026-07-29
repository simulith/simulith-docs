exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({
    service: "simulith",
    source: event.source || "",
    detailType: event["detail-type"] || "",
  }),
});
