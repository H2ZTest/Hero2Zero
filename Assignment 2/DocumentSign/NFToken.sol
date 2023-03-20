// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFToken is ERC721{

    address immutable documentSign;

    constructor (address _documentSign) ERC721("UniqueToken", "Z2H") {
        documentSign = _documentSign;
    }

    function mintBySign(address _signer, uint _id)external {
        require(msg.sender == documentSign, "NFToken: Invalid call");
        _safeMint(_signer, _id);
    }

}
