// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract EscrowManager {
    enum EscrowState {
        AWAITING_PAYMENT, // buyer haven't added the money
        AWAITING_DELIVERY, // money has been added
        DISPUTED, // buyer disputed with seller work
        COMPLETED, // seller wins
        REFUNDED // buyer wins
    }

    struct Escrow {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount; // agrred amount for escrow
        EscrowState state;
        uint256 balance; // amount present in escrow
    }

    uint256 public escrowCounter = 0;
    mapping(uint256 => Escrow) public escrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        address arbiter,
        uint256 amount
    );

    event Deposited(
        uint256 indexed escrowId,
        address indexed buyer,
        uint256 amount
    );

    event Released(uint256 indexed escrowId, address indexed buyer);

    event Disputed(uint256 indexed escrowId, address indexed buyer);

    event Resolved(
        uint256 indexed escrowId,
        address indexed arbiter,
        bool releasedToSeller
    );

    event Withdrawn(
        uint256 indexed escrowId,
        address indexed receiver,
        uint256 amount
    );

    modifier verifyAddress(address _address, string memory message) {
        require(_address != address(0), message);
        _;
    }

    // Function for creating escrow
    // Buyer can also pay amount at the time of creation only | can pay later too
    function createEscrow(
        address seller,
        address arbiter,
        uint256 amount
    )
        external
        payable
        verifyAddress(seller, "Invalid seller")
        verifyAddress(arbiter, "Invalid arbiter")
        returns (uint256 escrowId)
    {
        require(amount > 0, "Amount = 0");
        require(msg.value == 0 || msg.value == amount, "Invalid eth sent");
        require(seller != msg.sender, "Seller = buyer");
        require(arbiter != msg.sender, "Arbiter = buyer");
        require(arbiter != seller, "Arbiter = seller");

        escrowId = ++escrowCounter;

        escrows[escrowId] = Escrow({
            buyer: msg.sender,
            seller: seller,
            arbiter: arbiter,
            amount: amount,
            balance: msg.value,
            state: msg.value == 0
                ? EscrowState.AWAITING_PAYMENT
                : EscrowState.AWAITING_DELIVERY
        });

        emit EscrowCreated(escrowId, msg.sender, seller, arbiter, amount);

        if (msg.value == amount) {
            emit Deposited(escrowId, msg.sender, amount);
        }
    }

    // Buyer can deposit money - if not deposited at time of creation
    // paid money should be equal to the decided money
    function deposit(uint256 escrowId) external payable {
        require(escrowId > 0 && escrowId <= escrowCounter, "No escrow found");
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.buyer, "Not buyer");
        require(e.state == EscrowState.AWAITING_PAYMENT, "Invalid state");
        require(e.balance == 0, "Amount already paid");
        require(msg.value == e.amount, "Invalid eth sent");

        e.balance = msg.value;
        e.state = EscrowState.AWAITING_DELIVERY;
        emit Deposited(escrowId, msg.sender, e.amount);
    }

    // when buyer is okk with seller work, he can release his money
    function release(uint256 escrowId) external {
        require(escrowId > 0 && escrowId <= escrowCounter, "No escrow found");
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.buyer, "Not buyer");
        require(e.state == EscrowState.AWAITING_DELIVERY, "Invalid state");

        e.state = EscrowState.COMPLETED;
        emit Released(escrowId, msg.sender);
    }

    // If buyer is not okay with seller work, it can apply for dispute
    function dispute(uint256 escrowId) external {
        require(escrowId > 0 && escrowId <= escrowCounter, "No escrow found");
        Escrow storage e = escrows[escrowId];
        require(msg.sender == e.buyer, "Not buyer");
        require(e.state == EscrowState.AWAITING_DELIVERY, "Invalid state");

        e.state = EscrowState.DISPUTED;
        emit Disputed(escrowId, msg.sender);
    }

    // The disputer decides, who gets the money
    function resolve(uint256 escrowId, bool releaseToSeller) external {
        require(escrowId > 0 && escrowId <= escrowCounter, "No escrow found");
        Escrow storage e = escrows[escrowId];

        require(msg.sender == e.arbiter, "Not arbiter");
        require(e.state == EscrowState.DISPUTED, "Invalid state");
        e.state = releaseToSeller
            ? EscrowState.COMPLETED
            : EscrowState.REFUNDED;

        emit Resolved(escrowId, msg.sender, releaseToSeller);
    }

    // If current state is Refunded, buyer can withdraw his money
    // If current state is Completed, seller can withdraw his money
    function withdraw(uint256 escrowId) external {
        require(escrowId > 0 && escrowId <= escrowCounter, "No escrow found");

        Escrow storage e = escrows[escrowId];

        require(
            e.state == EscrowState.COMPLETED || e.state == EscrowState.REFUNDED,
            "Escrow not settled"
        );

        uint256 payout = e.balance;
        require(payout > 0, "Nothing to withdraw");

        if (e.state == EscrowState.COMPLETED) {
            require(msg.sender == e.seller, "Not seller");
        } else {
            require(msg.sender == e.buyer, "Not buyer");
        }
        e.balance = 0;

        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(escrowId, msg.sender, payout);
    }
}
