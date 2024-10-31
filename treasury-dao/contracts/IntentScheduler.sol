// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract IntentScheduler is ReentrancyGuard {
    struct Intent {
        address token;
        address to;
        uint256 amount;
        uint256 nextExecutionTime;
        uint256 interval;
    }

    mapping(address => Intent) public intents;

    event IntentCreated(address indexed user, address indexed to, uint256 amount, uint256 interval);
    event IntentExecuted(address indexed user, uint256 amount);

    function createIntent(
        address token,
        address to,
        uint256 amount,
        uint256 interval
    ) external {
        require(intents[msg.sender].nextExecutionTime == 0, "Intent already exists");
        require(interval > 0, "Invalid interval");

        intents[msg.sender] = Intent({
            token: token,
            to: to,
            amount: amount,
            nextExecutionTime: block.timestamp + interval,
            interval: interval
        });

        emit IntentCreated(msg.sender, to, amount, interval);
    }

    function executeIntent() external nonReentrant {
        Intent storage intent = intents[msg.sender];
        require(intent.nextExecutionTime != 0, "Intent not found");
        require(block.timestamp >= intent.nextExecutionTime, "Too early to execute");

        IERC20(intent.token).transferFrom(msg.sender, intent.to, intent.amount);
        intent.nextExecutionTime += intent.interval;

        emit IntentExecuted(msg.sender, intent.amount);
    }

    function cancelIntent() external {
        require(intents[msg.sender].nextExecutionTime != 0, "Intent not found");
        delete intents[msg.sender];
    }
}
