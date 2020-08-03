'use strict'

const assertRevert = (err) => {
  if (web3.version.startsWith("1")) {
    // console.log(JSON.stringify(err))
    assert.ok(err && err.hijackedStack && err.hijackedStack.includes('revert'))
  } else {
    assert.ok(err && err.message && err.message.includes('revert'));
  }
};

const assertInvalidOpcode = (err) => {
  if (web3.version.startsWith("1")) {
    assert.equal('invalid opcode', Object.values(err.results)[0].error)
  } else {
    assert.ok(err && err.message && err.message.includes('invalid opcode'))
  }
}

const assertPayable = (err) => {
  if (web3.version.startsWith("1")) {
    assert.ok(err && err.hijackedStack && err.hijackedStack.includes('revert'))
  } else {
    assert.ok(err && err.message && err.message.includes('payable'))
  }
}

const assertFunction = (err) => {
  if (web3.version.startsWith("1")) {
    assert.equal('is not a function', Object.values(err.results)[0].error)

  } else {
    assert.ok(err && err.message && err.message.includes('is not a function'))

  }
};

const assetEvent_getArgs = (logs, eventName) => {
  assert.ok(logs instanceof Array, 'logs should be an array')
  assert.equal(logs.length, 1, 'should return one log')
  const log = logs[0]
  assert.equal(log.event, eventName, 'event')
  return log.args
};


module.exports = {
  assertRevert,
  assertInvalidOpcode,
  assertPayable,
  assertFunction,
  assetEvent_getArgs
}
