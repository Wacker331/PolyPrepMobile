import Foundation

struct Attachment: Identifiable, Equatable {
    var id: Int = Int()
    let fileName: String
//    let fileLink: String
    let fileType: String
    let fileData: Data
    
    init(id: Int? = -1, filename: String, filedata: Data)
    {
        self.id = id ?? -1
        self.fileName = filename
        self.fileType = Attachment.defineType(name: filename)
        self.fileData = filedata
    }
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.id == rhs.id &&
        lhs.fileName == rhs.fileName &&
        lhs.fileType == rhs.fileType &&
        lhs.fileData == rhs.fileData
    }
    
    static func defineType(name: String) -> String
    {
        let parts = name.components(separatedBy: ".")
        switch parts[parts.count - 1].lowercased()
        {
        case "pdf":
            return "application/pdf"
        case "jpg", "jpeg", "png":
            return "image/jpeg"
        case "mp3", "wav":
            return "audio/mpeg"
        default:
            return "other"
        }
    }
}

enum AttachmentType: String, Codable {
    case image
    case audio
    case document
    case other
}
