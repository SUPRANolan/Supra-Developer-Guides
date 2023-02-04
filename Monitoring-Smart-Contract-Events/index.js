//Ethers v5.7.0
const ethers = require('ethers');
 
const monitorFeed = async function() {
    // Add your RPC URL for Goerli ETH between the ''
    const provider = new ethers.JsonRpcProvider('')
    const abi = [{ "inputs": [ { "internalType": "string", "name": "marketPair", "type": "string" } ], "name": "checkPrice", "outputs": [ { "internalType": "int256", "name": "price", "type": "int256" }, { "internalType": "uint256", "name": "timestamp", "type": "uint256" } ], "stateMutability": "view", "type": "function" } ]
    const address = '0x25DfdeD39bf0A4043259081Dc1a31580eC196ee7'
    const sValueFeed = new ethers.Contract(address, abi, provider)
 
    sValueFeed.on(0x808612c7, async data =>{
        console.log("S-Value Updated at TXN: " + data.transactionHash)
        console.log("New S-Value: " + (await sValueFeed.checkPrice('eth_usdt')).price)
    });
 
}
 
monitorFeed()