// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SBToken is ERC721{

    uint public totalSouls;

    address public immutable emitter;

    mapping(address => string) public comment;
    
    modifier onlyEmitter(address _user){
        require(_user == emitter, "SBToken: Invalid caller");
        _;
    }

    constructor() ERC721("Z2HSBToken", "SBT"){ 
        emitter = tx.origin;
    }

    function approve(address to, uint256 tokenId)public override onlyEmitter(msg.sender){}

    function transferFrom(address from,address to,uint256 tokenId)public override onlyEmitter(msg.sender){}

    function safeTransferFrom(address from, address to, uint256 tokenId)public override onlyEmitter(msg.sender){}

    function safeTransferFrom(address from, address to, uint256 tokenId,bytes memory data)public override onlyEmitter(msg.sender){}

    function setApprovalForAll(address operator, bool approved)public override onlyEmitter(msg.sender){}

    function mintTo(address _to, string calldata _comment)external onlyEmitter(msg.sender){
        require(balanceOf(_to) == 0, "SBToken: Invalid leash");
        _safeMint(_to, totalSouls);
        totalSouls += 1;
        comment[_to] = _comment;
    }

}
