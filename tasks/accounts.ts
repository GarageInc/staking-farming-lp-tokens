// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-ethers';

task('accounts', 'Prints the list of accounts', async (_args, hre) => {
  const accounts = await hre.ethers.getSigners();

  accounts.forEach(console.log);
});

export default {};
