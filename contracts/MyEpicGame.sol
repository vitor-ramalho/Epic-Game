// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/Base64.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "hardhat/console.sol";

contract MyEpicGame is ERC721 {
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    //TokenID do NFT
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;


    //mapping do token do NFT => Que contem os atributos do mesmo NFT - Ele é armazenado na variável puclia nftHolderAttributes;
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    //Definindo Estrutura do Chefão
    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;                
    }

    BigBoss public bigBoss;

    // mapping do address => que contém o ID dos NFTs daquele endereço - O objetivo é armazenar na variável nftHolders o dono do NFT e as referencias
    mapping(address => uint256) public nftHolders;
    
    //Inicializa as variáveis de estado do smart contract
    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackDmg,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage
         //identificador especial para o NFT.
        // onome e simbolo token, ex Ethereum and ETH.
    )
    ERC721("Memes", "MEME")
    {
        //inicializar estrutura do chefão
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

        // loop passando por todos os personagens e salvando os valores no contrato para usá-los depois. 
        for(uint i = 0; i < characterNames.length; i += 1){
            defaultCharacters.push(CharacterAttributes({
                characterIndex: i,
                name: characterNames[i],
                imageURI: characterImageURIs[i],
                hp: characterHp[i],
                maxHp: characterHp[i],
                attackDamage: characterAttackDmg[i]
            }));

            CharacterAttributes memory c = defaultCharacters[i];
            console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
        }
        // incremento para que o id do primeiro NFT seja 1.
        _tokenIds.increment();
    }

    function mintCharacterNFT(uint _characterIndex) external {
        // Pega o atual tokenId.
        uint newItemId = _tokenIds.current();

        // Assina o ID do token na carteira cadastrada.
        _safeMint(msg.sender, newItemId);

        // map tokenId => atributos do personagem. 
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
                
        });

        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);

        nftHolders[msg.sender] = newItemId;

        _tokenIds.increment();

        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        charAttributes.name,
                        ' -- NFT #: ',
                        Strings.toString(_tokenId),
                        '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "',
                        charAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
                        strAttackDamage,'} ]}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        // armazena o estado do NFT do usuario
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

        // valida se o personagem tem mais de 0 HP
        require (
            player.hp > 0,
            "Error: character must have HP to attack boss."
        );

        // valida se o chefe tem mais de 0 HP.
        require (
            bigBoss.hp > 0,
            "Error: boss must have HP to attack boss."
        );

        // permite o jogador atackar o chefe
        if(bigBoss.hp < player.attackDamage){
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }
        // permite o chefe atacar o jogador
        if(player.hp < bigBoss.attackDamage){
            player.hp = 0;
        } else{
            player.hp = player.hp - bigBoss.attackDamage;
        }

        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        emit AttackComplete(bigBoss.hp, player.hp);
    }

    //verifica se o usuario tem algum NFT
    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        uint256 userNftTokenId = nftHolders[msg.sender];

        if(userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        } else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    //Busca todos os personagens padrão
    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory){
        return defaultCharacters;
    }

    // retorna o Chefe
    function getBigBoss() public view returns (BigBoss memory){
        return bigBoss;
    }
}