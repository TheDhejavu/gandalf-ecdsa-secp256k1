import base64
import hashlib
import json
import ecdsa
from ecdsa import SigningKey, VerifyingKey, SECP256k1, BadSignatureError
from graphqlclient import GraphQLClient


# Step 1: Prepare the signature
def prepare_signature(private_key_hex, message):
    sk = SigningKey.from_string(bytes.fromhex(private_key_hex), curve=SECP256k1)
    message_hash = hashlib.sha256(message).digest()
    signature_der = sk.sign_digest(message_hash, sigencode=ecdsa.util.sigencode_der)

    # Encode the signature in base64
    signature_base64 = encode_signature(signature_der)
    return signature_base64

# Step 2: Encode the signature
def encode_signature(signature):
    return base64.b64encode(signature).decode('utf-8')

def verify_signature(public_key_hex, message, signature_base64):
    vk = VerifyingKey.from_string(bytes.fromhex(public_key_hex), curve=SECP256k1)
    message_hash = hashlib.sha256(message.encode()).digest()
    signature_der = base64.b64decode(signature_base64)
    try:
        vk.verify_digest(signature_der, message_hash, sigdecode=ecdsa.util.sigdecode_der)
        return True
    except BadSignatureError:
        return False

def main():
    private_key_hex = "GANDALF_PRIVATE_KEY"
    query = """
    query getActivity($dataKey: String!, $source: Source!, $limit: Int, $page: Int) {
        getActivity(dataKey: $dataKey, source: $source, limit: $limit, page: $page) {
            # ... specify the fields you want to get back
        }
    }
    """

    variables = {
        "dataKey": "YOUR_DATA_KEY",
        "source": "YOUR_SOURCE",
        "limit": 10,
        "page": 1
    }

    request_body = {
        'query': query,
        'variables': variables
    }

    signature_b64 = prepare_signature(private_key_hex, json.dumps(request_body).encode('utf-8'))
    client = GraphQLClient("https://sauron.gandalf.network/public/gql")

    # Step 3: Add signature header
    client.inject_token(signature_b64,'X-Gandalf-Signature')

    result = client.execute(query, variables)
    print(result)

if __name__ == "__main__":
  main()

