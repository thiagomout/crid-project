import pytest
from brownie import CRIDAcademico, accounts

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