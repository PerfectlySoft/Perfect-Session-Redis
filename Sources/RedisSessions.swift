//
//  RedisSessions.swift
//  PerfectSessionRedis
//
//  Created by Jonathan Guthrie on 2017-03-05.
//
//

import TurnstileCrypto
import PerfectRedis
import PerfectSession
import PerfectHTTP
import Foundation

public struct RedisSessionConnector {

	public static var host: String		= "127.0.0.1"
	public static var password: String	= ""
	public static var port: Int			= redisDefaultPort

	private init(){}

	public static func connect() -> RedisClientIdentifier {
		return RedisClientIdentifier(withHost: host, port: port, password: password)
	}
}


public struct RedisSessions {


	public func save(session: PerfectSession) {
		var s = session
		s.updated = Int(Date().timeIntervalSince1970)
		RedisClient.getClient(withIdentifier: RedisSessionConnector.connect()) {
			c in
			do {
				let client = try c()
				client.set(key: s.token, value: .string(s.tojson())) {
					response in
					defer {
						RedisClient.releaseClient(client)
					}
//					guard case .simpleString(let _) = response else {
//						return
//					}
				}
			} catch {
				print(error)
			}
		}

//		var s = session
//		s.updated = Int(Date().timeIntervalSince1970)
//		// perform UPDATE
//		let stmt = "UPDATE \(PostgresSessionConnector.table) SET userid = $1, updated = $2, idle = $3, data = $4 WHERE token = $5"
//		exec(stmt, params: [
//			s.userid,
//			s.updated,
//			s.idle,
//			s.tojson(),
//			s.token
//			])
	}

	public func start(_ request: HTTPRequest) -> PerfectSession {
		let rand = URandom()
		var session = PerfectSession()
		session.token = rand.secureToken
		session.data["userid"]		= session.userid
		session.data["created"]		= session.created
		session.data["updated"]		= session.updated
		session.data["idle"]		= SessionConfig.idle
		session.data["ipaddress"]	= request.remoteAddress.host
		session.data["useragent"]	= request.header(.userAgent) ?? "unknown"
		session.setCSRF()

		RedisClient.getClient(withIdentifier: RedisSessionConnector.connect()) {
			c in
			do {
				let client = try c()
				client.set(key: session.token, value: .string(session.tojson())) {
					response in
					defer {
						RedisClient.releaseClient(client)
					}
					guard case .simpleString( _) = response else {
						return
					}
				}
			} catch {
				print(error)
			}
		}
		return session
	}

	/// Deletes the session for a session identifier.
	public func destroy(_ request: HTTPRequest, _ response: HTTPResponse) {
		if let t = request.session?.token {
			RedisClient.getClient(withIdentifier: RedisSessionConnector.connect()) {
				c in
				do {
					let client = try c()
					client.delete(keys: t) {
						response in
						defer {
							RedisClient.releaseClient(client)
						}
					}
				} catch {
					print(error)
				}
			}
		}

		// Reset cookie to make absolutely sure it does not get recreated in some circumstances.
		var domain = ""
		if !SessionConfig.cookieDomain.isEmpty {
			domain = SessionConfig.cookieDomain
		}
		response.addCookie(HTTPCookie(
			name: SessionConfig.name,
			value: "",
			domain: domain,
			expires: .relativeSeconds(SessionConfig.idle),
			path: SessionConfig.cookiePath,
			secure: SessionConfig.cookieSecure,
			httpOnly: SessionConfig.cookieHTTPOnly,
			sameSite: SessionConfig.cookieSameSite
			)
		)

	}

	public func resume(token: String) -> PerfectSession {
		var session = PerfectSession()
		RedisClient.getClient(withIdentifier: RedisSessionConnector.connect()) {
			c in
			do {
				let client = try c()
				client.get(key: token) {
					response in
					defer {
						RedisClient.releaseClient(client)
					}
					guard case .bulkString = response else {
						print("Unexpected response \(response)")
						return
					}
					let data = response.toString()
					do {
						let opts = try data?.jsonDecode() as! [String: Any]
						session.token = token
						session.userid = opts["userid"] as? String ?? ""
						session.created = opts["created"] as? Int ?? 0
						session.updated = opts["updated"] as? Int ?? 0
						session.idle = opts["idle"] as? Int ?? 0
						session.ipaddress = opts["ipaddress"] as? String ?? ""
						session.useragent = opts["useragent"] as? String ?? ""
						session.data = opts
					} catch {
						print("Unexpected json response \(error)")
						return
					}
				}
			} catch {
				print(error)
			}
		}

/*
		client.get(key: key) {
		response in
		defer {
		RedisClient.releaseClient(client)
		expectation.fulfill()
		}
		guard case .bulkString = response else {
		XCTAssert(false, "Unexpected response \(response)")
		return
		}
		let s = response.toString()
		XCTAssert(s == value, "Unexpected response \(response)")
		}

*/

//		let server = connect()
//		let result = server.exec(statement: "SELECT token,userid,created, updated, idle, data, ipaddress, useragent FROM \(PostgresSessionConnector.table) WHERE token = $1", params: [token])
//
//		let num = result.numTuples()
//		for x in 0..<num {
//			session.token = result.getFieldString(tupleIndex: x, fieldIndex: 0) ?? ""
//			session.userid = result.getFieldString(tupleIndex: x, fieldIndex: 1) ?? ""
//			session.created = result.getFieldInt(tupleIndex: x, fieldIndex: 2) ?? 0
//			session.updated = result.getFieldInt(tupleIndex: x, fieldIndex: 3) ?? 0
//			session.idle = result.getFieldInt(tupleIndex: x, fieldIndex: 4) ?? 0
//			if let str = result.getFieldString(tupleIndex: x, fieldIndex: 5) {
//				session.fromjson(str)
//			}
//			session.ipaddress = result.getFieldString(tupleIndex: x, fieldIndex: 6) ?? ""
//			session.useragent = result.getFieldString(tupleIndex: x, fieldIndex: 7) ?? ""
//		}
//		result.clear()
//
//		server.close()
		session._state = "resume"
		return session
	}



	func isError(_ errorMsg: String) -> Bool {
		if errorMsg.contains(string: "ERROR") {
			print(errorMsg)
			return true
		}
		return false
	}
	
}



