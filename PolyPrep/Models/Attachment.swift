import Foundation

struct Attachment: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let fileType: String
    let fileData: Data
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.id == rhs.id &&
        lhs.fileName == rhs.fileName &&
        lhs.fileType == rhs.fileType &&
        lhs.fileData == rhs.fileData
    }
}

enum AttachmentType: String, Codable {
    case image
    case audio
    case document
    case other
}
