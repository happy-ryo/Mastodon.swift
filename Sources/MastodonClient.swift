import Foundation
import Alamofire
import Moya
import RxSwift
import RxMoya
import MoyaGloss
import RxMoyaGloss

public typealias Scope = String
public typealias Scopes = [Scope]

public class MastodonClient {
    
    public init(plugins: [PluginType]? = nil) {
        
        guard let _ = plugins else {
            return
        }
        
        self.plugins.append(contentsOf: plugins!)
    }
    
    public var plugins = [PluginType]()
    
    public func createApp(_ name: String,
                          redirectUri: String = "urn:ietf:wg:oauth:2.0:oob",
                          scopes: Scopes,
                          url: URL,
                          endpointClosure: @escaping MoyaProvider<Mastodon.Apps>.EndpointClosure = MoyaProvider.defaultEndpointMapping) -> Observable<App> {
        return RxMoyaProvider<Mastodon.Apps>(endpointClosure: endpointClosure, plugins: plugins)
            .request(.register(
                name,
                redirectUri,
                scopes.reduce("") { $0 == "" ? $1 : $0 + " " + $1},
                url.absoluteString
                ))
            .mapObject(type: App.self)
    }
    
    public func getToken(_ app: App,
                         username: String,
                         password: String,
                         scope: Scopes,
                         endpointClosure: @escaping MoyaProvider<Mastodon.OAuth>.EndpointClosure = MoyaProvider.defaultEndpointMapping) -> Observable<AccessToken> {
        return RxMoyaProvider<Mastodon.OAuth>(endpointClosure: endpointClosure, plugins: plugins)
            .request(.authenticate(app, username, password, scope.reduce("") { $0 == "" ? $1 : $0 + " " + $1}))
            .mapObject(type: AccessToken.self)
    }

    public func getHomeTimeline(_ token: String,
                                maxId: StatusId? = nil,
                                sinceId: StatusId? = nil,
                                endpointClosure: @escaping MoyaProvider<Mastodon.Timelines>.EndpointClosure = MoyaProvider.defaultEndpointMapping) -> Observable<[Status]> {
        let accessToken = AccessTokenPlugin(token: token)
        return RxMoyaProvider<Mastodon.Timelines>(
                endpointClosure: endpointClosure,
                plugins: [plugins, [accessToken]].flatMap { $0 }
            )
            .request(.home(maxId, sinceId))
            .mapArray(type: Status.self)
    }

    public func getPublicTimeline(_ token: String,
                                  isLocal: Bool = false,
                                  maxId: StatusId? = nil,
                                  sinceId: StatusId? = nil,
                                  endpointClosure: @escaping MoyaProvider<Mastodon.Timelines>.EndpointClosure = MoyaProvider.defaultEndpointMapping) -> Observable<[Status]> {
        let accessToken = AccessTokenPlugin(token: token)
        return RxMoyaProvider<Mastodon.Timelines>(
                endpointClosure: endpointClosure,
                plugins: [plugins, [accessToken]].flatMap { $0 }
            )
            .request(.pub(isLocal, maxId, sinceId))
            .mapArray(type: Status.self)
    }

    public func getTagTimeline(_ token: String,
                               tag: String,
                               isLocal: Bool = false,
                               maxId: StatusId? = nil,
                               sinceId: StatusId? = nil,
                               endpointClosure: @escaping MoyaProvider<Mastodon.Timelines>.EndpointClosure = MoyaProvider.defaultEndpointMapping) -> Observable<[Status]> {
        let accessToken = AccessTokenPlugin(token: token)
        return RxMoyaProvider<Mastodon.Timelines>(
                endpointClosure: endpointClosure,
                plugins: [plugins, [accessToken]].flatMap { $0 }
            )
            .request(.tag(tag, isLocal, maxId, sinceId))
            .mapArray(type: Status.self)
    }
}
