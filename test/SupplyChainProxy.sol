
pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// Using a proxy to simulate a Buyer or a Seller 
contract SupplyChainProxy{
    SupplyChain testChain;

    /// @notice Constructor for tester
    /// @param _chain Supplychain used for testing
    constructor(SupplyChain _chain) public{
        testChain = _chain;
    }

    /// Allow contract to receive ether
    function() external payable {}

    function getTestChain()
    public view returns (SupplyChain)
    {
        return testChain;
    }

    function sellItem(string memory name, uint price)
    public
    {
        testChain.addItem(name,price);
    }

    function buyItem(uint sku, uint price)
    public
    returns(bool){
        (bool success, ) = address(testChain).call.value(price)(abi.encodeWithSignature("buyItem(uint256)", sku));
        return success;
    }

    function shipItem(uint sku)
        public
        returns (bool)
    {
        /// invoke `supplyChain.shipItem(sku)` with msg.sender set to the address of this proxy
        (bool success, ) = address(testChain).call(abi.encodeWithSignature("shipItem(uint256)", sku));
        return success;
    }
    function receiveItem(uint sku)
        public
        returns (bool)
    {
        /// invoke `receiveChain.shipItem(sku)` with msg.sender set to the address of this proxy
        (bool success, ) = address(testChain).call(abi.encodeWithSignature("receiveItem(uint256)", sku));
        return success;
    }
}