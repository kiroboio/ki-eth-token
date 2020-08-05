'use strict'

const sleep = (milliseconds) => {
  return new Promise((r, j) => setTimeout(() => { r() }, milliseconds))
}

const getLatestBlockTimestamp = async (timeUnitInSeconds = 1) => {
  const timestamp = await new Promise(
    (r, j) => web3.eth.getBlock('latest', (err, block) => r(block.timestamp)))
  return Math.floor(timestamp / timeUnitInSeconds)
}

const mine = async (account) => {
  web3.eth.sendTransaction({ value: 0, from: account, to: account })
};

const isBackupActivated = async (wallet) => {
  return (await wallet.getBackupState()).eq(await wallet.BACKUP_STATE_ACTIVATED())
}

const advanceTime = (time) => { // taken from https://medium.com/fluidity/standing-the-time-of-test-b906fcc374a9
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_increaseTime',
      params: [time],
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    })
  })
}

const advanceBlock = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_mine',
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      const newBlockHash = web3.eth.getBlock('latest').hash

      return resolve(newBlockHash)
    })
  })
}

const takeSnapshot = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_snapshot',
      id: new Date().getTime()
    }, (err, snapshotId) => {
      if (err) { return reject(err) }
      return resolve(snapshotId)
    })
  })
}

const revertToSnapShot = (id) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_revert',
      params: [id],
      id: new Date().getTime()
    }, (err, result) => {
      if (err) { return reject(err) }
      return resolve(result)
    })
  })
}

const advanceTimeAndBlock = async (time) => {
  await advanceTime(time)
  await advanceBlock()
  return Promise.resolve(web3.eth.getBlock('latest'))
}

function pollCondition(cb, timeout) {
  return new Promise(resolve => {
    const checkCondition = () => {
      if (cb()) resolve();
      else setTimeout(checkCondition, timeout);
    };

    checkCondition();
  });
}

const parseAcceptTokensMessage = (message) => {
  return {
    version: message.slice(2, 2+2),
    uid: message.slice(4+2, 4+22-4),
    pool: message.slice(26,26+40),
    selector: message.slice(66, 66+8),
    from: message.slice(74, 74+40),
    value: message.slice(114, 114+64),
    secretHash: message.slice(178, 178+64),
    taiL: message.slice(242)
  }
}

const parsePaymentMessage = (message) => {
  return {
    version: message.slice(2, 2+2),
    uid: message.slice(4+2, 4+22-4),
    pool: message.slice(26,26+40),
    selector: message.slice(66, 66+8),
    from: message.slice(74, 74+40),
    value: message.slice(114, 114+64),
    nonce: message.slice(178, 178+64),
    tail: message.slice(242)
  }
}

const parseNonce = (nonce) => {
  const n = nonce.toString('hex')
  return {
    count: n.slice(0, -60),
    salt: n.slice(-60, -8),
    timestamp: n.slice(-8),
  }
}

module.exports = {
  sleep,
  getLatestBlockTimestamp,
  mine,
  isBackupActivated,
  advanceTime,
  advanceBlock,
  advanceTimeAndBlock,
  takeSnapshot,
  revertToSnapShot,
  pollCondition,
  parseAcceptTokensMessage,
  parsePaymentMessage,
  parseNonce,
}
