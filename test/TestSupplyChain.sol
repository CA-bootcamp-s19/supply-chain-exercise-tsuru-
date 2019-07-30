pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./SupplyChainProxy.sol";

contract TestSupplyChain {
    uint public initialBalance = 1 ether;

    //Creating test supplychain and two actors (Buyer and Seller) for the testing purposes
    SupplyChain public chain;
    SupplyChainProxy seller;
    SupplyChainProxy buyer;
    SupplyChainProxy randomUser;



    //Creating state enum matching the contract one
    enum State {ForSale, Sold, Shipped, Received}

    /// Allow contract to receive ether
    function() external payable {}
    
    string itemName = "Phone";
    uint itemPrice = 200;
    uint itemSku = 0;

    //Function run by Truffle before each test
    function beforeEach() public{

        chain = new SupplyChain();
        seller = new SupplyChainProxy(chain);
        buyer = new SupplyChainProxy(chain);
        randomUser = new SupplyChainProxy(chain);


        address(buyer).transfer(itemPrice+1); //Giving the buyer enough funds for the transaction
        seller.sellItem(itemName,itemPrice); //The seller offer his item
    }

    function getItemState(uint256 _expectedSku)
        public view
        returns (uint256)
    {
        string memory _name;
        uint _sku;
        uint _price;
        uint _state;
        address _seller;
        address _buyer;

        ( _name, _sku, _price, _state, _seller, _buyer) = chain.fetchItem(_expectedSku);
        return _state;
    }

    // buyItem
    function testSuccessBuy() public{
        bool result = buyer.buyItem(itemSku,itemPrice);
        Assert.isTrue(result,"Item bought with success");
        Assert.equal(getItemState(itemSku), (uint)(State.Sold), "Item should be Sold");
    }
    // test for failure if user does not send enough funds
    function testBuyerNotEnoughFunds() public{
        uint itemOffer = itemPrice -1;
        bool result = buyer.buyItem(itemSku,itemOffer);
        Assert.isFalse(result,"Try to pay less for one item");
        Assert.equal(getItemState(itemSku), (uint)(State.ForSale), "State should be ForSale");
    }
    // test for purchasing an item that is not for Sale
    function testPurchaseItemNotForSale() public{
        uint skuAttempt = itemSku + 1;
        bool result = buyer.buyItem(skuAttempt, itemPrice); // Buyer tries to buy item not added
        Assert.isFalse(result,"Buyer failed to buy unexisting item");
    }

    // shipItem
    function testSuccesfulShipping() public {
        // Purchase item
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item succesfully bought.");

        result = seller.shipItem(itemSku);
        Assert.isTrue(result, "Seller successfully shipped");

        // Check if the state is correctly changed
        Assert.equal(getItemState(itemSku), uint256(State.Shipped), "State should be Shipped");
    }
    // test for calls that are made by not the seller
    function testAnotherUserCannotShip() public {
        // Purchase item
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item succesfully bought.");

        result = randomUser.shipItem(itemSku);
        Assert.isFalse(result, "Shipping by different user failed");

        //Check if state is still sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "State should remain Sold");
    }

    // test for trying to ship an item that is not marked Sold
    function testShippingForSaleItem() public {
        bool result = seller.shipItem(itemSku);
        Assert.isFalse(result, "Cannot ship unsold item");

        //Check if state is still ForSale
        Assert.equal(getItemState(itemSku), uint256(State.ForSale), "State should remain ForSale");
    }

    // receiveItem
    function testReceiveItem() public {
        // Purchase item
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item succesfully bought.");

        // Ship item
        result = seller.shipItem(itemSku);
        Assert.isTrue(result, "Seller successfully shipped");

        // Receive
        result = buyer.receiveItem(itemSku);
        Assert.isTrue(result, "Buyer received the item");

        // Verify state is Receiver
        Assert.equal(getItemState(itemSku), uint256(State.Received), "State should be Received");
    }

    // test calling the function from an address that is not the buyer
    function testAnotherUserCannotReceive() public {
        // Purchase item
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item succesfully bought.");

        // Ship item
        result = seller.shipItem(itemSku);
        Assert.isTrue(result, "Seller successfully shipped");

        // Try to receive item
        result = randomUser.receiveItem(itemSku);
        Assert.isFalse(result, "Only buyer can receive the item");

        // Verify state is still Shipped
        Assert.equal(getItemState(itemSku), uint256(State.Shipped), "State should remain Shipped");
    }
    // test calling the function on an item not marked Shipped
    function testReceiveItemNotShipped() public {
        // Purchase item
        bool result = buyer.buyItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item succesfully bought.");

        // Try to receive item
        result = buyer.receiveItem(itemSku);
        Assert.isFalse(result, "Buyer can't receive item before shipping");

        // Verify state is stil Sold
        Assert.equal(getItemState(itemSku), uint256(State.Sold), "State should remain sold");
    }


}
