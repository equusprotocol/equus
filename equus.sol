pragma solidity ^0.6.6;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

interface Staking {

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount) external returns (bool);
    function stakeFor(address user, uint256 amount) external returns (bool);
    function unstake(uint256 amount) external returns (bool);
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function supportsHistory() external pure returns (bool);

}

contract EQUUSProtocol is IERC20, Staking {
    string public constant name = "EQUUS";
    string public constant symbol = "EQUUS";
    uint8 public constant decimals = 18;
    
    address public constant burnaddress = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) balances;
    
    mapping(address => uint256) stakedbalances;
    
    mapping(address => uint) staketimestamps;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    uint256 totalstaked = 0;
    address theowner;
    
    using SafeMath for uint256;
    
    constructor() public {
        totalSupply_ = 100000000;
        balances[msg.sender] = totalSupply_;
        theowner = msg.sender;
   }
   
   function totalSupply() public override view returns (uint256) {
       return totalSupply_;
   }
   
   function balanceOf(address tokenOwner) public override view returns (uint) {
       return balances[tokenOwner];
   }
   
   function burn(uint256 a) public pure returns (uint256) {
       uint256 c = a.div(20);
       return c;
   }
   
   function transfer(address receiver, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       balances[msg.sender] = balances[msg.sender].sub(numTokens);
       
       //uint256 burn = burn(numTokens);
       
       balances[receiver] = balances[receiver].add(numTokens);//.sub(burn));
       //balances[address(0)] = balances[address(0)].add(burn);
       emit Transfer(msg.sender, receiver, numTokens);//.sub(burn));
       return true;
   }
   
   function approve(address delegate, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       allowed[msg.sender][delegate] = numTokens;
       emit Approval(msg.sender, delegate, numTokens);
       return true;
   }
   
   function allowance(address owner, address delegate) public override view returns (uint) {
       return allowed[owner][delegate];
   }
   
   function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
       require(numTokens <= balances[owner], 'Amount exceeds balance.');
       require(numTokens <= allowed[owner][msg.sender], 'Amount exceeds allowance.');
       
       balances[owner] = balances[owner].sub(numTokens);
       allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
       balances[buyer] = balances[buyer].add(numTokens);
       emit Transfer(owner, buyer, numTokens);
       return true;
   }
   
   //Staking processes
   
   function stake(uint256 amount) public override returns (bool) {
       require(amount <= balances[msg.sender]);
       balances[msg.sender] = balances[msg.sender].sub(amount);
       
       uint256 burned = burn(amount);
       
       totalSupply_ = totalSupply_.sub(burned);
       
       balances[burnaddress] = balances[burnaddress].add(burned);
       
       stakedbalances[msg.sender] = stakedbalances[msg.sender].add(amount.sub(burned));
       totalstaked = totalstaked.add(amount.sub(burned));
       
       staketimestamps[msg.sender] = time();
       
       emit Staked(msg.sender, amount.sub(burned), stakedbalances[msg.sender], 'Staking');
       return true;
   }
   
   function stakeFor(address user, uint256 amount) public override returns (bool) {
       require(amount <= balances[user]);
       require(theowner == msg.sender);
       balances[user] = balances[user].sub(amount);
       
       uint256 burned = burn(amount);
       
       totalSupply_ = totalSupply_.sub(burned);
       
       balances[burnaddress] = balances[burnaddress].add(burned);
       
       stakedbalances[user] = stakedbalances[user].add(amount.sub(burned));
       totalstaked = totalstaked.add(amount.sub(burned));
       
       staketimestamps[msg.sender] = time();
       
       emit Staked(user, amount.sub(burned), stakedbalances[user], 'Staking');
       
       return true;
   }
   
   function unstake(uint256 amount) public override returns (bool) {
       require(amount <= stakedbalances[msg.sender]);
       require(amount <= totalstaked);
       stakedbalances[msg.sender] = stakedbalances[msg.sender].sub(amount);
       totalstaked = totalstaked.sub(amount);
       
       uint256 burned = burn(amount);
       
       totalSupply_ = totalSupply_.sub(burned);
       
       balances[burnaddress] = balances[burnaddress].add(burned);
       
       balances[msg.sender] = balances[msg.sender].add(amount.sub(burned));
       
       emit Unstaked(msg.sender, amount.sub(burned), stakedbalances[msg.sender], 'Stake being untaked');
       
       return true;
   }
   
   function totalStakedFor(address addr) public override view returns (uint256) {
       return stakedbalances[addr];
   }
   
   function stakeTimestampFor(address addr) public view returns (uint256) {
       return staketimestamps[addr];
   }
   
   function stakeTimeFor(address addr) public view returns (uint256) {
       return time().sub(staketimestamps[addr]);
   }
   
   function totalStaked() public override view returns (uint256) {
       return totalstaked;
   }
   
   function supportsHistory() public override pure returns (bool) {
       return false;
   }
   
   function time() public view returns (uint) {
       return block.timestamp;
   }
   
}
