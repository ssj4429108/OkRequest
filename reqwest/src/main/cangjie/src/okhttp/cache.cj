/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Cache class.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos_app_cangjie_OkRequest.okio.*
import ohos.hilog.Hilog

let ENTRY_COUNT: Int64 = 2
let ENTRY_METADATA: Int64 = 0
let ENTRY_BODY: Int64 = 1

let CLEAN: String = "CLEAN"
let DIRTY: String = "DIRTY"
let REMOVE: String = "REMOVE"
let READ: String = "READ"
let JOURNAL_FILE: String = "journal"
let JOURNAL_FILE_TEMP: String = "journal.tmp"
let JOURNAL_FILE_BACKUP: String = "journal.bkp"
let VERSION_1: String = "20230228"
let ANY_SEQUENCE_NUMBER = -1
let MAGIC: String = "HTTPCLIENT4CJ"

/** Synthetic response header: the local time when the request was sent. */
let SENT_MILLIS = "Httpclient4cj-Sent-Millis"

/** Synthetic response header: the local time when the response was received. */
let RECEIVED_MILLIS = "Httpclient4cj-Received-Millis"

public class Cache <: Resource {
    let cache: DiskLruCache
    let lock: Monitor = Monitor()
    let cacheDir: String

    private var requestCount: Int64 = 0
    private var hitCount: Int64 = 0
    var writeSuccessCount: Int64 = 0
    private var writeAbortCount: Int64 = 0
    private var networkCount: Int64 = 0

    public init(directoryPath: String, maxSize: Int64) {
        let directory: Directory

        if (!Directory.exists(directoryPath)) {
            directory = Directory.create(directoryPath, recursive: true)
        } else {
            directory = Directory(directoryPath)
        }
        this.cacheDir = directoryPath
        CacheRegister.regDir(cacheDir)
        this.cache = DiskLruCache.create(FileSystem(directory), directory, ENTRY_COUNT, maxSize)
    }

    func trackResponse(cacheStrategy: CacheStrategy) {
        synchronized(lock) {
            requestCount++
            if (has(cacheStrategy.networkRequest)) {
                networkCount++
            } else if (has(cacheStrategy.cacheResponse)) {
                hitCount++
            }
        }
    }

    func update(cached: Response, network: Response): Unit {
        var entry: CacheEntry = CacheEntry(network)
        let snapshot: Snapshot = match (cached.getBody().getOrThrow()) {
            case cacheBody: CacheResponseBody => cacheBody.snapshot
            case _ => throw IllegalArgumentException("response has no cacheBody")
        }
        var editor: Option<Editor> = None
        try {
            editor = snapshot.edit()
            match (editor) {
                case Some(e) =>
                    entry.writeTo(e)
                    e.commit()
                case None => ()
            }
        } catch (e: FSException) {
            abortQuietly(editor)
        }
    }

    private func abortQuietly(editor: Option<Editor>) {
        try {
            match (editor) {
                case Some(e) => e.abort()
                case None => ()
            }
        } catch (ignored: Exception) {}
    }

    func trackConditionalCacheHit() {
        synchronized(lock) {
            hitCount++
        }
    }

    func get(request: Request): Option<Response> {
        let key = key(request.getUrl())
        var snapshot: Snapshot
        var entry: CacheEntry
        try {
            match (cache.get(key)) {
                case None => return Option<Response>.None
                case Some(v) => snapshot = v
            }
        } catch (e: FSException | EOFException) {
            return Option<Response>.None
        }

        try {
            entry = CacheEntry(snapshot.getSource(ENTRY_METADATA))
        } catch (e: FSException | EOFException) {
            Util.closeQuietly(snapshot)
            return Option<Response>.None
        }

        let response: Response = entry.response(snapshot)
        return response
    }

    func put(response: Response): Option<CacheRequest> {
        let requestMethod = response.getRequest().getMethod()
        if (invalidatesCache(requestMethod)) {
            try {
                remove(response.getRequest())
            } catch (ignored: FSException | EOFException) {}
            return None
        }

        if (requestMethod != "GET") {
            // Don't cache non-GET responses. We're technically allowed to cache
            // HEAD requests and some POST requests, but the complexity of doing
            // so is high and the benefit is low.
            return None
        }

        if (HttpHeaderUtils.hasVaryAll(response.getHeaders())) {
            return None
        }

        let entry: CacheEntry = CacheEntry(response)
        var editor: Option<Editor> = Option<Editor>.None

        try {
            editor = cache.edit(key(response.getRequest().getUrl()))
            if (!has(editor)) {
                return None
            }
            let realEditor = editor.getOrThrow()
            entry.writeTo(realEditor)
            return CacheRequest(realEditor, this)
        } catch (e: IOException) {
            try {
                match (editor) {
                    case Some(e) => e.abort()
                    case None => ()
                }
            } catch (e: FSException | EOFException) {
                // ignored
            }
        }

        return Option<CacheRequest>.None
    }

    public static func key(url: URL): String {
        return MD5.digest(url.toString())
    }

    public func getDirectory(): Directory {
        return cache.directory
    }

    func remove(request: Request) {
        cache.remove(key(request.getUrl()))
    }

    public func initialize(): Unit {
        cache.initialize()
    }

    public func delete(): Unit {
        this.close()
        cache.delete()
    }

    public func evictAll(): Unit {
        cache.evictAll()
    }

    public func urls(): Iterator<String> {
        return CacheIterator(this)
    }

    public func flush(): Unit {
Hilog.info(3, "ok-request", "flush1112")
        cache.flush()
    }

    public func close(): Unit {
        cache.close()
        CacheRegister.releaseDir(this.cacheDir)
    }

    public func getSize(): Int64 {
        cache.getSize()
    }

    public func getMaxSize(): Int64 {
        cache.getMaxSize()
    }

    public func isClosed(): Bool {
        cache.isClosed()
    }
}

class CacheIterator <: Iterator<String> {
    let cache: Cache
    let delegate: Iterator<Snapshot>

    init(cache: Cache) {
        this.cache = cache
        this.delegate = cache.cache.snapshots()
    }

    public func next(): Option<String> {
        while (true) {
            match (delegate.next()) {
                case None => return Option<String>.None
                case Some(snapshot) => try {
                    let source = Okio.buffer(snapshot.getSource(ENTRY_METADATA))
                    let str = source.readUtf8LineStrict()
                    snapshot.close()
                    return str
                } catch (e: FSException | EOFException) {
                    return Option<String>.None
                }
            }
        }
        return Option<String>.None
    }

    // public func iterator(): Iterator<String> {
    //     return this
    // }
}

class CacheEntry {
    private let url: String
    private let varyHeaders: Header
    private let requestMethod: String
    private let protocol: Protocol
    private let code: Int64
    private let message: String
    private let responseHeaders: Header
    private let sentRequestMillis: Int64
    private let receivedResponseMillis: Int64

    init(response: Response) {
        this.url = response.getRequest().getUrl().toString()
        this.varyHeaders = HttpHeaderUtils.varyHeaders(response)
        this.requestMethod = response.getRequest().getMethod()
        this.protocol = response.getProtocol()
        this.code = response.getCode()
        this.message = response.getMessage()
        this.responseHeaders = response.getHeaders()
        this.sentRequestMillis = response.getSentRequestAtMillis()
        this.receivedResponseMillis = response.getReceivedResponseAtMillis()
    }

    init(rawSource: Source) {
        let source = Okio.buffer(rawSource)
        try {
            let urlString = source.readUtf8Line()
            url = urlString.getOrThrow()
            requestMethod = source.readUtf8Line().getOrThrow()
            let varyRequestHeaderLineCount: Int64

            try {
                varyRequestHeaderLineCount = Int64.parse(source.readUtf8Line().getOrThrow())
            } catch (e: Exception) {
                throw HttpException(e.message)
            }

            let varyHeader: Header = Header()

            for (_ in 0..varyRequestHeaderLineCount) {
                addLenient(varyHeader, source.readUtf8Line().getOrThrow())
            }

            this.varyHeaders = varyHeader
            let statusLine: StatusLine = StatusLine.parse(source.readUtf8Line().getOrThrow())
            protocol = statusLine.protocol
            code = statusLine.code
            message = statusLine.message
            let responseHeader: Header = Header()
            let responseHeaderLineCount: Int64

            try {
                responseHeaderLineCount = Int64.parse(source.readUtf8Line().getOrThrow())
            } catch (e: Exception) {
                throw HttpException(e.message)
            }

            for (_ in 0..responseHeaderLineCount) {
                addLenient(responseHeader, source.readUtf8Line().getOrThrow())
            }

            let sendRequestMillisString: String = responseHeader.getString(SENT_MILLIS).getOrThrow()
            let receivedResponseMillisString: String = responseHeader.getString(RECEIVED_MILLIS).getOrThrow()
            sentRequestMillis = match (Int64.tryParse(sendRequestMillisString)) {
                case None => 0
                case Some(v) => v
            }

            receivedResponseMillis = match (Int64.tryParse(receivedResponseMillisString)) {
                case None => 0
                case Some(v) => v
            }
            responseHeader.remove(SENT_MILLIS)
            responseHeader.remove(RECEIVED_MILLIS)
            responseHeaders = responseHeader
            //TODO https
        } finally {
            source.close()
        }
    }

    public func response(snapshot: Snapshot): Response {
        let contentType: String = responseHeaders.getString("Content-Type") ?? ""
        let contentLength: String = responseHeaders.getString("Content-Length") ?? ""

        let cacheRequest: Request = Request.builder().url(url).method(requestMethod).header(varyHeaders).build()

        return Response.builder().request(cacheRequest).protocol(protocol).code(code).message(message).header(
            responseHeaders).body(CacheResponseBody(snapshot, contentType, contentLength)).sentRequestAtMillis(
            sentRequestMillis).receivedResponseAtMillis(receivedResponseMillis).build()
    }

    public func writeTo(editor: Editor): Unit {
        let sink = Okio.buffer(editor.newSink(ENTRY_METADATA))
        sink.write(url.toUtf8Array())
        sink.write("\n".toUtf8Array())
        sink.write(requestMethod.toUtf8Array())
        sink.write("\n".toUtf8Array())
        var size = 0
        let list: ArrayList<Byte> = ArrayList<Byte>()
        for ((k, v) in varyHeaders) {
            size++
            list.appendAll(k.toUtf8Array())
            list.appendAll(": ".toUtf8Array())
            list.appendAll(v[0].toUtf8Array())
            list.appendAll("\n".toUtf8Array())
        }
        sink.write("${size}".toUtf8Array())
        sink.write("\n".toUtf8Array())
        sink.write(list.toArray())
        list.clear()
        size = 0

        sink.write("${StatusLine(protocol, code, message)}".toUtf8Array())
        sink.write("\n".toUtf8Array())

        for ((k, v) in responseHeaders) {
            size += v.size
            for (i in 0..v.size) {
                list.appendAll(k.toUtf8Array())
                list.appendAll(": ".toUtf8Array())
                list.appendAll(v[i].toUtf8Array())
                list.appendAll("\n".toUtf8Array())
            }
        }
        sink.write("${size + 2}".toUtf8Array())
        sink.write("\n".toUtf8Array())
        sink.write(list.toArray())
        sink.write(SENT_MILLIS.toUtf8Array())
        sink.write(": ".toUtf8Array())
        sink.write("${sentRequestMillis}".toUtf8Array())
        sink.write("\n".toUtf8Array())
        sink.write(RECEIVED_MILLIS.toUtf8Array())
        sink.write(": ".toUtf8Array())
        sink.write("${receivedResponseMillis}".toUtf8Array())
        sink.write("\n".toUtf8Array())

        //TODO https
        sink.close()
    }
}

class CacheResponseBody <: ResponseBody {
    let snapshot: Snapshot

    init(snapshot: Snapshot, contentType: String, contentLength: String) {
        super(
            contentType,
            match (Int64.tryParse(contentLength)) {
                case Some(v) => v
                case None => -1
            },
            Okio.buffer(snapshot.getSource(ENTRY_BODY))
        )
        this.snapshot = snapshot
    }
}

class CacheRequest <: Sink {
    private let editor: Editor
    private let cache: Cache
    private let cacheOut: Sink
    private var done = false

    init(editor: Editor, cache: Cache) {
        this.editor = editor
        this.cache = cache
        this.cacheOut = editor.newSink(ENTRY_BODY)
    }
    
    public func write(source: Buffer, byteCount: Int64): Unit {
        Hilog.info(3, "ok-request", "write1")
        this.cacheOut.write(source, byteCount)    
    }
    

    public func flush(): Unit {
        Hilog.info(3, "ok-request", "flush1113")
        this.cacheOut.flush()
    }

    public func close(): Unit {
        synchronized(cache.lock) {
            if (done) {
                return
            }
            done = true
            cache.writeSuccessCount++
        }

        cacheOut.close()
        editor.commit()
    }

    public func abort() {
        synchronized(cache.lock) {
            if (done) {
                return
            }
            done = true
            cache.writeSuccessCount++
        }

        cacheOut.close()

        try {
            editor.abort()
        } catch (ignored: IOException | HttpException) {}
    }

    public func toString(): String {
        return "CacheRequest"
    }

    public func isClosed(): Bool {
        return false
    }

    public func timeout(): Timeout {
        return Timeout.NONE
    }
}

class CacheRegister {
    private static let map = HashMap<String, Int64>()
    private static let lock: Monitor = Monitor()
    static func regDir(dir: String): Unit {
        synchronized(lock) {
            if (map.contains(dir)) {
                throw IllegalStateException("cache dir is in use")
            } else {
                map.put(dir, 1)
            }
            // println("regdir ${map[dir]}")
        }
    }
    static func releaseDir(dir: String): Unit {
        synchronized(lock) {
            map.remove(dir)
            // println("releasedir ${count}")
        }
    }
    static func ifSafe(dir: String) {
        synchronized(lock) {
            // if(map.contains(dir)){
            //     println("ifsafe ${map[dir]}")
            // }else{
            //     println("ifsafe 0")
            // }
            return !map.contains(dir)
        }
    }
}
