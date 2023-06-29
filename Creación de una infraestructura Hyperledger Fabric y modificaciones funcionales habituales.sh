
*** INSTALAR RED UNIVERSITARIA **


***** Borrar instalaciones previas
**Llamar la red anterior y darle de baja
cd ~/fabric-samples/test-network
    ./network.sh down

**Para regresar a ruta origen para instalar**
cd 
git clone https://gitlab.com/STorres17/soluciones-blockchain.git

cd ~/soluciones-blockchain/universidades

****Sirtve para editar Json**
sudo apt install jq

**Eliminar todo para empezar y que no haya sesgos

***parar todos los dockers que haya en el servidor**
docker stop $(docker ps -a -q)

**Eliminar todos los dockers que haya en el servidor**
docker rm $(docker ps -a -q)

*** Borrar todos los volumenes previos en el equipo***
docker volume prune
***Borrar todas las network previas y todas las certificaciones previas en el servidor**
docker network prune

** Eliminar los certificados de los peer y de los orderes / configuracion de los canales para crear canales con el orderer - luego crea carpeta para dar la configuracion***
rm -rf organizations/peerOrganizations
rm -rf organizations/ordererOrganizations
rm -rf channel-artifacts/
mkdir channel-artifacts


*** Exportacion de los binarios
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
**para revisar**
ls ../bin/

****PRIMERO SE CREAR LOS CA para cada una de las universidades *****

**Crear certificados para cada una de las organizaciones/universidades //AQUI CAMBIAR NOMBRES
cryptogen generate --config=./organizations/cryptogen/crypto-config-madrid.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-bogota.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"


**** Para ver los certificados de los nodos pares***
ls organizations
ls organizations/ordererOrganizations/
ls organizations/ordererOranizations/universidades.com/
ls organizations/ordererOranizations/universidades.com/orderers/


docker-compose -f docker/docker-compose-universidades.yaml up -d

**ya tenemos arracanda la red con 1 orderer, 2 orgs y 2 couchdbs
**habrá que crear los canales

***** LUEGO SE CREA LA CONFIGURACIÓN DEL CANAL CANAL SOBRE EL CUAL SE VAN A COMUNICAR****

**Exportar carpeta llamada configtx = donde esta toda la configuracion MSP de las empresas y configuracion de canales que se pueden crear en al Red***
export FABRIC_CFG_PATH=${PWD}/configtx

**para saber como es esa configuracion, vamos al arhcivo: configtx.yaml --
    vi configtx/configtx.yaml
    :q ***para salir***


*** TERCERO, SE GENERA UN BLOQUE GENESIS DEL CANAL CON LOS CA DE LAS UNIVERSIDADES****

***Generar el bloque genesis del canal EN LA CARPETA Channel-Artifcats***
    configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel
    ***Para verificiar la creacion:
        ls channel-artifacts/

***Luego de haber creado el genensis, se cambiar el canal de la carpeta  config tx -> config
export FABRIC_CFG_PATH=${PWD}/../config

*****CUARTO CONVERTIRSE EN ADMIN DEL ORDERER Y CREAR CANAL DESDE EL ORDERER****

***Exportar variables que convierten en Admin del orderer**
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key

*** Crear canal en el orderer = esta pasando bloque genesis con todos los CA creados // Esta es una herramienta que permite administrar el orderer **
osnadmin channel join --channelID universidadeschannel --config-block ./channel-artifacts/universidadeschannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

***Revisar los canales creados***
osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"


****QUINTO, ADHERIR A LOS NODOS A EL CANAL 

**EXPORTA LOS CERTIFICADOS QUE ACREDITAN COMO LA UNIVERISDAD DE MADRID
export CORE_PEER_TLS_ENABLED=true
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MADRID_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051

*** Envia la configuracion del bloque al nodo de madrid para adehirrlo al canal*
peer channel join -b ./channel-artifacts/universidadeschannel.block

*EXPORTA LOS CERTIFICADOS QUE ACREDITAN COMO UNIVERSIDAD BOGOTA
export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BOGOTA_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051

***Enviar configuracion del bloque genesis al nodo de bogota para adicionarlo al canal***
peer channel join -b ./channel-artifacts/universidadeschannel.block

**** REVISAR DOCKERS Y SUS LOGS
docker ps
*indica si hay algun docker que esta parado**
docker ps -a

**Revisar los logs***
docker logs -f peer0.madrid.universidades.com



************ ADICIÓN DE UNA ORGANIZACIÓN A LA RED UNIVERSITARIA *******

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config


cryptogen generate --config=./organizations/cryptogen/crypto-config-berlin.yaml --output="organizations"

cd berlin/
export FABRIC_CFG_PATH=$PWD
../../bin/configtxgen -printOrg BerlinMSP > ../organizations/peerOrganizations/berlin.universidades.com/berlin.json

cd ..
docker-compose -f docker/docker-compose-berlin.yaml up -d

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
export CORE_PEER_TLS_ENABLED=true
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MADRID_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel fetch config channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com -c universidadeschannel --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq .data.data[0].payload.data.config config_block.json > config.json

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"BerlinMSP":.[1]}}}}}' config.json ../organizations/peerOrganizations/berlin.universidades.com/berlin.json > modified_config.json
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id universidadeschannel --original config.pb --updated modified_config.pb --output berlin_update.pb
configtxlator proto_decode --input berlin_update.pb --type common.ConfigUpdate --output berlin_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'universidadeschannel'", "type":2}},"data":{"config_update":'$(cat berlin_update.json)'}}}' | jq . > berlin_update_in_envelope.json
configtxlator proto_encode --input berlin_update_in_envelope.json --type common.Envelope --output berlin_update_in_envelope.pb

cd ..
peer channel signconfigtx -f channel-artifacts/berlin_update_in_envelope.pb

export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BOGOTA_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel update -f channel-artifacts/berlin_update_in_envelope.pb -c universidadeschannel -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem

export PEER0_BERLIN_CA=${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BerlinMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BERLIN_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:2051
peer channel fetch 0 channel-artifacts/universidadeschannel.block -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com -c universidadeschannel --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
peer channel join -b channel-artifacts/universidadeschannel.block


************** Administración y configuración de un canal de Hyperledger Fabric ***********
--> Revisar configtx.yaml 
--> Extraer info de un canal 
--> https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/peerchannel.html
--> https://hyperledger-fabric.readthedocs.io/en/release-2.3/commands/osnadminchannel.html


************ Creación de certificados en base a la configuración de la red **************
*** De cryptogen a la CA

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker volume prune
docker network prune

rm -rf organizations/peerOrganizations
rm -rf organizations/ordererOrganizations
sudo rm -rf organizations/fabric-ca/madrid/
sudo rm -rf organizations/fabric-ca/bogota/
sudo rm -rf organizations/fabric-ca/ordererOrg/
rm -rf channel-artifacts/
mkdir channel-artifacts

docker-compose -f docker/docker-compose-ca.yaml up -d

. ./organizations/fabric-ca/registerEnroll.sh && createMadrid
. ./organizations/fabric-ca/registerEnroll.sh && createBogota
. ./organizations/fabric-ca/registerEnroll.sh && createOrderer

docker-compose -f docker/docker-compose-universidades.yaml up -d

export FABRIC_CFG_PATH=${PWD}/configtx
configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel
export FABRIC_CFG_PATH=${PWD}/../config
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key

osnadmin channel join --channelID universidadeschannel --config-block ./channel-artifacts/universidadeschannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

export CORE_PEER_TLS_ENABLED=true
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MADRID_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel join -b ./channel-artifacts/universidadeschannel.block

export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BOGOTA_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel join -b ./channel-artifacts/universidadeschannel.block


********** Administración de una Autoridad Certificadora (CA) *********
--> Leer despliegue de la CA
--> Opcionales al despliegue
--> Logs de CA
--> HSM en CA 
https://hyperledger-fabric-ca.readthedocs.io/en/v1.5.2/