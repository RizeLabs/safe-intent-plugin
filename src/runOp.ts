import { ethers } from "hardhat";
import { SampleAccount__factory } from "../typechain-types";
import { SafeProtocolRegistry__factory } from "../typechain-types";
import { IntentPlugin__factory } from "../typechain-types";
import type { BigNumberish, BytesLike, AddressLike } from "ethers";
import SafeProtocolManagerAbi from "../abis/SafeProtocolManager.json";
import IntentPlugin from "../abis/IntentPlugin.json";

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
    sender: "",
  };
  const provider = ethers.provider;
  const userSigner = await provider.getSigner(0);
  const userAddress = await userSigner.getAddress();
  const globalOwner = await provider.getSigner(1);
  const globalOwnerAddress = await globalOwner.getAddress();

  console.log("Deploying registry contract...");
  const registryDeployment = await ethers.deployContract(
    "SafeProtocolRegistry",
    [globalOwnerAddress]
  );
  await registryDeployment.waitForDeployment();
  const registryAddress = registryDeployment.target;
  console.log("Registry deployed to:", registryAddress);

  // get random address
  console.log("Deploying other boiler plate contracts...");
  const randomAddress1 = ethers.Wallet.createRandom().address;
  const [sampleAccount, protocolManager, intentPlugin] = await Promise.all([
    ethers.deployContract("SampleAccount", [userAddress]).then((d) => d.target),
    ethers
      .deployContract("SafeProtocolManager", [
        globalOwnerAddress,
        registryAddress,
      ])
      .then((d) => d.target),
    ethers
      .deployContract("IntentPlugin", [randomAddress1])
      .then((d) => d.target),
  ]);

  console.log("Deployed contracts...");

  // need to add module to the registry
  console.log("Adding module to registry...");
  const registryInstance = SafeProtocolRegistry__factory.connect(
    String(registryAddress),
    globalOwner
  );
  const addModuleTxn = await registryInstance.addModule(intentPlugin, 1); // passing 1 because module is a plugin type
  console.log("Module added to registry", addModuleTxn.hash);

  const txnData = new ethers.Interface(
    SafeProtocolManagerAbi.abi
  ).encodeFunctionData("enablePlugin", [String(intentPlugin), 1]);

  const abiCoder = new ethers.AbiCoder;
  const appendedCallData = abiCoder.encode(
    ['bytes', 'bytes'],
    [txnData, String(sampleAccount)]
  );

  const enablePluginTxn = {
    to: protocolManager,
    data: appendedCallData,
    value: 0
  };

  // fund sampleAccount contract
  console.log("Funding sampleAccount contract...");

  // funding wallet with 1 ether
  const fundTxn = await userSigner.sendTransaction({
     to: sampleAccount,
     value: ethers.parseEther("1.0"),
     data: "0x",
  });
  
  console.log("funded sampleAccount with 1 eth");
  console.log("Txn hash:", fundTxn.hash);

  console.log("Enable plugin with necessary execute permission...");
  const SampleAccountInstance = SampleAccount__factory.connect(String(sampleAccount), userSigner);
  const enableAccountTxn = await SampleAccountInstance.execTransaction(
    enablePluginTxn.to,
    enablePluginTxn.value,
    enablePluginTxn.data,
    0,
    { gasLimit: 1000000 }
  );

  console.log('Enabled intent plugin ', enableAccountTxn.hash);

  const intentPluginInstance = IntentPlugin__factory.connect(
    String(intentPlugin),
    userSigner
  );
  sampleATO.sender = String(sampleAccount);

  // ISafeProtocolManager manager,
  // ISafe userSafeAccount,
  // ATO calldata ato
  console.log("Executing ATO...");
  console.log("this is sample ATO", sampleATO);

  const executeAtoTxnData = new ethers.Interface(IntentPlugin.abi).encodeFunctionData(
    'executeATO',
    [
      String(protocolManager),
      String(sampleAccount),
      sampleATO
    ]
  );

  const txn = await SampleAccountInstance.execTransaction(
    sampleAccount,
    "0",
    executeAtoTxnData,
    0,
    { gasLimit: 1000000 }
  );
  console.log("ATO sent for execution", txn.hash);
})();
