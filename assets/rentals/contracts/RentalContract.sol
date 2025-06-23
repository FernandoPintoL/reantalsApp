// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title RentalContract
 * @dev Smart contract for managing rental agreements
 */
contract RentalContract {
    // Contract states
    enum ContractState { Pending, Approved, Active, Terminated, Expired }
    
    // Contract structure
    struct RentalAgreement {
        uint256 contractId;        // Identificación del contrato en el sistema convencional
        address landlord;          // Dirección de la billetera del propietario de la propiedad
        address tenant;            // Dirección de la billetera del inquilino
        uint256 propertyId;        // Identificación del inmueble en el sistema convencional
        uint256 rentAmount;        // Monto del alquiler mensual (en wei)
        uint256 depositAmount;     // Monto del depósito de seguridad (en wei)
        uint256 startDate;         // Fecha de inicio del período de alquiler (marca de tiempo)
        uint256 endDate;           // Fecha de finalización del período de alquiler (marca de tiempo)
        uint256 lastPaymentDate;   // Fecha del último pago (sello de tiempo)
        ContractState state;       // Estado actual del contrato
        string termsHash;          // IPFS hash of the contract terms documentHash IPFS del documento de términos del contrato
    }
    
    // Mapping from contract ID to rental agreement
    mapping(uint256 => RentalAgreement) public rentalAgreements;
    // Owner of the contract
    address public owner;

    // Events
    event ContractCreated(uint256 indexed contractId, address indexed landlord, address indexed tenant);
    event ContractApproved(uint256 indexed contractId);
    event ContractActivated(uint256 indexed contractId);
    event PaymentReceived(uint256 indexed contractId, uint256 amount, uint256 timestamp);
    event ContractTerminated(uint256 indexed contractId, string reason);
    event ContractExpired(uint256 indexed contractId);
    /**
     * @dev Constructor to initialize the contract
     */
    constructor() {
        owner = msg.sender;
    }

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
        require(_contractId > 0, "El ID del contrato debe ser positivo");
        require(rentalAgreements[_contractId].contractId == 0, "El ID del contrato ya existe");
        require(_landlord != address(0), "Direccion de propietario no valida");
        require(_tenant != address(0), "Direccion de inquilino no valida");
        require(_startDate < _endDate, "La fecha de finalizacion debe ser posterior a la fecha de inicio");
        require(_rentAmount > 0, "El importe del alquiler debe ser positivo");

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
        
        require(agreement.contractId != 0, "El contrato no existe");
        require(agreement.state == ContractState.Pending, "El contrato no esta en estado pendiente");
        require(msg.sender == agreement.tenant, "Solo el inquilino puede aprobar el contrato.");
        
        agreement.state = ContractState.Approved;
        
        emit ContractApproved(_contractId);
    }
    
    /**
     * @dev Make a payment to activate the contract or pay monthly rent
     */
    function makePayment(uint256 _contractId) public payable {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "El contrato no existe");
        require(agreement.state == ContractState.Approved || agreement.state == ContractState.Active, 
                "El contrato debe estar aprobado o activo");
        require(msg.sender == agreement.tenant, "Solo el inquilino puede hacer pagos");
        
        // For first payment, check if deposit + first month rent is paid
        if (agreement.state == ContractState.Approved) {
            require(msg.value >= agreement.rentAmount + agreement.depositAmount, 
                    "El primer pago debe incluir el deposito y el primer mes de alquiler.");
            
            agreement.state = ContractState.Active;
            emit ContractActivated(_contractId);
        } else {
            // For subsequent payments, check if monthly rent is paid
            require(msg.value >= agreement.rentAmount, "El pago debe ser al menos el monto del alquiler.");
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
        
        require(agreement.contractId != 0, "El contrato no existe");
        require(agreement.state == ContractState.Active, "El contrato debe estar activo.");
        require(msg.sender == agreement.landlord || msg.sender == agreement.tenant, 
                "Solo el propietario o el inquilino pueden rescindir el contrato");
        
        agreement.state = ContractState.Terminated;
        
        emit ContractTerminated(_contractId, _reason);
    }
    
    /**
     * @dev Check if a contract has expired and update its state if needed
     */
    function checkExpiration(uint256 _contractId) public {
        RentalAgreement storage agreement = rentalAgreements[_contractId];
        
        require(agreement.contractId != 0, "El contrato no existe");
        require(agreement.state == ContractState.Active, "El contrato debe estar activo.");
        
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
        require(agreement.contractId != 0, "El contrato no existe");
        
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