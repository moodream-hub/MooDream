// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DLMCore {
    // MooDreamToken 계약 주소 (배포 후 연결 예정)
    address public mooDreamTokenAddress;

    // M 모듈 (MQE)의 검증 결과 (Q_Proof)를 입력받는 핵심 함수
    function record_CSIP(bytes32 qProof) public {
        // Logic Placeholder:
        // 1. Check Q_Proof legitimacy (via Oracle/M Module verification).
        // 2. CSIP Hash is generated and recorded on the ledger.
        pay_creator_fee(); // 수익 분배 함수 자동 호출
    }

    // 수익 분배 로직 (15% 수수료를 창시자에게 보냄)
    function pay_creator_fee() internal {
        // Logic Placeholder:
        // Transfer 15% of the transaction fee (or service fee) 
        // from the user to the CREATOR_WALLET defined in MooDreamToken.
    }
}
// DLMCore.sol 파일 시작 부분에 추가 (pragma solidity 아래)
// ====================================================================
// (추가 1) 외부 계약 인터페이스 선언: 토큰과 PIG 서버 연결
// ====================================================================

// MooDreamToken 계약 인터페이스 (토큰 정보와 CREATOR_WALLET 주소 접근용)
interface IMooDreamToken {
    function CREATOR_WALLET() external view returns (address);
    // 향후 토큰 전송 로직이 추가될 수 있음
}

// PIG 서버 오라클 인터페이스 (MRP 처리를 위해 외부 PIG 서버에 요청)
// Chainlink와의 연동을 가정하여, 요청 ID를 반환하는 구조를 사용합니다.
interface IPIGOracle {
    function request_MRP_process(bytes32 transactionId, address user) external returns (bytes32 requestId);
}

// ====================================================================
// (추가 2) DLMCore 상태 변수: 주소 저장 및 CSIP 기록 배열
// ====================================================================
contract DLMCore {
    // 기존: address public mooDreamTokenAddress; (사용)
    address public pigOracleAddress; // PIG Oracle 서버의 계약 주소

    // CSIP (Code Subject Immutability Protocol) 기록을 위한 맵핑
    mapping(bytes32 => bool) public isCSIPRecorded;
    
    // CSIP 기록 시 발생하는 이벤트 (블록체인 외부에 데이터를 알림)
    event CSIPRecorded(bytes32 indexed csipHash, address indexed creatorAddress, uint256 feeAmount);

    // ... 기존 코드 계속 (라인 9의 record_CSIP 함수 정의로 이동)
// ====================================================================
// M 모듈 (MQE)의 검증 결과 (Q_Proof)를 입력받는 핵심 함수
function record_CSIP(bytes32 qProof) public payable {
    // ====================================================================
    // 1. M 모듈 검증 강제 (오라클 시스템 통합)
    // - Q_Proof는 오라클 시스템을 통해 유효성이 사전 검증되었음을 가정하고,
    // - 추가적인 온체인 검증이 필요하다면 여기에 코드를 삽입합니다.
    require(qProof != bytes32(0), "MooOS: Invalid Q_Proof from MQE.");
    
    // 2. CSIP 해시 생성 (불변성 기록)
    bytes32 csipHash = keccak256(abi.encodePacked(qProof, msg.sender, block.timestamp));
    require(!isCSIPRecorded[csipHash], "MooOS: CSIP already recorded.");
    isCSIPRecorded[csipHash] = true;
    
    // 3. MRP (개인 정보 처리) 연동
    // - PIG 서버에 트랜잭션의 ID와 사용자 주소를 보내 개인 정보 처리를 요청합니다.
    IPIGOracle(pigOracleAddress).request_MRP_process(csipHash, msg.sender);
    
    // 4. 수익 분배 함수 호출
    pay_creator_fee();
    
    // 5. CSIP 기록 이벤트 발생 (외부 서비스 및 P2P에 불변성 기록을 알림)
    IMooDreamToken tokenContract = IMooDreamToken(mooDreamTokenAddress);
    emit CSIPRecorded(csipHash, tokenContract.CREATOR_WALLET(), msg.value);

    // ====================================================================
}
// 수익 분배 로직 (15% 수수료를 창시자에게 보냄)
function pay_creator_fee() internal {
    // ====================================================================
    // 1. 창시자 지갑 주소 불러오기
    IMooDreamToken tokenContract = IMooDreamToken(mooDreamTokenAddress);
    address creator = tokenContract.CREATOR_WALLET();
    
    // 2. 수수료 계산: 트랜잭션으로 받은 전체 Ether/Token의 15%
    uint256 totalFee = msg.value; // 사용자가 트랜잭션에 첨부한 Ether
    uint256 creatorCut = totalFee * 15 / 100; // 15% 계산
    
    // 3. 수익 이체 강제 (N 모듈의 핵심 기능)
    (bool success, ) = creator.call{value: creatorCut}("");
    require(success, "MooOS: Creator fee transfer failed.");

    // ====================================================================
}
