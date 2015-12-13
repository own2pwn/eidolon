import Foundation
import RxSwift
import Moya
import Alamofire

enum ArtsyAPI {
    case XApp
    case XAuth(email: String, password: String)
    case TrustToken(number: String, auctionPIN: String)

    case SystemTime
    case Ping

    case Me
    
    case MyCreditCards
    case CreatePINForBidder(bidderID: String)
    case FindBidderRegistration(auctionID: String, phone: String)
    case RegisterToBid(auctionID: String)

    case Artwork(id: String)
    case Artist(id: String)

    case Auctions
    case AuctionListings(id: String, page: Int, pageSize: Int)
    case AuctionInfo(auctionID: String)
    case AuctionInfoForArtwork(auctionID: String, artworkID: String)
    case ActiveAuctions
    
    case MyBiddersForAuction(auctionID: String)
    case MyBidPositionsForAuctionArtwork(auctionID: String, artworkID: String)
    case MyBidPosition(id: String)
    case PlaceABid(auctionID: String, artworkID: String, maxBidCents: String)

    case UpdateMe(email: String, phone: String, postCode: String, name: String)
    case CreateUser(email: String, password: String, phone: String, postCode: String, name: String)

    case RegisterCard(stripeToken: String, swiped: Bool)

    case BidderDetailsNotification(auctionID: String, identifier: String)
    
    case LostPasswordNotification(email: String)
    case FindExistingEmailRegistration(email: String)
}

extension ArtsyAPI : MoyaTarget {
     var path: String {
        switch self {

        case .XApp:
            return "/api/v1/xapp_token"

        case .XAuth:
            return "/oauth2/access_token"

        case AuctionInfo(let id):
            return "/api/v1/sale/\(id)"
            
        case Auctions:
            return "/api/v1/sales"

        case AuctionListings(let id, _, _):
            return "/api/v1/sale/\(id)/sale_artworks"

        case AuctionInfoForArtwork(let auctionID, let artworkID):
            return "/api/v1/sale/\(auctionID)/sale_artwork/\(artworkID)"

        case SystemTime:
            return "/api/v1/system/time"

        case Ping:
            return "/api/v1/system/ping"

        case RegisterToBid:
            return "/api/v1/bidder"

        case MyCreditCards:
            return "/api/v1/me/credit_cards"

        case CreatePINForBidder(let bidderID):
            return "/api/v1/bidder/\(bidderID)/pin"

        case ActiveAuctions:
            return "/api/v1/sales"

        case Me:
            return "/api/v1/me"

        case UpdateMe:
            return "/api/v1/me"

        case CreateUser:
            return "/api/v1/user"

        case MyBiddersForAuction:
            return "/api/v1/me/bidders"

        case MyBidPositionsForAuctionArtwork:
            return "/api/v1/me/bidder_positions"

        case MyBidPosition(let id):
            return "/api/v1/me/bidder_position/\(id)"

        case Artwork(let id):
            return "/api/v1/artwork/\(id)"

        case Artist(let id):
            return "/api/v1/artist/\(id)"

        case FindBidderRegistration:
            return "/api/v1/bidder"
            
        case PlaceABid:
            return "/api/v1/me/bidder_position"

        case RegisterCard:
            return "/api/v1/me/credit_cards"

        case TrustToken:
            return "/api/v1/me/trust_token"

        case BidderDetailsNotification:
            return "/api/v1/bidder/bidding_details_notification"

        case LostPasswordNotification:
            return "/api/v1/users/send_reset_password_instructions"

        case FindExistingEmailRegistration:
            return "/api/v1/user"

        }
    }

    var base: String { return AppSetup.sharedState.useStaging ? "https://stagingapi.artsy.net" : "https://api.artsy.net" }
    var baseURL: NSURL { return NSURL(string: base)! }

    var parameters: [String: AnyObject]? {
        switch self {

        case XAuth(let email, let password):
            return [
                "client_id": APIKeys.sharedKeys.key ?? "",
                "client_secret": APIKeys.sharedKeys.secret ?? "",
                "email": email,
                "password":  password,
                "grant_type": "credentials"
            ]

        case XApp:
            return ["client_id": APIKeys.sharedKeys.key ?? "",
                "client_secret": APIKeys.sharedKeys.secret ?? ""]

        case Auctions:
            return ["is_auction": "true"]

        case RegisterToBid(let auctionID):
            return ["sale_id": auctionID]

        case MyBiddersForAuction(let auctionID):
            return ["sale_id": auctionID]

        case PlaceABid(let auctionID, let artworkID, let maxBidCents):
            return [
                "sale_id": auctionID,
                "artwork_id":  artworkID,
                "max_bid_amount_cents": maxBidCents
            ]

        case TrustToken(let number, let auctionID):
            return ["number": number, "auction_pin": auctionID]

        case CreateUser(let email, let password,let phone,let postCode, let name):
            return [
                "email": email, "password": password,
                "phone": phone, "name": name,
                "location": [ "postal_code": postCode ]
            ]

        case UpdateMe(let email, let phone,let postCode, let name):
            return [
                "email": email, "phone": phone,
                "name": name, "location": [ "postal_code": postCode ]
            ]

        case RegisterCard(let token, let swiped):
            return ["provider": "stripe", "token": token, "created_by_trusted_client": swiped]

        case FindBidderRegistration(let auctionID, let phone):
            return ["sale_id": auctionID, "number": phone]

        case BidderDetailsNotification(let auctionID, let identifier):
            return ["sale_id": auctionID, "identifier": identifier]

        case LostPasswordNotification(let email):
            return ["email": email]

        case FindExistingEmailRegistration(let email):
            return ["email": email]

        case AuctionListings(_, let page, let pageSize):
            return ["size": pageSize, "page": page]

        case ActiveAuctions:
            return ["is_auction": true, "live": true]

        case MyBidPositionsForAuctionArtwork(let auctionID, let artworkID):
            return ["sale_id": auctionID, "artwork_id": artworkID]
            
        default:
            return nil
        }
    }

    var method: Moya.Method {
        switch self {
        case .LostPasswordNotification,
             .CreateUser,
             .PlaceABid,
             .RegisterCard,
             .RegisterToBid,
             .CreatePINForBidder:
            return .POST
        case .FindExistingEmailRegistration:
            return .HEAD
        case .UpdateMe,
             .BidderDetailsNotification:
            return .PUT
        default:
            return .GET
        }
    }

    var sampleData: NSData {
        switch self {

        case XApp:
            return stubbedResponse("XApp")

        case XAuth:
            return stubbedResponse("XAuth")

        case TrustToken:
            return stubbedResponse("XAuth")

        case Auctions:
            return stubbedResponse("Auctions")

        case AuctionListings:
            return stubbedResponse("AuctionListings")
            
        case SystemTime:
            return stubbedResponse("SystemTime")

        case CreatePINForBidder:
            return stubbedResponse("CreatePINForBidder")

        case ActiveAuctions:
            return stubbedResponse("ActiveAuctions")

        case MyCreditCards:
            return stubbedResponse("MyCreditCards")

        case RegisterToBid:
            return stubbedResponse("RegisterToBid")

        case MyBiddersForAuction:
            return stubbedResponse("MyBiddersForAuction")

        case Me:
            return stubbedResponse("Me")

        case UpdateMe:
            return stubbedResponse("Me")

        case CreateUser:
            return stubbedResponse("Me")
            
        // This API returns a 302, so stubbed response isn't valid
        case FindBidderRegistration:
            return stubbedResponse("Me")

        case PlaceABid:
            return stubbedResponse("CreateABid")

        case Artwork:
            return stubbedResponse("Artwork")

        case Artist:
            return stubbedResponse("Artist")

        case AuctionInfo:
            return stubbedResponse("AuctionInfo")

        case RegisterCard:
            return stubbedResponse("RegisterCard")

        case BidderDetailsNotification:
            return stubbedResponse("RegisterToBid")

        case LostPasswordNotification:
            return stubbedResponse("ForgotPassword")

        case FindExistingEmailRegistration:
            return stubbedResponse("ForgotPassword")

        case AuctionInfoForArtwork:
            return stubbedResponse("AuctionInfoForArtwork")

        case MyBidPositionsForAuctionArtwork:
            return stubbedResponse("MyBidPositionsForAuctionArtwork")
            
        case MyBidPosition:
            return stubbedResponse("MyBidPosition")

        case Ping:
            return stubbedResponse("Ping")

        }
    }
}

// Custom stuff
extension ArtsyAPI {
    var requiresAuthorization: Bool {
        switch self {
        case .MyCreditCards: fallthrough
        case .CreatePINForBidder: fallthrough
        case .FindBidderRegistration: fallthrough
        case .RegisterToBid: fallthrough
        case .MyBiddersForAuction: fallthrough
        case .MyBidPositionsForAuctionArtwork: fallthrough
        case .MyBidPosition: fallthrough
        case .PlaceABid: fallthrough
        case .UpdateMe: fallthrough
        case .RegisterCard: fallthrough
        case .Me: return true

        default: return false
        }
    }
}

// MARK: - Provider support

func stubbedResponse(filename: String) -> NSData! {
    @objc class TestClass: NSObject { }
    
    let bundle = NSBundle(forClass: TestClass.self)
    let path = bundle.pathForResource(filename, ofType: "json")
    return NSData(contentsOfFile: path!)
}

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}
