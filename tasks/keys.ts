import { announce, info } from '@utils/output.helper';
import { ethers } from 'ethers';
import { task, types } from 'hardhat/config';
import { HardhatNetworkHDAccountsConfig } from 'hardhat/src/types/config';

task('keys', 'Prints private keys and addresses for a mnemonic, also translates private key into address')
  .addOptionalParam('generate', 'generate a new mnemonic and print it', false, types.boolean)
  .addOptionalParam(
    'mnemonic',
    'bip39 mnemonic words, taken from the configuration if not set',
    undefined,
    types.string,
  )
  .addOptionalParam('pkey', 'private key, if entered, the address is displayed', undefined, types.string)
  .setAction(async ({ generate, mnemonic: mnemonicProvidedByUser, pkey }, hre) => {
    const accounts = await hre.ethers.getSigners();
    const config = hre.config.networks.hardhat.accounts as HardhatNetworkHDAccountsConfig;

    if (pkey) {
      const wallet = new ethers.Wallet(pkey);
      info(`private key: ${wallet.privateKey}`);
      info(`address    : ${wallet.address}`);
      return;
    }

    const mnemonic = generate
      ? ethers.Wallet.createRandom().mnemonic.phrase
      : mnemonicProvidedByUser ?? config.mnemonic;
    info(`mnemonic: ${mnemonic}`);
    for (let index = 0; index < accounts.length; index++) {
      announce(`Account ${index}:`);
      const wallet = ethers.Wallet.fromMnemonic(mnemonic, config.path + `/${index}`);
      info(`address: ${wallet.address}`);
      info(`private key: ${wallet.privateKey}`);
    }
  });
