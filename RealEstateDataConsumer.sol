// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract RealEstateDataConsumer is ChainlinkClient {
    uint256 oraclePayment;

    constructor(uint256 _oraclePayment) {
        setPublicChainlinkToken();
        oraclePayment = _oraclePayment;
    }

    function requestDataSmartZip(
        address _oracle,
        bytes32 _jobId,
        string memory _propertyId
    ) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfillSmartZip.selector
        );
        req.add("property_id", _propertyId);
        return sendChainlinkRequestTo(_oracle, req, oraclePayment);
    }

    uint256 public smartZipData;

    function fulfillSmartZip(
        bytes32 _requestId,
        uint256 _data
    ) public recordChainlinkFulfillment(_requestId) {
        smartZipData = _data;
    }

    function requestDataProspectNow(
        address _oracle,
        bytes32 _jobId,
        string memory _propertyZip
    ) public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfillProspectNow.selector
        );
        req.add("propertyZip", _propertyZip);
        return sendChainlinkRequestTo(_oracle, req, oraclePayment);
    }

    uint256 public prospectNowData;

    function fulfillProspectNow(
        bytes32 _requestId,
        uint256 _data
    ) public recordChainlinkFulfillment(_requestId) {
        prospectNowData = _data;
    }

    function isPropertyOverAverage(
        uint _squareFootage
    ) public view returns (bool) {
        //return true if property valuation is over the average
        //price per sqft x given sqft
        return ((smartZipData * 10 ** 8) > (prospectNowData * _squareFootage));
    }

    function getPropertyAverage(
        uint _squareFootage
    ) public view returns (uint) {
        //return average of property value and ZIP code average x square footage
        return (((smartZipData * 10 ** 8) +
            (prospectNowData * _squareFootage)) / 2);
    }
}
