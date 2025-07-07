import pytest
from brownie import CRIDAcademico, accounts, exceptions
from web3.exceptions import BadResponseFormat

@pytest.fixture
def crid_contract():
    # A conta 0 é a "Universidade"
    return CRIDAcademico.deploy({"from": accounts[0]})

def test_emissao_sucesso(crid_contract):

    # Define os participantes do teste
    universidade = accounts[0]
    aluno = accounts[1]
    METADATA_URI = "ipfs://QmT...ExampleHash"

    tx = crid_contract.emitirCRID(aluno, METADATA_URI, {"from": universidade})
    
    emitted_token_id = tx.return_value

    assert crid_contract.ownerOf(emitted_token_id) == aluno
    assert crid_contract.balanceOf(aluno) == 1
    assert "CRIDEmitido" in tx.events
    assert tx.events["CRIDEmitido"]["aluno"] == aluno
    assert tx.events["CRIDEmitido"]["cridId"] == emitted_token_id
    assert tx.events["CRIDEmitido"]["metadataURI"] == METADATA_URI

def test_emissao_falha_nao_autorizada(crid_contract):

    # Define os participantes
    aluno_malicioso = accounts[1]
    outro_aluno = accounts[2]
    
    with pytest.raises(Exception, match="Ownable: caller is not the owner"):
        crid_contract.emitirCRID(outro_aluno, "fake_uri", {"from": aluno_malicioso})

def test_revoke_crid_sucesso(crid_contract):

    # Define os participantes
    universidade = accounts[0]
    aluno = accounts[1]
    METADATA_URI = "ipfs://QmT...ExampleHash"

    # Emite um CRID primeiro
    tx = crid_contract.emitirCRID(aluno, METADATA_URI, {"from": universidade})
    emitted_token_id = tx.return_value

    # Revoga o CRID
    revoke_tx = crid_contract.revokeCRID(emitted_token_id, {"from": universidade})

    assert crid_contract.isRevoked(emitted_token_id) is True
    assert "CRIDRevogado" in revoke_tx.events
    assert revoke_tx.events["CRIDRevogado"]["tokenId"] == emitted_token_id

def test_revoke_crid_falha_nao_autorizada(crid_contract):
    # Define os participantes
    aluno = accounts[1]
    METADATA_URI = "ipfs://QmT...ExampleHash"

    # Emite um CRID primeiro
    tx = crid_contract.emitirCRID(aluno, METADATA_URI, {"from": accounts[0]})
    emitted_token_id = tx.return_value

    with pytest.raises(BadResponseFormat):
        crid_contract.revokeCRID(emitted_token_id, {"from": aluno})

def test_transferir_crid_revogado_falha(crid_contract):
    # Define os participantes
    universidade = accounts[0]
    aluno = accounts[1]
    comprador = accounts[2]

    tx_emissao = crid_contract.emitirCRID(aluno, "uri", {"from": universidade})
    token_id = tx_emissao.return_value

    # Revoga o token
    crid_contract.revokeCRID(token_id, {"from": universidade})

    # O aluno tenta transferir seu token revogado
    with pytest.raises(BadResponseFormat):
        crid_contract.safeTransferFrom(aluno, comprador, token_id, {"from": aluno})