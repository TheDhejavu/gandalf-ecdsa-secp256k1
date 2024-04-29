import base64
import hashlib
import json
import ecdsa
from ecdsa import SigningKey, VerifyingKey, SECP256k1, BadSignatureError
from graphqlclient import GraphQLClient

# Rest of your code remains unchanged
def sign_message_as_base64(private_key_hex, message):
    sk = SigningKey.from_string(bytes.fromhex(private_key_hex), curve=SECP256k1)
    message_hash = hashlib.sha256(message).digest()
    signature_der = sk.sign_digest(message_hash, sigencode=ecdsa.util.sigencode_der)

    # Encode the signature in base64
    signature_base64 = base64.b64encode(signature_der).decode()
    return signature_base64

def verify_signature(public_key_hex, message, signature_base64):
    vk = VerifyingKey.from_string(bytes.fromhex(public_key_hex), curve=SECP256k1)
    message_hash = hashlib.sha256(message.encode()).digest()
    signature_der = base64.b64decode(signature_base64)
    try:
        vk.verify_digest(signature_der, message_hash, sigdecode=ecdsa.util.sigdecode_der)
        return True
    except BadSignatureError:
        return False
  
def serialize_for_signature(data):
    return json.dumps(data, separators=(',', ':'), sort_keys=True)

def main():
    private_key_hex = "366a5ae7c7575f8cb0e3832ad53e668061e0ad800b94ffb75fd5b6d241a83e56"
    
    query = """
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
    """

    variables = {
        "dataKey": "BG7u85FMLGnYnUv2ZsFTAXrGT2Xw3TikrBHm2kYz31qq",
        "source": "NETFLIX",
        "limit": 10,
        "page": 1
    }

    request_body = {
        'query': query,
        'variables': variables
    }

    signature_b64 = sign_message_as_base64(private_key_hex, json.dumps(request_body).encode('utf-8'))
    print("Request Body:", request_body)
    print("X-Gandalf-Signature:", signature_b64)
   
    client = GraphQLClient("http://localhost:1000/public/gql")
    client.inject_token(signature_b64,'X-Gandalf-Signature')

    result = client.execute(query, variables)

if __name__ == "__main__":
  main()

