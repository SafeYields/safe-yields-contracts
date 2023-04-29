import { SafeRouter, SafeToken } from '@contractTypes/contracts';
import { deployAndTell } from '@utils/deployFunc';
import { ethers } from 'ethers';
import { DeployFunction } from 'hardhat-deploy/types';

const tokens = [
  '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
  '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9',
  '0xda10009cbd5d07dd0cecc66161fc93d7c9000da1',
  '0x82af49447d8a07e3bd95bd0d56f35241523fbab1',
  '0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f',
  '0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A',
  '0x3F56e0c36d275367b8C502090EDF38289b3dEa0d',
  '0x9d2f299715d94d8a7e6f5eaa8e654e8c74a988a7',
  '0x080f6aed32fc474dd5717105dba5ea57268f46eb',
  '0x319f865b287fcc10b30d8ce6144e8b6d1b476999',
  '0x9fb9a33956351cf4fa040f65a13b835a3c8764e3',
  '0x6694340fc020c5e6b96567843da2df01b2ce1eb6',
  '0x99c409e5f62e4bd2ac142f17cafb6810b8f0baae',
  '0x68ead55c258d6fa5e46d67fc90f53211eab885be',
  '0xd74f5255d557944cf7dd0e45ff521520002d5748',
  '0xee9801669c6138e84bd50deb500827b776777d28',
  '0x21e60ee73f17ac0a411ae5d690f908c3ed66fe12',
  '0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a',
];
const kyberSwapRouter = '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5';
const amount = ethers.constants.MaxUint256;

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, usdc } = await hre.getNamedAccounts();

  const tokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');

  await deployAndTell(deploy, 'SafeRouter', {
    from: deployer,
    proxy: 'initialize',
    args: [kyberSwapRouter, usdc, tokenContract.address],
  });

  const router = await hre.ethers.getContract<SafeRouter>('SafeRouter');

  await (await router.approveTokens(tokens, kyberSwapRouter, amount)).wait();
};
export default func;
func.tags = ['SafeRouter'];
