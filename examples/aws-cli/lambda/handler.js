exports.handler = async () => ({
  greeting: process.env.GREETING || "unset",
  source: "aws-cli-example",
});
