// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    event RandomNumberGenerated(uint256 lotteryDate, uint256 lastTwoDigits, uint256[] lastThreeDigits, uint256[] lotteryNumbers);
    event WinnerAnnounced( uint256 indexed winningNumber, address indexed winner, uint256 amountWon);

    struct Player {
        address payable playerAddress;
        uint256 number;
        uint256 value;

          
    }

    Player[] private players;
    uint256[] private winningNumbers; // Store winning numbers as state variable
    address private owner;
    address[] private addRewardAddresses;

    struct AddReward {
        address payable addRewardAddress;
    }
        constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }




    function addReward() public payable {
            require(msg.value > 0, "You need to send some ether .");

            if(addRewardAddresses.length == 1){
                require(msg.sender == addRewardAddresses[0]);
            }
            else{
                require(addRewardAddresses.length < 1, "Not a founder.");
            }
            addRewardAddresses.push(payable(msg.sender));
        }

    function buyLottery(string memory numStr) public payable {
        require(msg.value > 1, "You need to send some ether to buy a ticket.");
        require(bytes(numStr).length == 6, "You need to specify a 6-character string.");

        Player memory newPlayer;
        newPlayer.playerAddress = payable(msg.sender);
        newPlayer.number = str2uint(numStr);
        newPlayer.value = msg.value;
        players.push(newPlayer);
    }
    
    function getNumbers() public view returns (string[] memory, address[] memory, uint256[] memory) {
        string[] memory numbers = new string[](players.length);
        address[] memory addresses = new address[](players.length);
        uint256[] memory values = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            numbers[i] = uint2str(players[i].number);
            addresses[i] = players[i].playerAddress;
            values[i] = players[i].value;
        }
        return (numbers, addresses, values);
    }

    function str2uint(string memory _str) internal pure returns (uint256 result) {
        bytes memory b = bytes(_str);
        result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function uint2str(uint256 _num) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 6; i++) {
            buffer[i] = "0";
        }
        uint256 digits = 0;
        while (_num != 0) {
            buffer[5 - digits] = bytes1(uint8(48 + _num % 10));
            _num /= 10;
            digits++;
        }
        return string(buffer);
    }

    function getLength() public view returns (uint256) {
        return players.length;
    }

       function randomNumber() private     view returns (uint256 lotteryDate, uint256 lastTwoDigits, uint256[] memory lastThreeDigits, uint256[] memory lotteryNumbers) {
        // uint256 random1 = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp + 1, players.length)));
        // uint256 random2 = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp + 5, players.length)));
            // ล็อกผล
        uint256 random1 = 123456;
        uint256 random2 = 654321;
        uint256 random3 = 654389;




        // สุ่มเลข 6 ตัวราลวันที่ 1
        lotteryDate = random1 % 1000000;

        // สุ่มเลขท้าย 2 ตัว
        lastTwoDigits = random2 % 100;
        
        // สุ่มเลขท้าย 3 ตัว 2 = ชุด
        lastThreeDigits = new  uint256[](2);
        for   (uint256 i = 0; i < 2; i++) {
            // lastThreeDigits[i] = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp + i, players.length))) % 1000;
            //ล็อกผล
            lastThreeDigits[i] = (random3 + i) %1000 ;

        }


        // สุ่มราลวัลที่ 5 100 ชุด
        lotteryNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            lotteryNumbers[i] = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp + i +5, players.length))) % 1000000;
        }



    }



function checkWinnersAndPayRewards() public {
    require(players.length > 0, "No players participated in the lottery.");
    
    // Get winning numbers from randomNumber function
    (uint256 lotteryDate, uint256 lastTwoDigits, uint256[] memory lastThreeDigits, uint256[] memory lotteryNumbers) = randomNumber();
    
    // Flag to keep track if any player has won
    bool anyWinner = false;
    uint256 totalRewards = 0;

    // Iterate through players
    for(uint256 i = 0; i < players.length; i++) {
        Player memory player = players[i];
        uint256 playerNumber = player.number;
        uint256 reward = 0;

        // Check if player's number matches any of the winning numbers
        if (playerNumber == lotteryDate) {
            reward += player.value * 10;
        }
        
        if (playerNumber % 100 == lastTwoDigits) {
            reward += player.value * 1;
        }
        
        for(uint256 j = 0; j < 2; j++) {
            if (playerNumber % 1000 == lastThreeDigits[j]) {
                reward += player.value * 2;
            }
        }
        
        for(uint256 j = 0; j < 5; j++) {
            if (playerNumber == lotteryNumbers[j]) {
                reward += player.value * 5;
            }
        }
        
        // If the player has won, transfer the reward to the player's address
        if (reward > 0) {
            anyWinner = true;
            totalRewards += reward;
            // Update the player's value to reflect the reward
            players[i].value += reward;
            // Transfer the reward to the winner
            player.playerAddress.transfer(reward);
            // Record the winning ticket
            winningNumbers.push(playerNumber);

           emit RandomNumberGenerated(lotteryDate, lastTwoDigits, lastThreeDigits, lotteryNumbers);
           emit WinnerAnnounced(playerNumber, player.playerAddress, reward);
        }
    }

    // If no player has won, transfer all funds to the owner
    if (!anyWinner) {
        totalRewards = address(this).balance;

        emit RandomNumberGenerated(lotteryDate, lastTwoDigits, lastThreeDigits, lotteryNumbers);

    }

    // Transfer remaining funds to owner
    if (totalRewards > 0) {
           uint256 totalFunds = address(this).balance;
            require(totalFunds > 0, "No funds available for refund.");
            payable(owner).transfer(totalFunds);
    }

    // Clear the players array
    delete players;
    delete addRewardAddresses;
}



}