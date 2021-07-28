// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Cai dat Openzeppelin Contracts de co the include nhu ben duoi:
// npm install @openzeppelin/contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NginNFT is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _tokenBaseUri;

    constructor(string memory _uri) ERC721("NginNFT", "NGNFT") {
        _setBaseURI(_uri);
    }

    function safeMint(address to) public {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _baseURI() internal view override returns (string memory) {
        // return 'https://thawing-cove-08010.herokuapp.com/';
        return _tokenBaseUri;
    }
    
    function _setBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "BaseURI must not be blank");
        _tokenBaseUri = _uri;
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        // lấy balanceOf / tổng số token của _owner
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Nếu _owner không sở hữu token nào thì trả về một mảng rỗng
            return new uint[](0);
        }
        else {
            // Lấy ra các token của _owner theo index, đưa vào mảng uint[]
            uint[] memory tokenList = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                tokenList[i] = tokenOfOwnerByIndex(_owner, i);
            }

            return tokenList;
        }
    }
}