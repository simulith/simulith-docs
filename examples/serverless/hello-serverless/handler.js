'use strict';

module.exports.hello = async () => {
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'hello from simulith' }),
  };
};
