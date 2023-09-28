import { ethers } from "hardhat";
import { SampleAccount__factory } from "../typechain-types";
import { SafeProtocolManager__factory } from "../typechain-types";
import { IntentPlugin__factory } from "../typechain-types";
import { IDSNIntentModule } from "../typechain-types";
import type {
    BaseContract,
    BigNumberish,
    BytesLike,
    AddressLike,
  } from "ethers";

type ATOStruct = {
    Operation: BigNumberish;
    fieldsToOptimize: BytesLike;
    fieldsToOptimizeSchema: BytesLike;
    chainId: BigNumberish;
    payload: BytesLike;
    payloadSchema: BytesLike;
    sender: AddressLike;
  };

(async () => {

    const sampleATO: ATOStruct = {
        Operation: ethers.toBigInt(1),
        fieldsToOptimize: ethers.toUtf8Bytes(""),
        fieldsToOptimizeSchema: ethers.toUtf8Bytes(""),
        chainId: ethers.toBigInt(1),
        payload: ethers.toUtf8Bytes(""),
        payloadSchema: ethers.toUtf8Bytes(""),
        sender: '',
    };

    // get random address
    console.log('Deploying boiler plate contracts...');
    const randomAddress1 = ethers.Wallet.createRandom().address;
    const randomAddress2 = ethers.Wallet.createRandom().address;
    const [sampleAccount, protocolManager, intentPlugin] = await Promise.all([
        ethers.deployContract('SampleAccount').then(d => d.target),
        ethers.deployContract('SafeProtocolManager', [randomAddress1, randomAddress2]).then(d => d.target),
        ethers.deployContract('IntentPlugin', [randomAddress1]).then(d => d.target),
      ]);
    
    // console.log('Addresses' + JSON.stringify({sampleAccount, protocolManager, intentPlugin}, null, 2));
    // fund sampleAccount contract
    console.log('Funding sampleAccount contract...');

    const provider = ethers.provider
    const ethersSigner = await provider.getSigner(0);

    // funding wallet with 1 ether
    const fundTxn = await ethersSigner.sendTransaction({
        to: sampleAccount,
        value: ethers.parseEther("1.0"),
        data: '0x'
    });

    console.log('funded sampleAccount with 1 eth');
    console.log('Txn hash:', fundTxn.hash);

    const intentPluginInstance = IntentPlugin__factory.connect(String(intentPlugin), ethersSigner);
    sampleATO.sender = String(sampleAccount);

    // ISafeProtocolManager manager, 
    // ISafe userSafeAccount,
    // ATO calldata ato
    console.log('Executing ATO...')
    console.log('this is sample ATO', sampleATO);

    const txn = await intentPluginInstance.executeATO(
        String(protocolManager),
        String(sampleAccount),
        sampleATO
    );

    console.log('ATO sent for execution', txn.hash);

})()