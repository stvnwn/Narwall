import Foundation

class Unsplash {
    private let location = "https://api.unsplash.com"
    var applicationName: String
    var applicationId: String
    
    init(applicationName: String, applicationId: String) {
        self.applicationName = applicationName
        self.applicationId = applicationId
    }
    
    func getPhoto(_ id: String?, then callback: @escaping (() throws -> Photo) -> Void) {
        var endpointUrl = URLComponents(string: location + "/photos")!
        
        if let id = id {
            endpointUrl.path += "/\(id)"
        } else {
            endpointUrl.path += "/random"
        }
        
        var request = URLRequest(url: endpointUrl.url!)
        request.setValue("Client-ID \(applicationId)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let jsonDecoder = JSONDecoder()
            if let data = data {
                if var photo = try? jsonDecoder.decode(Photo.self, from: data) {
                    photo.photographerProfile = URL(string: "\(photo.photographerProfile.absoluteString)?utm_source=\(self.applicationName)&utm_medium=referral")!
                    callback({return photo})
                } else {
                    callback({throw UnsplashError.rateLimitExceeded})
                }
            } else {
                callback({throw UnsplashError.offlineInternetConnection})
            }
        }
        task.resume()
    }
    
    struct Photo: Decodable {
        var id: String
        var thumbnail: URL
        var rawImage: URL
        var downloadLocation: URL
        var photographerName: String
        var photographerProfile: URL
        
        private enum CodingKeys: String, CodingKey {
            case id
            case urls
            case links
            case photographer = "user"
        }
        
        private struct PhotoURLs: Decodable {
            let thumbnail: URL
            let rawImage: URL
            
            enum CodingKeys: String, CodingKey {
                case thumbnail = "thumb"
                case rawImage = "raw"
            }
        }
        
        private struct PhotoLinks: Decodable {
            let downloadLocation: URL
            
            enum CodingKeys: String, CodingKey {
                case downloadLocation = "download_location"
            }
        }
        
        private struct Photographer: Decodable {
            let name: String
            let links: PhotographerLinks
            
            enum CodingKeys: String, CodingKey {
                case name
                case links
            }
            
            struct PhotographerLinks: Decodable {
                let profile: String
                
                enum CodingKeys: String, CodingKey {
                    case profile = "html"
                }
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.id = try container.decode(String.self, forKey: .id)
            
            let photoURLs = try container.nestedContainer(keyedBy: PhotoURLs.CodingKeys.self, forKey: .urls)
            self.thumbnail = try photoURLs.decode(URL.self, forKey: .thumbnail)
            self.rawImage = try photoURLs.decode(URL.self, forKey: .rawImage)
            
            let photoLinks = try container.nestedContainer(keyedBy: PhotoLinks.CodingKeys.self, forKey: .links)
            self.downloadLocation = try photoLinks.decode(URL.self, forKey: .downloadLocation)
            
            let photographer = try container.nestedContainer(keyedBy: Photographer.CodingKeys.self, forKey: .photographer)
            self.photographerName = try photographer.decode(String.self, forKey: .name)
            
            let photographerLinks = try photographer.nestedContainer(keyedBy: Photographer.PhotographerLinks.CodingKeys.self, forKey: .links)
            self.photographerProfile = try photographerLinks.decode(URL.self, forKey: .profile)
        }
    }
    
    enum UnsplashError: Error {
        case offlineInternetConnection
        case rateLimitExceeded
    }
}
