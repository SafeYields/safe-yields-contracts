import { discountedPrice } from '@config';
import { SafeNFT, SafeToken, SafeVault } from '@contractTypes/contracts';
import { deployInfo, deploySuccess } from '@utils/output.helper';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const tokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
  const vault = await hre.ethers.getContract<SafeVault>('SafeVault');
  const nft = await hre.deployments.get('SafeNFT');
  for (const address of [
    process.env.TREASURY_ADDRESS || hre.ethers.constants.AddressZero,
    process.env.MANAGEMENT_ADDRESS || hre.ethers.constants.AddressZero,
    vault.address,
    nft.address,
  ]) {
    if (!(await tokenContract.whitelist(address))) {
      deployInfo(`Authorizing SafeToken for ${address}`);
      await (await tokenContract.whitelistAdd(address)).wait();
    } else {
      deployInfo(`SafeToken for ${address} already authorized`);
    }
  }

  deployInfo('Setting SafeToken for SafeVault');
  await (await vault.setSafeToken(tokenContract.address)).wait();
  deploySuccess('Done.');

  const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
  deployInfo(`Setting URLs for NFT`);
  for (const tokenId of [0, 1, 2, 3]) {
    deployInfo(`Setting URL for NFT ${tokenId}`);
    const url = await nftContract.uri(tokenId);
    const urlToSet = `https://safe-yields.s3.amazonaws.com/metadata-tier${tokenId + 1}.json`;
    if (url !== urlToSet) {
      await (await nftContract.setURI(tokenId, urlToSet)).wait();
    }
  }

  deployInfo('Setting ambassador address');
  const ambassador = await nftContract.ambassador();
  if (ambassador === hre.ethers.constants.AddressZero) {
    await (await nftContract.setAmbassador('0x82368563257B056Ae3d5eB9434C8AA4E0FA3526E')).wait();
  }

  const configuredDiscountedPrice = await nftContract.discountedPrice();
  if (!configuredDiscountedPrice.eq(discountedPrice)) {
    await (await nftContract.setDiscountedPrice(discountedPrice)).wait();
  }
};
export default func;
func.tags = ['Config'];
