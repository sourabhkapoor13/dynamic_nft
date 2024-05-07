// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC6551Registry.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./ERC6551Account.sol";


contract AccountRegistry is IRegistry {
    error InitializationFailed();

     function deploy(uint salt, bytes memory bytecode) internal returns (address) {
        bytes memory implInitCode = bytecode;
        address addr;
        assembly {
            let encoded_data := add(0x20, implInitCode) // load initialization code.
            let encoded_size := mload(implInitCode)     // load init code's length.
            addr := create2(0, encoded_data, encoded_size, salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        
        return addr;
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
        
    ) external returns (address) {
        bytes memory code = _creationCode(implementation, chainId, tokenContract, tokenId, salt);

        address _account = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );

        if (_account.code.length != 0) return _account;

        _account = Create2.deploy(0, bytes32(salt), code);

       

        emit AccountCreated(
            _account,
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        return _account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            _creationCode(implementation, chainId, tokenContract, tokenId, salt)
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }

    function _creationCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, chainId_, tokenContract_, tokenId_)
            );
    }
   
}