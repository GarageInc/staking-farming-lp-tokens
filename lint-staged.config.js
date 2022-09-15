module.exports = {
  "*.{ts,js,json}": ["pretty-quick --pattern '**/*.*(js|tx|json)' --staged"],
  "**/*.{ts,js,json}": ["yarn lint:js:fix"],
};
