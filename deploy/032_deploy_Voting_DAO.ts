import { SafeNFT } from '@contractTypes/contracts';
import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer } = await hre.getNamedAccounts();

  const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');

  await deployAndTell(deploy, 'VotingDAO', {
    from: deployer,
    proxy: 'initialize',
    args: [nftContract.address],
  });
};
export default func;
func.tags = ['VotingDAO'];
