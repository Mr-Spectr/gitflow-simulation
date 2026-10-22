const test = require("node:test");
const assert = require("node:assert/strict");
const { getWelcomeMessage } = require("./message");

test("returns a welcome message for the default team", () => {
  assert.equal(getWelcomeMessage(), "Welcome, team!");
});
