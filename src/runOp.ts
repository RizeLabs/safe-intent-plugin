import { ethers } from "hardhat";
import { SampleAccount__factory } from "../typechain-types";
import { SafeProtocolRegistry__factory } from "../typechain-types";
import { IntentPlugin__factory } from "../typechain-types";
import type { BigNumberish, BytesLike, AddressLike } from "ethers";
import SafeProtocolManagerAbi from "../abis/SafeProtocolManager.json";
import IntentPlugin from "../abis/IntentPlugin.json";

enum SupportedChainId {
  POLYGON = 137,
  MAINNET = 1,
  CELO = 42220
}

type ATOStruct = {
  Operation: BigNumberish;
  minTokenIn: BigNumberish;
  maxTokenIn: BigNumberish;
  minTokenOut: BigNumberish;
  maxTokenOut: BigNumberish;
  tokenInAddress: AddressLike;
  tokenOutAddress: AddressLike;
  sourceChainId: number;
  destinationChainId: number;
};

type UserIntent = {
  sender: AddressLike;
  intent: ATOStruct[];
  nonce: BigNumberish;
}


(async () => {
  const sampleATO: ATOStruct = {
    Operation: ethers.toBigInt(1),
    minTokenIn: ethers.toBigInt(1),
    maxTokenIn: ethers.toBigInt(5),
    minTokenOut: ethers.toBigInt(5),
    maxTokenOut: ethers.toBigInt(10),
    tokenInAddress: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    tokenOutAddress: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    sourceChainId: SupportedChainId.POLYGON,
    destinationChainId: SupportedChainId.CELO,
  };

  const sampleUserIntent: UserIntent = {
    sender: "",
    intent: [sampleATO],
    nonce: ethers.toBigInt(0),
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
  sampleUserIntent.sender = String(sampleAccount);

  console.log("Paying fees for intent execution...");
  console.log("Sample Intent formed", sampleUserIntent);

  const executeIntentTxnData = new ethers.Interface(IntentPlugin.abi).encodeFunctionData(
    'payFeesAndExecuteIntent',
    [
      String(protocolManager),
      String(sampleAccount),
      sampleUserIntent
    ]
  );

  const txn = await SampleAccountInstance.execTransaction(
    String(sampleAccount),
    "0",
    executeIntentTxnData,
    0,
    { gasLimit: 1000000 }
  );
  console.log("Intent is now valid for execution", txn.hash);
})();
