// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//
interface ISupraRouter {
   function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed) external returns(uint256);
   function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations) external returns(uint256);
}

// 
contract randomNFTStats is ERC721 {
  //
  using Counters for Counters.Counter;

  //
  address supraAddr;
  ISupraRouter holder;

  //
  struct playerStats{
    uint8 level;
    uint8 health;
    uint8 strength;
  }

  //nonce to tokenId
  mapping(uint256 => address) nonceToMinterAddress;

  //tokenId to playerStats
  mapping (uint256 => playerStats ) tokenIdToStats;

  //
  Counters.Counter private _tokenIdCounter;

  //
  constructor(address supraSC) ERC721("supraVrfNFT", "SNFT") {
    supraAddr = supraSC;
  }

  //request function
  //anyone can mint as long as tokens are available
  function safeMint() public {
    uint256 nonce =  ISupraRouter(supraAddr).generateRequest("setStartingStats(uint256,uint256[])", 1, 1, 123);
    nonceToMinterAddress[nonce] = msg.sender;
  }

  //callback function
  function setStartingStats(uint256 nonce, uint256[] calldata rngList) external {
    require(msg.sender == supraAddr, "only supra router can call this function");
    require(rngList.length == 1, "Incorrect amount of random numbers returned");
    uint256 tokenId = _tokenIdCounter.current();

    _tokenIdCounter.increment();
    _safeMint(nonceToMinterAddress[nonce], tokenId);

    tokenIdToStats[tokenId].level = uint8((rngList[0] % 100));
    tokenIdToStats[tokenId].health = uint8((rngList[0] % 1000)/10);
    tokenIdToStats[tokenId].strength = uint8((rngList[0] % 10000)/100);
  }

  //
  function getTokenStats(uint tokenId) external view returns (uint, uint, uint){
    return (tokenIdToStats[tokenId].level, tokenIdToStats[tokenId].health, tokenIdToStats[tokenId].strength);
  }

  function levelUpToken(uint tokenId) external{
    require(_exists(tokenId), 'Token does not exist.');
    tokenIdToStats[tokenId].level = tokenIdToStats[tokenId].level + 1;
    tokenIdToStats[tokenId].health = tokenIdToStats[tokenId].health + 10;
    tokenIdToStats[tokenId].strength = tokenIdToStats[tokenId].strength + 10;
  }

}