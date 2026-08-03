const net = require("net");

exports.handler = async () => {
  const endpoint = process.env.RDS_PROXY_ENDPOINT || "";
  const sep = endpoint.lastIndexOf(":");
  const host = sep >= 0 ? endpoint.slice(0, sep) : endpoint;
  const port = sep >= 0 ? Number(endpoint.slice(sep + 1)) : 5432;
  return new Promise((resolve, reject) => {
    const socket = net.connect(port, host, () => {
      socket.end();
      resolve({ connected: true, endpoint });
    });
    socket.on("error", reject);
    setTimeout(() => reject(new Error("timeout")), 5000);
  });
};
