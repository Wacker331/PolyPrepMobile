import Foundation

struct KeycloakTokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
    let token_type: String
}

struct KeycloakUserInfo: Codable {
    let sub: String
    let email_verified: Bool
    let name: String
    let preferred_username: String
    let given_name: String
    let family_name: String
    let email: String
}

struct KeycloakError: Codable {
    let error: String
    let error_description: String
}
