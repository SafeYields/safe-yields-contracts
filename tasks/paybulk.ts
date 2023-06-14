import { SafeRouter } from '@contractTypes/contracts';
import { info, networkInfo, success } from '@utils/output.helper';
import { task } from 'hardhat/config';

const receivers = [
  '0x67a5A9E9a0A6cfb6a73442b9811B141EA875D3B7',
  '0x5926433A020059E65cC5F06c0b7683540EC4427f',
  '0x9F4a825290dc01EdCefF30fEC2EaE7498c7f8874',
  '0x05414dB4BaF046202C2B4a5CB21F636717C73a93',
  '0x5D419012E99c22f695017EBE94Cfb8d2e2062662',
  '0x8D1dc91f8B7487317ba4F616c88b7A5fabb87B91',
  '0xA87554f97fc805205CF067EFC515eF597Bd30dd9',
  '0x2A3e45b88Cc75f4c9bCd00d8B2Df85226D0C10Ae',
  '0x1D70676AB2bC9AB633e01eaB41ac44b7700e9153',
  '0x018a1022f291D0aa495834dF8DeC24dc246f4FDF',
  '0x244A95abBBaDc5c516155EFB2c68DcB61AA4D836',
  '0x1A8500c7927973e5602d9aE7EC6f0367319f5202',
  '0x72c2207C858141164Ce320ec36EA12504e5FF008',
  '0x20a7cC45383986dfeCEE18C29D0be0E1c33f09cE',
  '0xCB55977D74888E0a0Fc5cF71Bc20F5e7567Fb50c',
  '0x75fd78440F71baAF74fa215A1c8b18d625259B53',
  '0x4eb4A3a374A9aFE06A3927Db56f46D83e1cbdFd6',
  '0xbb1404f7C2062Ba5A1487Ee425ED80b79819970d',
  '0xB77A0727Be99fFE941826fA021EEecd97ed01Cd5',
  '0x6fcA84363E386ae1a99EbC65c42D34b392Fd7D6E',
  '0x1c556918FC9504c2D9d3a1BA614E1340E73Eb71c',
  '0xdFF910CF3BF36C468B1514E6D8887A7E1134Bf3D',
  '0xa2Fd9928384EF998110370B5DeBeFFb8D2984Fea',
  '0xaB248c44332951187B5dDf82080cCee90684021D',
  '0x4148A20C8CD4DC16883f6112B678a400B5289616',
  '0x1E1FCc44a239E624ae854e4D6f356C09255ac26e',
];
export default task('paybulk', 'distribute Safe token according to the list').setAction(async (_, hre) => {
  await networkInfo(hre, info);
  const amounts = receivers.map(() => hre.ethers.utils.parseUnits('15', 6));
  const router = await hre.ethers.getContract<SafeRouter>('SafeRouter');
  receivers.push('0xcda8983F24B3a94Cb8d3DA32c62d724B309B71A5');
  amounts.push(hre.ethers.utils.parseUnits('45', 6));
  receivers.push('0x72c2207C858141164Ce320ec36EA12504e5FF008');
  amounts.push(hre.ethers.utils.parseUnits('40', 6));

  info(`Paying ${receivers.length} addresses...`);
  const tx = await router.payBulk(receivers, amounts);
  const hash = await tx.wait();
  success('Done.');
  success(`Tx hash: ${hash.transactionHash}`);
});
