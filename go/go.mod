module gandalf-ecdsa-secp256k1

go 1.22.1

require (
	github.com/btcsuite/btcd/btcec/v2 v2.3.3
	github.com/machinebox/graphql v0.2.2
	github.com/rs/zerolog v1.32.0
)

require (
	github.com/decred/dcrd/dcrec/secp256k1/v4 v4.0.1 // indirect
	github.com/matryer/is v1.4.1 // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.19 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	golang.org/x/sys v0.12.0 // indirect
)

replace github.com/machinebox/graphql => github.com/machinebox/graphql v0.2.3-0.20181106130121-3a9253180225
