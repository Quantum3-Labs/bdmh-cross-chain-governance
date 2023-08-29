// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MetaHumanGovernor.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "../src/vhm-token/VHMToken.sol";
import "../src/hm-token/HMToken.sol";
import "./DeploymentUtils.sol";

contract PrepareHubTesting is Script, DeploymentUtils {
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        address automaticRelayerAddress = vm.envAddress("HUB_AUTOMATIC_RELAYER_ADDRESS");
        uint16 chainId = uint16(vm.envUint("HUB_CHAIN_ID"));
        HMToken hmToken = new HMToken(1000 ether, "HMToken", 18, "HMT");
        hmToken.transfer(secondAddress, 100 ether);
        hmToken.transfer(thirdAddress, 100 ether);
        VHMToken voteToken = new VHMToken(IERC20(address(hmToken)));
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        CrossChainGovernorCountingSimple.CrossChainAddress[] memory spokeContracts = new CrossChainGovernorCountingSimple.CrossChainAddress[](0);
        proposers[0] = deployerAddress;
        executors[0] = address(0);
        TimelockController timelockController = new TimelockController(1, proposers, executors, deployerAddress);
        MetaHumanGovernor governanceContract = new MetaHumanGovernor(voteToken, timelockController, spokeContracts, chainId, hubAutomaticRelayerAddress, deployerAddress);
        timelockController.grantRole(keccak256("PROPOSER_ROLE"), address(governanceContract));
        timelockController.revokeRole(keccak256("TIMELOCK_ADMIN_ROLE"), deployerAddress);

        vm.stopBroadcast();

        vm.startBroadcast(secondPrivateKey);
        hmToken.approve(address(voteToken), 10 ether);
        voteToken.depositFor(address(secondAddress), 10 ether);
        vm.stopBroadcast();

        vm.startBroadcast(thirdPrivateKey);
        hmToken.approve(address(voteToken), 10 ether);
        voteToken.depositFor(address(thirdAddress), 10 ether);
        vm.stopBroadcast();
    }
}
