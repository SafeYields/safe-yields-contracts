import { presaleMaxSupply } from '@config';
import { SafeNFT } from '@contractTypes/contracts';
import { info, networkInfo, success } from '@utils/output.helper';
import { task, types } from 'hardhat/config';

export default task('presale', 'gets and sets presale date to now or other date')
  .addOptionalParam(
    'test',
    'update the date (default is false which only reads and displays the date)',
    true,
    types.boolean,
  )
  .addOptionalParam('price', 'update the discounted price table and maxSupply per week', false, types.boolean)
  .setAction(async ({ test, price }, hre) => {
    await networkInfo(hre, info);

    const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
    if (!test) {
      if (price) {
        info(`setting presaleMaxSupply to: ${presaleMaxSupply}`);
        await (await nftContract.setPresaleMaxSupply(presaleMaxSupply)).wait();
      } else {
        info('skipping price table update since price parameter is not set to true');
      }

      success('Done.');
    }
  });
