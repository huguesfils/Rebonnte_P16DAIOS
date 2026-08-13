import Foundation
import FirebaseFirestore

enum FirestoreErrorMapper {
    static func map(_ error: Error) -> MediStockError {
        if let mediStockError = error as? MediStockError {
            return mediStockError
        }

        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain,
              let code = FirestoreErrorCode.Code(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }

        switch code {
        case .unavailable, .deadlineExceeded:
            return .networkUnavailable
        case .notFound:
            return .medicineNotFound
        case .permissionDenied, .unauthenticated:
            return .permissionDenied
        case .invalidArgument, .dataLoss:
            return .invalidData
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
