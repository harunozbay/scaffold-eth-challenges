// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    event Stake(address, uint256);
    event Execute(address);
    event Withdraw(address, uint256);
    event Receive(address, uint256);

    mapping(address => uint256) public balances;
    uint256 public threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool openForWithdraw = false;

    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "External contract completed."
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable {
        require(block.timestamp < deadline, "The deadline has passed.");
        require(msg.value > 0, "You have no wei to stake");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function execute() public notCompleted {
        require(
            block.timestamp >= deadline,
            "The deadline has not passed yet."
        );
        if (address(this).balance > threshold)
            exampleExternalContract.complete{value: address(this).balance}();
        else openForWithdraw = true;
        emit Execute(msg.sender);
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public payable notCompleted {
        require(openForWithdraw);
        uint256 amount = balances[msg.sender];
        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        emit Receive(msg.sender, msg.value);
        stake();
    }
}
