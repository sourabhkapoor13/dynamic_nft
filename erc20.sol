// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.11;

interface IERC20{
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient,uint amount) external returns(bool);
    function approve(address _owner,address _spender,uint _value) external returns(uint);
    function transferFrom(address _from,address _to,uint _value) external returns (bool);


    event Transfer(address indexed from, address indexed to , uint value);

}


contract erc20 is IERC20{
    string public  name = "EthTK";
    string public symbol = 'ETK';
    uint public  decimals = 10000;

    event Approval(address indexed tokenOwner,address indexed spender ,uint tokens);
    

    mapping(address=>uint) balances;
    mapping(address=>mapping(address =>uint)) allowed;

    uint totalSupply_ =10000;
    address admin;
    
    constructor()  {
        
         admin = msg.sender;

    }

    function totalSupply() public override view returns(uint){
        return totalSupply_;

    }

    function balanceOf(address tokenOwner) public override view returns(uint){
        return balances[tokenOwner];
    }

    function transfer(address receiver,uint numTokens) public override returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -=numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender,receiver,numTokens);
        return true;
    }

    modifier onlyAdmin{
        require(msg.sender == admin , "only admin can run this function");
        _;
    }

    function mint(uint _qty) public  returns(uint){
        totalSupply_ += _qty;
        balances[msg.sender] += _qty;
        return totalSupply_; 
    }

    function burn(uint _qty) public  onlyAdmin returns(uint){
        totalSupply_ -= _qty;
        balances[msg.sender] -= _qty;
        return totalSupply_; 
    }

    function allowence(address _owner,address _spender) public view returns(uint){
        return allowed[_owner][_spender];
    }

    function approve(address _owner,address _spender,uint _value) public returns(uint){
        allowed[_owner][_spender] =_value;
        emit Approval(_owner,_spender,_value);
        return _value;
    }


    //spender will run transfer from function
    function transferFrom(address _from,address _to,uint _value) public returns (bool){
        uint allow = allowed[_from][msg.sender];
        require(balances[_from]>=_value && allow>=_value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -=_value; 
         
         return true;
        
    }
}