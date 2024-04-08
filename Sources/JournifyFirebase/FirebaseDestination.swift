//
//  FirebaseDestination.swift
//
//

import Foundation
import Journify
import Firebase
import FirebaseAnalytics

/**
 An implmentation of the Firebase Analytics device mode destination as a plugin.
 */

open class FirebaseDestination: DestinationPlugin {
    public let timeline = Timeline()
    public let type = PluginType.destination
    public let key = "firebase"
    public var analytics: Journify? = nil

    private var firebaseOptions: FirebaseOptions? = nil

    public init(firebaseOptions: FirebaseOptions? = nil) {
        self.firebaseOptions = firebaseOptions
    }
    
    open func update(settings: Settings, type: UpdateType) {
        // we've already set up this singleton SDK, can't do it again, so skip.
//        guard type == .initial else { return }
        
        if let firebaseSettings: FirebaseSettings = settings.integrationSettings(forPlugin: self) {
            if let deepLinkURLScheme = firebaseSettings.deepLinkURLScheme {
                FirebaseOptions.defaultOptions()?.deepLinkURLScheme = deepLinkURLScheme
                analytics?.log(message: "Added deepLinkURLScheme: \(deepLinkURLScheme)")
            }
        }
        // First check if firebase has been set up from a previous settings call
        if (FirebaseApp.app() != nil) {
            analytics?.log(message: "Firebase already configured, skipping")
        } else {
            if let options = firebaseOptions {
                FirebaseApp.configure(options: options)
            } else {
                FirebaseApp.configure()
            }
        }
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        
        if let userId = event.userId {
            FirebaseAnalytics.Analytics.setUserID(userId)
            analytics?.log(message: "Firebase setUserId(\(userId))")
        }
        
        // Check the user properties for type
        if let traits = event.traits,
           let mapDictionary = traits.dictionaryValue {
            // Send off to identify
            mapToStrings(mapDictionary) { key, data in
                FirebaseAnalytics.Analytics.setUserProperty(data, forName: key)
                analytics?.log(message: "Firebase setUserPropertyString \(data) for key \(key)")
            }
        }
        
        return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        
        let name = formatFirebaseEventNames(event.event)
        var parameters: [String: Any]? = nil
        if let properties = event.properties?.dictionaryValue {
            parameters = returnMappedFirebaseParameters(properties, for: FirebaseDestination.mappedKeys)
        }

        if let campaign = event.context?.dictionaryValue?["campaign"] as? [String: Any] {
            let campaignParameters = returnMappedFirebaseParameters(campaign, for: FirebaseDestination.campaignMappedKeys)
            parameters = (parameters ?? [:]).merging(campaignParameters) { (current, _) in current }
        }

        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
        analytics?.log(message: "Firebase logEventWithName \(name) parameters \(String(describing: parameters))")
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        
        if let eventName = event.name {
            var parameters: [String: Any] = [FirebaseAnalytics.AnalyticsParameterScreenName: eventName]
            
            if let properties = event.properties?.dictionaryValue {
                let propertiesParameters = returnMappedFirebaseParameters(properties, for: FirebaseDestination.mappedKeys)
                parameters = parameters.merging(propertiesParameters) { (current, _) in current }
            }

            if let campaign = event.context?.dictionaryValue?["campaign"] as? [String: Any] {
                let campaignParameters = returnMappedFirebaseParameters(campaign, for: FirebaseDestination.campaignMappedKeys)
                parameters = parameters.merging(campaignParameters) { (current, _) in current }
            }
            
            FirebaseAnalytics.Analytics.logEvent(FirebaseAnalytics.AnalyticsEventScreenView,
                                                 parameters: parameters)
            analytics?.log(message: "Firebase setScreenName \(eventName)")
        }

        return event
    }
}

// MARK: - Support methods

extension FirebaseDestination {
    
    // Maps Journify spec to Firebase constant
    func formatFirebaseEventNames(_ eventName: String) -> String {
        
        if let mappedEvent = FirebaseDestination.mappedValues[eventName] {
            return mappedEvent
        } else {
            return (try? formatFirebaseName(eventName)) ?? eventName
        }
    }
    
    func formatFirebaseName(_ eventName: String) throws -> String {
        let trimmed = eventName.trimmingCharacters(in: .whitespaces)
        do {
            let regex = try NSRegularExpression(pattern: "([^a-zA-Z0-9_])", options: .caseInsensitive)
            let formattedString = regex.stringByReplacingMatches(in: trimmed, options: .reportProgress, range: NSMakeRange(0, trimmed.count), withTemplate: "_")
            
            // Resize the string to maximum 40 characters if needed
            let range = NSRange(location: 0, length: min(formattedString.count, 40))
            return NSString(string: formattedString).substring(with: range)
        } catch {
            analytics?.log(message: "Could not parse event name for Firebase.")
            throw(error)
        }
    }

    func returnMappedFirebaseParameters(_ properties: [String: Any], for keys: [String: String]) -> [String: Any] {


        var mappedValues = properties

        for (key, firebaseKey) in keys {
            if var data = properties[key] {
                
                mappedValues.removeValue(forKey: key)
                
                if let castData = data as? [String: Any] {
                    data = returnMappedFirebaseParameters(castData, for: keys)
                } else if let castArray = data as? [Any] {
                    var updatedArray = [Any]()
                    for item in castArray {
                        if let castDictionary = item as? [String: Any] {
                            updatedArray.append(returnMappedFirebaseParameters(castDictionary, for: keys))
                        } else {
                            updatedArray.append(item)
                        }
                    }
                    data = updatedArray
                }
                
                // Check key name for proper format
                if let updatedFirebaseKey = try? formatFirebaseName(firebaseKey) {
                    mappedValues[updatedFirebaseKey] = data
                }
            }
        }
        
        return mappedValues
    }
    
    // Makes sure all traits are string based for Firebase API
    func mapToStrings(_ mapDictionary: [String: Any?], finalize: (String, String) -> Void) {
        
        for (key, data) in mapDictionary {

            // Since dictionary values can be Optional we have to unwrap them
            // before encoding so that we don't encode them as "Optional(*)"
            // Note: nil values are NOT encoded.
            if let d = data {
                var dataString = d as? String ?? "\(d)"
                let keyString = key.replacingOccurrences(of: " ", with: "_")
                dataString = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                finalize(keyString, dataString)
            }
        }
    }
}


private struct FirebaseSettings: Codable {
    let deepLinkURLScheme: String?
}

private extension FirebaseDestination {
    
    static let mappedValues = ["Product Clicked": FirebaseAnalytics.AnalyticsEventSelectItem,
                               "Product Viewed": FirebaseAnalytics.AnalyticsEventViewItem,
                               "Product Added": FirebaseAnalytics.AnalyticsEventAddToCart,
                               "Product Removed": FirebaseAnalytics.AnalyticsEventRemoveFromCart,
                               "Checkout Started": FirebaseAnalytics.AnalyticsEventBeginCheckout,
                               "Promotion Viewed": FirebaseAnalytics.AnalyticsEventViewPromotion,
                               "Payment Info Entered": FirebaseAnalytics.AnalyticsEventAddPaymentInfo,
                               "Order Completed": FirebaseAnalytics.AnalyticsEventPurchase,
                               "Order Refunded": FirebaseAnalytics.AnalyticsEventRefund,
                               "Product List Viewed": FirebaseAnalytics.AnalyticsEventViewItemList,
                               "Product Added to Wishlist": FirebaseAnalytics.AnalyticsEventAddToWishlist,
                               "Product Shared": FirebaseAnalytics.AnalyticsEventShare,
                               "Cart Shared": FirebaseAnalytics.AnalyticsEventShare,
                               "Products Searched": FirebaseAnalytics.AnalyticsEventSearch]
    
    static let mappedKeys = ["products": FirebaseAnalytics.AnalyticsParameterItems,
                             "category": FirebaseAnalytics.AnalyticsParameterItemCategory,
                             "product_id": FirebaseAnalytics.AnalyticsParameterItemID,
                             "name": FirebaseAnalytics.AnalyticsParameterItemName,
                             "brand": FirebaseAnalytics.AnalyticsParameterItemBrand,
                             "price": FirebaseAnalytics.AnalyticsParameterPrice,
                             "quantity": FirebaseAnalytics.AnalyticsParameterQuantity,
                             "query": FirebaseAnalytics.AnalyticsParameterSearchTerm,
                             "shipping": FirebaseAnalytics.AnalyticsParameterShipping,
                             "tax": FirebaseAnalytics.AnalyticsParameterTax,
                             "total": FirebaseAnalytics.AnalyticsParameterValue,
                             "revenue": FirebaseAnalytics.AnalyticsParameterValue,
                             "order_id": FirebaseAnalytics.AnalyticsParameterTransactionID,
                             "currency": FirebaseAnalytics.AnalyticsParameterCurrency]
    
    static let campaignMappedKeys = ["source": FirebaseAnalytics.AnalyticsParameterSource,
                                     "medium": FirebaseAnalytics.AnalyticsParameterMedium,
                                     "name": FirebaseAnalytics.AnalyticsParameterCampaign,
                                     "term": FirebaseAnalytics.AnalyticsParameterTerm,
                                     "content": FirebaseAnalytics.AnalyticsParameterContent]
}


extension FirebaseDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}
