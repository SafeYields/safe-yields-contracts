import { error, fromBigNumber, info, networkInfo, success, toBigNumber } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import assert from 'assert';
import { BigNumber } from 'ethers';
import { task, types } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

type Tokens = keyof typeof tokens;

const tokens = {
  usdc: {
    address: '0xff970a61a04b1ca14834a43f5de4533ebddb5cc8',
    whale: '0xf89d7b9c864f589bbf53a82105107622b35eaa40',
    defaultAmount: 100000,
    decimals: 6,
  },
  usds: {
    address: '0xd74f5255d557944cf7dd0e45ff521520002d5748',
    whale: '0x9499506fcb2b2eab5ac62ac82e2284501e472b60',
    defaultAmount: 1000,
    decimals: 18,
  },
  wbtc: {
    address: '0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f',
    whale: '0x59a661f1c909ca13ba3e9114bfdd81e5a420705d',
    defaultAmount: 3,
    decimals: 8,
  },
};

const beTheWhale = async (hre: HardhatRuntimeEnvironment, accountToFund: string) => {
  const signer = (await hre.ethers.getSigners())[0];
  for (const token of Object.keys(tokens) as Tokens[]) {
    const accountToInpersonate = tokens[token].whale;
    info(`impersonating ${accountToInpersonate}`);
    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [accountToInpersonate],
    });
    const whaleSigner = await hre.ethers.getSigner(accountToInpersonate);
    await (
      await signer.sendTransaction({
        to: accountToInpersonate,
        value: toBigNumber('1'),
        gasLimit: 8_000_000,
      })
    ).wait();

    const contract = new hre.ethers.Contract(tokens[token].address, erc20abi, whaleSigner);
    const balance = await contract.balanceOf(accountToInpersonate);
    const toTransfer = toBigNumber(tokens[token].defaultAmount, tokens[token].decimals) ?? balance;
    info(`token:  ${token}`);
    info(`Whale:  ${accountToInpersonate}`);
    info(`Balance:  ${fromBigNumber(balance, tokens[token].decimals)}`);
    info(`Transferring ${fromBigNumber(toTransfer, tokens[token].decimals)} to ${accountToFund}`);
    assert(BigNumber.from(balance).gte(toTransfer), 'Not enough balance to transfer');
    const connectedContract = contract.connect(whaleSigner);
    await (await connectedContract.transfer(accountToFund, toTransfer)).wait();
    success(`Transferred ${fromBigNumber(toTransfer, tokens[token].decimals)} ${token} to ${accountToFund}`);
    await hre.network.provider.request({
      method: 'hardhat_mine',
    });
  }
};

export default task('fund', 'get tokens (USDC by default) from a whale on a forked mainnet')
  .addOptionalParam(
    'account',
    "The named account to get USDC, e.g. 'management', 'vault', or 'all'",
    'deployer',
    types.string,
  )
  .addOptionalParam('user', 'user address to get', undefined, types.string)
  .setAction(async ({ account, user }, hre) => {
    const { getNamedAccounts } = hre;
    await networkInfo(hre, info);

    assert((await hre.getChainId()) === '1337', 'Not applicable to live networks!');

    const namedAccounts = await getNamedAccounts();
    if (user === undefined && account !== 'all' && !namedAccounts[account]) {
      error(`Named account ${account} or user not set`);
      return;
    }
    const accounts = user ? [user] : account === 'all' ? Object.values(namedAccounts) : [namedAccounts[account]];

    for (const account of accounts) {
      await beTheWhale(hre, account);
    }
  });
