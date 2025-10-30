package main

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/go-jose/go-jose/v4"
	"github.com/go-jose/go-jose/v4/jwt"
)

// go run . -jwks ../.k3d/certs/jwks.json -jwt-claims ../jwt1.json -key ../.k3d/certs/sa.key
func main() {

	var jwksPath = "jwks.json"
	var keyPath = "key.pem"
	var jwtClaimsPath = "jwt.json"

	flag.StringVar(&jwksPath, "jwks", jwksPath, "path to JWKS file. Note: considerering only the first key!")
	flag.StringVar(&keyPath, "key", keyPath, "path to private key file")
	flag.StringVar(&jwtClaimsPath, "jwt-claims", jwtClaimsPath, "path to claims file")
	flag.Parse()

	fmt.Printf("Using JWKS file: %s\n", jwksPath)
	data, err := os.ReadFile(jwksPath)
	if err != nil {
		fmt.Printf("failed to read %s: %v\n", jwksPath, err)
		return
	}

	var jwks jose.JSONWebKeySet
	if err := json.Unmarshal(data, &jwks); err != nil {
		fmt.Printf("failed to unmarshal %s: %v\n", jwksPath, err)
		return
	}

	if len(jwks.Keys) == 0 {
		fmt.Printf("no keys found in %s\n", jwksPath)
		return
	}

	key := jwks.Keys[0].Public()
	fmt.Printf("Using key with kid=%s alg=%s use=%s\n", key.KeyID, key.Algorithm, key.Use)

	claims, err := readClaimsFromFileAndUpdateDates(jwtClaimsPath)
	if err != nil {
		fmt.Printf("failed to read %s: %v\n", jwtClaimsPath, err)
		return
	}
	updateClaimDates(claims)

	pretty, _ := json.MarshalIndent(claims, "", "  ")
	fmt.Printf("JWT claims: %s\n", string(pretty))

	fmt.Printf("Using private key file: %s\n", keyPath)
	privateKey, err := loadPrivateKey(keyPath)
	if err != nil {
		fmt.Printf("failed to load private key: %v\n", err)
		return
	}

	signer, err := jose.NewSigner(jose.SigningKey{Algorithm: jose.SignatureAlgorithm(key.Algorithm), Key: privateKey}, (&jose.SignerOptions{}).WithHeader("kid", key.KeyID))
	if err != nil {
		fmt.Printf("failed to create signer: %v\n", err)
		return
	}

	rawJwt, err := jwt.Signed(signer).Claims(claims).Serialize()
	if err != nil {
		fmt.Printf("failed to sign JWT: %v\n", err)
		return
	}

	fmt.Printf("Generated JWT:\n====\n%s\n====\n", rawJwt)
}

func updateClaimDates(claims map[string]interface{}) {
	t := time.Now().UTC()
	ff := jwt.NewNumericDate(t)
	claims["iat"] = ff
	claims["nbf"] = ff
	claims["exp"] = jwt.NewNumericDate(t.Add(24 * time.Hour))
}

func readClaimsFromFileAndUpdateDates(jwtClaimsPath string) (map[string]interface{}, error) {
	fmt.Printf("Reading JWT claims file: %s\n", jwtClaimsPath)
	jwtClaimsData, err := os.ReadFile(jwtClaimsPath)
	if err != nil {
		fmt.Println("failed to read", jwtClaimsPath+":", err)
		return nil, err
	}

	var claims map[string]interface{}
	if err := json.Unmarshal(jwtClaimsData, &claims); err != nil {
		fmt.Printf("failed to unmarshal %s: %v\n", jwtClaimsPath, err)
		return nil, err
	}

	return claims, nil
}

func loadPrivateKey(keyPath string) (interface{}, error) {
	keyData, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read private key file: %w", err)
	}
	block, _ := pem.Decode(keyData)
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM data: %w", err)
	}
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse RSA key: %w", err)
	}
	if key, ok := key.(*rsa.PrivateKey); ok {
		return key, nil
	}

	return nil, fmt.Errorf("key is not of type *rsa.PrivateKey")
}
