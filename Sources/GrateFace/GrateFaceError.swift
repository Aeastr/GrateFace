import Foundation

/// Errors from validating a Photos face template and writing its replacement artwork.
public enum GrateFaceError: LocalizedError {
    case invalidTemplate(String)
    case unsupportedTemplate(String)
    case invalidImage(String)
    case outputAlreadyExists
    case outputMatchesTemplate

    public var errorDescription: String? {
        switch self {
        case .invalidTemplate(let detail): "The selected watch face is invalid: \(detail)"
        case .unsupportedTemplate(let detail): "This Photos face is not supported: \(detail)"
        case .invalidImage(let detail): "The artwork could not be prepared: \(detail)"
        case .outputAlreadyExists: "A face already exists at the output location. Choose another file name."
        case .outputMatchesTemplate: "Choose an output file different from the template."
        }
    }
}
