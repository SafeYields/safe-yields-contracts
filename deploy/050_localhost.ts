import { SafeNFT } from '@contractTypes/contracts';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  if (hre.network.name !== 'localhost' && hre.network.name !== 'hardhat') return;
  const nft = await hre.ethers.getContract<SafeNFT>('SafeNFT');
  await nft.setPresaleMaxSupply([100, 50, 30, 20]);
  await nft.togglePresale();
  const signers = await hre.ethers.getSigners();
  for (const signer of signers) {
    await hre.run('permit', { user: signer.address });
    await hre.run('fund', { user: signer.address });
  }
  await hre.run('init');
};
export default func;
func.tags = ['LocalhostPostConfig'];
