import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  if (hre.network.name !== 'localhost' && hre.network.name !== 'hardhat') {
    return;
  }
  const { deployer } = await hre.getNamedAccounts();

  await deployAndTell(deploy, 'Multicall2', {
    from: deployer,
    proxy: false,
  });
};
export default func;
func.tags = ['Multicall2'];
