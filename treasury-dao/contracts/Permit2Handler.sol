// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Permit2Handler is Ownable {
    mapping(address => uint256) public nonces;

    event PermitUsed(address indexed from, address indexed to, uint256 amount);
    
    constructor(address initialOwner) Ownable(initialOwner) {}

    function permitTransfer(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Permit expired");

        bytes32 permitHash = keccak256(
            abi.encodePacked(from, to, amount, nonces[from]++, deadline)
        );

        address signer = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", permitHash)),
            v, r, s
        );

        require(signer == from, "Invalid permit signature");
        require(IERC20(token).transferFrom(from, to, amount), "Transfer failed");

        emit PermitUsed(from, to, amount);
    }
}
