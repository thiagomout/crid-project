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

    mapping(uint256 => bool) private _revokedTokens; // Mapeia IDs de CRIDs revogados

    event CRIDRevogado(uint256 indexed tokenId);
    // Evento que será emitido quando um CRID for emitido

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
    /**
     * @dev Revoga um CRID, tornando-o inválido para transferência.
     * @param tokenId ID do CRID a ser revogado.
     */

    function revokeCRID(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "CRID nao existe.");
        require(!_revokedTokens[tokenId], "CRID ja foi revogado.");

        _revokedTokens[tokenId] = true;
        emit CRIDRevogado(tokenId);
    }
    /**
     * @dev Verifica se um CRID foi revogado.
     * @param tokenId ID do CRID a ser verificado.
     * @return true se o CRID foi revogado, false caso contrário.
     */
    function isRevoked(uint256 tokenId) public view returns (bool) {
        return _revokedTokens[tokenId];
    }
    /**
     * @dev Sobrescreve a função _beforeTokenTransfer do ERC721 para impedir a transferência de CRIDs revogados.
     * @param from Endereço do remetente (quem está transferindo o token).
     * @param to Endereço do destinatário (quem está recebendo o token).
     * @param tokenId ID do token que está sendo transferido.
     * @param batchSize Tamanho do lote de tokens (não usado aqui, mas necessário para compatibilidade).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Impede a transferência se o token estiver na lista de revogados
        require(!isRevoked(tokenId), "CRID foi revogado e nao pode ser transferido.");
    }
}