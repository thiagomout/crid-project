// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importa os contratos prontos do OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title CRIDAcademico
 * @dev Contrato que representa um CRID da UFRJ como um NFT (ERC-721).
 * Apenas o dono do contrato (a Universidade) pode emitir novos CRIDs.
 */
contract CRIDAcademico is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    // Um contador para gerar IDs únicos para cada CRID (1, 2, 3...)
    Counters.Counter private _tokenIds;

    event CRIDEmitido(uint256 indexed cridId, address indexed aluno, string metadataURI);

    constructor() ERC721("CRID UFRJ", "CRIDUFRJ") {}

    /**
     * @dev Emite um novo CRID (NFT) para um aluno.
     * @param aluno Endereço da carteira do aluno.
     * @param metadataURI Link para o arquivo JSON com os dados do CRID (ex: em IPFS).
     */
    function emitirCRID(address aluno, string memory metadataURI)
        public
        onlyOwner // Modificador que garante que só o dono do contrato pode chamar
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 novoCRIDId = _tokenIds.current();

        _safeMint(aluno, novoCRIDId);
        _setTokenURI(novoCRIDId, metadataURI);

        emit CRIDEmitido(novoCRIDId, aluno, metadataURI);
        // Retorna o ID do novo CRID emitido

        return novoCRIDId;
    }
}