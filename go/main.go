package main

import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/rs/zerolog/log"

	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"strings"

	"github.com/machinebox/graphql"

	"github.com/btcsuite/btcd/btcec/v2"
)

// HexToECDSAPrivateKey converts a hexadecimal string representing a private key
// into an *ecdsa.PrivateKey for the secp256k1 curve.
func HexToECDSAPrivateKey(hexKey string) (*ecdsa.PrivateKey, error) {
	trimmedHexKey := strings.TrimPrefix(hexKey, "0x")

	privKeyBytes, err := hex.DecodeString(trimmedHexKey)
	if err != nil {
		return nil, fmt.Errorf("failed to decode hex string: %v", err)
	}

	privKey, _ := btcec.PrivKeyFromBytes(privKeyBytes)

	return privKey.ToECDSA(), nil
}

// SignMessage signs a message using the given ECDSA private key.
func SignMessageAsBase64(privKey *ecdsa.PrivateKey, message []byte) string {
	hash := sha256.Sum256(message)

	signature, err := ecdsa.SignASN1(rand.Reader, privKey, hash[:])
	if err != nil {
		log.Fatal().Msgf("failed to sign message: %v", err)
	}

	signatureB64 := base64.StdEncoding.EncodeToString(signature)

	return signatureB64
}

func main() {
	privateKey, err := HexToECDSAPrivateKey("GANDAL_PRIVATE_KEY")
	if err != nil {
		log.Fatal().Msgf("failed to parse private key: %v", err)
	}

	req := graphql.NewRequest(`
	query getActivity($dataKey: String!, $source: Source!, $limit: Int64!, $page: Int64!) {
		getActivity(dataKey: $dataKey, source: $source, limit: $limit, page: $page) {
		  data {
			id
			metadata {
			  ...NetflixActivityMetadata
			}
		  }
		  limit
		  page
		  total
		}
	  }
	  fragment NetflixActivityMetadata on NetflixActivityMetadata {
		title
		subject {
		  value
		  identifierType
		}
		date
	  }
    `)

	req.Var("dataKey", "dataKey")
	req.Var("source", "NETFLIX")
	req.Var("limit", 10)
	req.Var("page", 1)

	requestBodyObj := struct {
		Query     string                 `json:"query"`
		Variables map[string]interface{} `json:"variables"`
	}{
		Query:     req.Query(),
		Variables: req.Vars(),
	}

	var requestBody bytes.Buffer
	if err := json.NewEncoder(&requestBody).Encode(requestBodyObj); err != nil {
		log.Fatal().Msgf("encode body: %v", err)
	}

	signatureB64 := SignMessageAsBase64(privateKey, requestBody.Bytes())
	req.Header.Set("X-Gandalf-Signature", signatureB64)

}
