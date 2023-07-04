import { SafeNFT } from '@contractTypes/contracts';
import { info, networkInfo, success } from '@utils/output.helper';
import { task } from 'hardhat/config';

const airdropData = [
  ['0x07d89372daa468575b7fbd814e4a9d59e38d414b', 0, 1, 0, 0],
  ['0x0879578083928a2b33466b09e894060115032bed', 0, 1, 0, 0],
  ['0x10b0d7ad19f4e61c8ccd10632252939c27ab7029', 1, 0, 1, 0],
  ['0x194f5428967647efad484ed65cd54e65a9ef337f', 0, 1, 0, 0],
  ['0x1fce95d3b5eb9255c7f90ef6ac3ed8d086ece2d4', 0, 1, 1, 0],
  ['0x2b8834eda92862d117d239da4f36a9c9884dc12a', 1, 0, 0, 0],
  ['0x36bd14eaf211d65164e1e0a2eab5c98b4b734875', 0, 1, 1, 0],
  ['0x3c6ecc9d359d2b8de6412bc0cfc78f125dad5b68', 0, 1, 0, 0],
  ['0x498ac92d548990217159c751e3823b88c5a4b192', 1, 0, 0, 0],
  ['0x53963b4f9751f46646a82b350fedd852c6944251', 1, 0, 0, 0],
  ['0x56ad040251c4a896948447cb96e0b7e27f755eea', 1, 0, 0, 0],
  ['0x5af34a3fffc67e7778393ad01f4204354ff889d1', 1, 0, 0, 0],
  ['0x5b241a1f3751c202b2834ac6e90d144697ecc354', 0, 1, 1, 0],
  ['0x5be26396c40f62359dbf0cc7bc5ce2b62f0e9896', 1, 0, 0, 0],
  ['0x6adfc7058c9147cf2102b6b87c4c0cde8e1daebe', 0, 1, 0, 0],
  ['0x6b95b0dc145655f28c8126505f263031d248a09e', 1, 0, 0, 0],
  ['0x6db31b906d7284f92646e74b913207c8275a7931', 0, 1, 0, 0],
  ['0x6fd2e47562dce78aeef846612fd59b69d39d8614', 0, 1, 0, 0],
  ['0x7469ad145870122155bfb76e4adbf180a8da1a30', 0, 1, 0, 0],
  ['0x82354264cabc7fd1d5678458fe44f82f22c7052c', 1, 0, 0, 0],
  ['0x82d2258c2dcc6383169e99d4f48cb91d2bd1a098', 1, 1, 0, 0],
  ['0x8a94acd5d8834663398b22b76b84a6743c25b3b4', 0, 1, 0, 0],
  ['0x9716444f669e10573513fbdc0ad5d03c2e236fdc', 0, 1, 1, 0],
  ['0x9b5ae497fd1bf885a40d6f99d0c57245761e053c', 1, 0, 0, 0],
  ['0x9b5AE497fd1BF885A40D6f99d0c57245761E053C', 0, 1, 0, 0],
  ['0x9b5AE497fd1BF885A40D6f99d0c57245761E053C', 0, 0, 1, 0],
  ['0x9b5AE497fd1BF885A40D6f99d0c57245761E053C', 0, 1, 0, 0],
  ['0x9b5AE497fd1BF885A40D6f99d0c57245761E053C', 1, 1, 0, 0],
  ['0x9f9a04a5f5a34d9b1f9ec0d2103cb7b9ec69241c', 1, 1, 0, 0],
  ['0x9ffaebafff961d43e7793411dfab9fe9f994298d', 1, 0, 0, 0],
  ['0xa081b7596330d46b1bfe70caff2ca295e06b3c39', 1, 0, 1, 2],
  ['0xa2bb8c6834f55bc3ff89f71082c8ac868216c42e', 1, 1, 0, 0],
  ['0xa69a062d0f231f18870814be81404673120ce778', 0, 1, 0, 0],
  ['0xaa61252de6fccdd4ca4029570ca8b3004a8ee760', 1, 1, 0, 0],
  ['0xaab5027bc36c1269a7bef467b9214618d33173cf', 1, 0, 0, 0],
  ['0xacfd201ba9c8ad94104ec8227c09a0a7976bbf18', 1, 1, 0, 0],
  ['0xad7cd73164206a647e928aa66d4044e99cfff16c', 1, 0, 0, 0],
  ['0xadd0f95b171d34bc3b2ec1e6fc1581781ea18068', 1, 0, 0, 0],
  ['0xb09753213524b17cf62a1306559ab50176b2683e', 0, 1, 1, 0],
  ['0xb4d59884bd6dc8190be4fccc9d34484ec4b9a316', 1, 1, 0, 0],
  ['0xb6c7ae2e58444f89dd95e1d30f21fb1f1c467a8f', 1, 0, 0, 0],
  ['0xb868425c55c0c9f2e494039f86df0216b2c7ef88', 0, 1, 1, 0],
  ['0xb92c334104ccda32dc51d479723a64bb97469ed1', 0, 1, 1, 0],
  ['0xbbcfd5dc51ead91342f6c0caa595e1ced195669e', 1, 0, 0, 0],
  ['0xbe2dac6599e3916d4796828e4d63fc80d6b5413b', 0, 1, 0, 0],
  ['0xbf4d24ebbdbfe4b1f59608feef02e7b0d9093d50', 1, 0, 0, 0],
  ['0xbfa0e26a56120a98184a0bf80a2a22bb845e2854', 1, 0, 0, 0],
  ['0xc9f889c6da55b1daa0d04b026e3d5241aa2f8959', 1, 0, 0, 0],
  ['0xd1195af161730fb24151f23e6b7d994cf0aaf01a', 1, 0, 0, 0],
  ['0xd235ab1876bfee4168b8615ae09a6b192cf31fd0', 0, 1, 0, 0],
  ['0xd5f347df1fa35ff71c3627b8b1858a21895dae1d', 0, 1, 0, 0],
  ['0xdad0c04ddea55bc4d8dda63fc72f4209382c9ea7', 0, 1, 0, 0],
  ['0xdd2d6446bee70e4c4813b7d24f0742dd0f5c7942', 1, 0, 0, 0],
  ['0xe015008a2b3382612dce43cb454de6ae6c4e5533', 1, 0, 0, 0],
  ['0xe6e84836d7147d2058bb4a5a6f10f37c9c6f4433', 1, 1, 0, 1],
  ['0xea54f6e5af387e9a161fcb174d0113f725c3bb72', 1, 0, 0, 0],
  ['0xede22e55e0d00a0f385f09955997b045c47ece9b', 1, 1, 0, 0],
  ['0xfaf790ff539471763da851d63ad1a47d0f95f2a6', 0, 1, 0, 0],
  ['0xfd104ddbfc4575173588fe9dbad417f8088488d8', 1, 0, 0, 0],
  ['0xfddbc8f564cdf6ba58715d5eeee90ac96530b5fa', 0, 1, 0, 0],
];
export default task('whitelist', 'add wallets back to the rewards distribution list').setAction(async (_, hre) => {
  await networkInfo(hre, info);

  const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');

  const addresses: string[] = airdropData.map(data => data[0].toString().toLowerCase());
  info(`Whitelisting ${addresses.length} addresses for the rewards distribution ...`);
  const tx = await nftContract.whitelistForRewardsDistribution(addresses);
  await tx.wait();
  success('Done.');
});
