import 'hardhat-gas-reporter';
import 'hardhat-deploy';
import 'hardhat-spdx-license-identifier';

import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-truffle5';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';

import '@openzeppelin/hardhat-upgrades';

import '@typechain/hardhat';

import 'solidity-coverage';
// import 'hardhat-log-remover';

import './tasks';

import keys from './dev-keys.json';

const config = {
  defaultNetwork: 'bsc',
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${keys.alchemyKeyMainnet}`,
        // blockNumber: 12594447        , // <-- edit here
        blockNumber: 13137174, // <-- edit here
      },
      initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
      mining: {
        auto: true,
      },
      gasPrice: 0,
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${keys.alchemyKeyMainnet}`,
      accounts: [`0x${keys.PRIVATE_KEY_1}`, `0x${keys.PRIVATE_KEY_2}`],
      gasPrice: 71000000000,
      timeout: 3600000,
    },
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${keys.alchemyKeyRopsten}`,
      accounts: [`0x${keys.PRIVATE_KEY_1}`, `0x${keys.PRIVATE_KEY_2}`],
      gasPrice: 83431241471,
    },
    rinkeby: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${keys.alchemyKeyRopsten}`,
      accounts: [`0x${keys.PRIVATE_KEY_1}`, `0x${keys.PRIVATE_KEY_2}`],
    },
    polygon: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${keys.alchemyKeyPolygon}`,
      accounts: [`0x${keys.PRIVATE_KEY_1}`, `0x${keys.PRIVATE_KEY_2}`],
      chainId: 137,
      gasPrice: 300000000000,
    },
    fantom: {
      url: 'https://rpc.ftm.tools',
      accounts: {
        mnemonic: keys.metamaskMnemonic,
      },
      chainId: 250,
      gasPrice: 1000000000000,
    },
    'fantom-testnet': {
      url: 'https://rpc.testnet.fantom.network',
      accounts: {
        mnemonic: keys.metamaskMnemonic,
      },
      chainId: 4002,
      gasMultiplier: 2,
    },
    avalanche: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      accounts: {
        mnemonic: keys.metamaskMnemonic,
      },
      gasPrice: 225000000000,
      chainId: 43114,
      live: true,
      saveDeployments: true,
    },
    bsc: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      gasPrice: 20000000000,
      accounts: {
        mnemonic: keys.metamaskMnemonic,
      },
    },
  },
  etherscan: {
    // apiKey: keys.etherscanAPIKey,
    apiKey: keys.bscAPIKey,
    // apiKey: keys.polygonscanAPIKey,
    // apiKey: keys.avaxscanAPIKey,
    // snowtrace: keys.avaxscanAPIKey,
    /*apiKey: {
      mainnet: keys.etherscanAPIKey,
      ropsten: keys.etherscanAPIKey,
    },*/
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: true,
  },
  solidity: {
    compilers: [
      {
        version: '0.8.13',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 2000000,
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS,
    currency: 'USD',
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    firstTestWallet: {
      default: 1,
    },
    secondTestWallet: {
      default: 2,
    },
    thirdTestWallet: {
      default: 3,
    },
  },
};

export default config;
