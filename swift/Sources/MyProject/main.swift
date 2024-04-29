import Foundation
import secp256k1

let privateKeyHex = "GANDALF_PRIVATE_KEY"

extension Data {
    init?(hexString: String) {
        self.init()
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if nextIndex > hexString.endIndex { break }
            let range = index..<nextIndex
            if let byte = UInt8(hexString[range], radix: 16) {
                self.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
    }
    
    func toHexString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}

func signMessage(privateKeyHex: String, message: String) -> String? {
    guard let privateBytes = Data(hexString: privateKeyHex) else {
        print("Invalid private key hex.")
        return nil
    }

    do {
        let privateKey = try secp256k1.Signing.PrivateKey(dataRepresentation: privateBytes)
        let messageData = message.data(using: .utf8)!
        let signature = try privateKey.signature(for: messageData)
        let derSignature = try signature.derRepresentation
        return Data(derSignature).base64EncodedString()
    } catch {
        print("Error signing message: \(error)")
        return nil
    }
}

func verifySignature(publicKeyHex: String, message: String, signatureBase64: String) -> Bool {
    guard let publicKeyBytes = Data(hexString: publicKeyHex),
        let signatureDER = Data(base64Encoded: signatureBase64),
        let messageData = message.data(using: .utf8) else {
        print("Invalid input.")
        return false
    }
    
    do {
        let publicKey = try secp256k1.Signing.PublicKey(dataRepresentation: publicKeyBytes, format: .compressed)
        let signature = try secp256k1.Signing.ECDSASignature(derRepresentation: signatureDER)
        return publicKey.isValidSignature(signature, for: messageData)
    } catch {
        print("Error verifying signature: \(error)")
        return false
    }
}


struct GraphQLRequest: Codable {
    let query: String
    let variables: ActivityRequestVariables
}

struct ActivityRequestVariables: Codable {
    let dataKey: String
    let source: String
    let limit: Int64
    let page: Int64
}


func getActivity(dataKey: String, source: String, limit: Int64, page: Int64) {
    let variables = ActivityRequestVariables(dataKey: dataKey, source: source, limit: limit, page: page)
    let queryString = """
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

    let graphQLRequest = GraphQLRequest(query: queryString, variables: variables)
    
    let semaphore = DispatchSemaphore(value: 0)
    do {
        let jsonData = try JSONEncoder().encode(graphQLRequest)
        let jsonString = String(data: jsonData, encoding: .utf8)
       
        guard let signatureBase64 = signMessage(privateKeyHex: privateKeyHex, message: jsonString ?? "") else {
            print("Failed to generate signature")
            return
        }

        print("Signature in Base64:", signatureBase64)
        let verificationResult = verifySignature(publicKeyHex: publicKeyHex, message: message, signatureBase64: signatureBase64)
        print("Verification Result:", verificationResult)

            
        let url = URL(string: "http://localhost:1000/public/gql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(signatureBase64, forHTTPHeaderField: "X-Gandalf-Signature")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP response received.")
                return
            }

            if httpResponse.statusCode != 200 {
                print("HTTP Response: \(httpResponse)")
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")

                if let data = data, let bodyString = String(data: data, encoding: .utf8) {
                    print("Response Body: \(bodyString)")
                }
                return
            }

            guard let data = data else {
                print("No data received.")
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                print("Response: \(jsonResponse)")
            } catch {
                print("Error parsing the JSON response: \(error)")
            }
        }
        task.resume()
        semaphore.wait() 
    } catch {
        print("Error encoding the request body: \(error)")
    }
}

// Example usage
getActivity(dataKey: "BG7u85FMLGnYnUv2ZsFTAXrGT2Xw3TikrBHm2kYz31qq", source: "NETFLIX", limit: 10, page: 1)
