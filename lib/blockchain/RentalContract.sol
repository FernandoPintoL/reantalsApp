// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RentalContract
 * @dev Smart contract for managing rental agreements
 */
contract RentalContract {
    // Contract states
    enum ContractState { Pending, Approved, Active, Terminated, Expired }
    
    // Contract structure
    struct RentalAgreement {
        uint256 contractId;        // ID of the contract in the conventional system
        address landlord;          // Wallet address of the property owner
        address tenant;            // Wallet address of the tenant
        uint256 propertyId;        // ID of the property in the conventional system
        uint256 rentAmount;        // Monthly rent amount (in wei)
        uint256 depositAmount;     // Security deposit amount (in wei)
        uint256 startDate;         // Start date of the rental period (timestamp)
        uint256 endDate;           // End date of the rental period (timestamp)
        uint256 lastPaymentDate;   // Date of the last payment (timestamp)
        ContractState state;       // Current state of the contract
        string termsHash;          // IPFS hash of the contract terms document
    }
    
    // Mapping from contract ID to rental agreement
    mapping(uint256 => RentalAgreement) public rentalAgreements;
    
    // Events
    event ContractCreated(uint256 indexed contractId, address indexed landlord, address indexed tenant);
    event ContractApproved(uint256 indexed contractId);
    event ContractActivated(uint256 indexed contractId);
    event PaymentReceived(uint256 indexed contractId, uint256 amount, uint256 timestamp);
    event ContractTerminated(uint256 indexed contractId, string reason);
    event ContractExpired(uint256 indexed contractId);
    
    /**
     * @dev Create a new rental contract
     */
    function createContract(
        uint256 _contractId,
        address _landlord,
        address _tenant,
        uint256 _propertyId,
        uint256 _rentAmount,
        uint256 _depositAmount,
        uint256 _startDate,
        uint256 _endDate,
        string memory _termsHash
    ) public {
        require(rentalAgreements[_contractId].contractId == 0, "Contract ID already exists");
        require(_startDate < _endDate, "End date must be after start date");
        
        RentalAgreement memory newAgreement = RentalAgreement({
            contractId: _contractId,
            landlord: _landlord,
            tenant: _tenant,
            propertyId: _propertyId,
            rentAmount: _rentAmount,
            depositAmount: _depositAmount,
            startDate: _startDate,
            endDate: _endDate,
            lastPaymentDate: 0,
            state: ContractState.Pending,
            termsHash: _termsHash
        });
        
        rentalAgreements[_contractId] = newAgreement;
        
        emit ContractCreated(_contractId, _landlord, _tenant);
    }
    
    /**
     * @dev Approve the contract by the tenant
     */
    function approveContract(uint256 _contractId) public {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "Contract does not exist");
        require(agreement.state == ContractState.Pending, "Contract is not in pending state");
        require(msg.sender == agreement.tenant, "Only tenant can approve the contract");
        
        agreement.state = ContractState.Approved;
        
        emit ContractApproved(_contractId);
    }
    
    /**
     * @dev Make a payment to activate the contract or pay monthly rent
     */
    function makePayment(uint256 _contractId) public payable {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "Contract does not exist");
        require(agreement.state == ContractState.Approved || agreement.state == ContractState.Active, 
                "Contract must be approved or active");
        require(msg.sender == agreement.tenant, "Only tenant can make payments");
        
        // For first payment, check if deposit + first month rent is paid
        if (agreement.state == ContractState.Approved) {
            require(msg.value >= agreement.rentAmount + agreement.depositAmount, 
                    "First payment must include deposit and first month rent");
            
            agreement.state = ContractState.Active;
            emit ContractActivated(_contractId);
        } else {
            // For subsequent payments, check if monthly rent is paid
            require(msg.value >= agreement.rentAmount, "Payment must be at least the rent amount");
        }
        
        // Transfer the payment to the landlord
        payable(agreement.landlord).transfer(msg.value);
        
        // Update last payment date
        agreement.lastPaymentDate = block.timestamp;
        
        emit PaymentReceived(_contractId, msg.value, block.timestamp);
    }
    
    /**
     * @dev Terminate the contract before its end date
     */
    function terminateContract(uint256 _contractId, string memory _reason) public {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "Contract does not exist");
        require(agreement.state == ContractState.Active, "Contract must be active");
        require(msg.sender == agreement.landlord || msg.sender == agreement.tenant, 
                "Only landlord or tenant can terminate the contract");
        
        agreement.state = ContractState.Terminated;
        
        emit ContractTerminated(_contractId, _reason);
    }
    
    /**
     * @dev Check if a contract has expired and update its state if needed
     */
    function checkExpiration(uint256 _contractId) public {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "Contract does not exist");
        require(agreement.state == ContractState.Active, "Contract must be active");
        
        if (block.timestamp > agreement.endDate) {
            agreement.state = ContractState.Expired;
            emit ContractExpired(_contractId);
        }
    }
    
    /**
     * @dev Get contract details
     */
    function getContractDetails(uint256 _contractId) public view returns (
        address landlord,
        address tenant,
        uint256 propertyId,
        uint256 rentAmount,
        uint256 depositAmount,
        uint256 startDate,
        uint256 endDate,
        uint256 lastPaymentDate,
        ContractState state,
        string memory termsHash
    ) {
        RentalAgreement memory agreement = rentalAgreements[_contractId];
        require(agreement.contractId != 0, "Contract does not exist");
        
        return (
            agreement.landlord,
            agreement.tenant,
            agreement.propertyId,
            agreement.rentAmount,
            agreement.depositAmount,
            agreement.startDate,
            agreement.endDate,
            agreement.lastPaymentDate,
            agreement.state,
            agreement.termsHash
        );
    }
}