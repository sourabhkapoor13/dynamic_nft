// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./IERC6551Registry.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract dynamic_mint is ERC721URIStorage, AutomationCompatibleInterface {
    using Counters for Counters.Counter;
    Counters.Counter _tokenId;
    struct nft_data {
        address _address;
        bool executed;
    }
    uint256 public counter;
    uint256 public lastTimeStamp;
    uint256 public interval;
    string static_uri;
    IRegistry _AccountRegistry;
    mapping(uint256 => nft_data) public  nft;

    mapping(address => string[]) public uri;

    mapping(uint256 => uint256) public nft_turn;

    mapping(uint256 => string[]) public nft_uri;

    

    // fix the interval
    constructor(uint256 _interval, address _address) ERC721("Mayank", "nft") {
        _AccountRegistry = IRegistry(_address);
        interval = _interval;
        lastTimeStamp = block.timestamp;
    }

    // minting dynamic nft
    function dynamic_nft() public {
        _tokenId.increment();
        uint256 newItemId = _tokenId.current();
        string memory tokenURI = uri[msg.sender][0];

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        nft_turn[newItemId] = 0;
        nft_uri[newItemId] = uri[msg.sender];
    }

    function transfer(address new_owner, uint256 nft_ids) public {
        _safeTransfer(msg.sender, new_owner, nft_ids, "");
    }

    //      minting static nft

    function static_nft() public returns (uint256, address) {
        address implementation = 0x4d15998939cc2B2F580076e585A258650d0Fe68D;
        static_uri = "https://gateway.pinata.cloud/ipfs/QmXNdafRs7G839NgsHzm1pnpzRDJNdwnA86GdzvAG1eC6k/";

        _tokenId.increment();

        uint256 newItemId = _tokenId.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(
            newItemId,
            string(
                abi.encodePacked(
                    static_uri,
                    Strings.toString(newItemId),
                    ".json"
                )
            )
        );
        address nftaddress = _AccountRegistry.account(
            implementation,
            80001,
            address(this),
            newItemId,
            1
        );
        nft[newItemId]._address = nftaddress;

        return (newItemId, nftaddress);
    }

    function deploy(uint256 id) public returns (address,string memory) {
        require( nft[id].executed==false,"already deployed");
        address _address;
        address implementation = 0x4d15998939cc2B2F580076e585A258650d0Fe68D;
        require(msg.sender == ownerOf(id), "not allowed");
       _address= _AccountRegistry.createAccount(
            implementation,
            80001,
           address(this) ,
            id,
            1
        );

    
        nft[id].executed=true;

        return(_address, "deployed");
    }

    function set_counter(uint256 _counter) public {
        counter = _counter;
    }

    // burn minted nft
    function burn_nft(uint256 id) public returns (uint256) {
        _burn(id);
        return id;
    }

    //      get current id of nft

    function get_ItemId() public view returns (uint256) {
        uint256 id = _tokenId.current();
        return id;
    }

    //      here dynamic nft metadata are changing

    function changeNFT(uint256 tokenId) private {
        require(nft_turn[tokenId] < 6, "we can not exceed than 6");

        uint256 current_uri = nft_turn[tokenId] + 1;
        string memory newUri = nft_uri[tokenId][current_uri];

        _setTokenURI(tokenId, newUri);
        nft_turn[tokenId] += 1;
    }

    function set_uri(string memory _uri) public {
        uri[msg.sender].push(_uri);
    }

    // oracle function which will get data offchain and run our onchain data

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        //         upkeepNeeded=x.on("nft_id", (event) => {
        //   console.log("Transfer event emitted:", event);
        // });
        upkeepNeeded =
            (block.timestamp - lastTimeStamp) > interval &&
            counter > 4;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // this is oracle function which will run automatically when offchain data requirment is met

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // We highly recommend revalidating the upkeep in the performUpkeep function
        require(get_ItemId() > 0, "wrong");
        if ((block.timestamp - lastTimeStamp) > interval && counter > 4) {
            lastTimeStamp = block.timestamp;

            uint256 index = get_ItemId();

            changeNFT(index);
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    //
}
