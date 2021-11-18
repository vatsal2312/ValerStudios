require('dotenv').config()
require("@nomiclabs/hardhat-waffle");
require('solidity-coverage');
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers")

const user0_private_key = process.env.USER0_PRIVATE_KEY
  ? process.env.USER0_PRIVATE_KEY
  : '0000000000000000000000000000000000000000000000000000000000000000'
const user1_private_key = process.env.USER1_PRIVATE_KEY
  ? process.env.USER1_PRIVATE_KEY
  : '0000000000000000000000000000000000000000000000000000000000000000'
const user2_private_key = process.env.USER2_PRIVATE_KEY
  ? process.env.USER2_PRIVATE_KEY
  : '0000000000000000000000000000000000000000000000000000000000000000'
const user3_private_key = process.env.USER3_PRIVATE_KEY
  ? process.env.USER3_PRIVATE_KEY
  : '0000000000000000000000000000000000000000000000000000000000000000'
const user4_private_key = process.env.USER4_PRIVATE_KEY
  ? process.env.USER4_PRIVATE_KEY
  : '0000000000000000000000000000000000000000000000000000000000000000'

  const accounts = [
    `0x${user0_private_key}`,
    `0x${user1_private_key}`,
    `0x${user2_private_key}`,
    `0x${user3_private_key}`,
    `0x${user4_private_key}`,
  ]
  
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gas: 2100000,
      gasPrice: 20000000000,
      accounts: ['0x2a60a90385921af92e32faaa2fdf8c7a7ff7d2b9421cf8cc34ec4880c2b8bb59'],
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: accounts,
    }
  },
  solidity: "0.8.4",
  namedAccounts: {
    deployer: 0,
    tokenOwner: 1,
  },
};
