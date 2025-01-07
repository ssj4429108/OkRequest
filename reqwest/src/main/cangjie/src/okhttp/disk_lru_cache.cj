/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CallServerInterceptor class.
 */

package ohos_app_cangjie_OkRequest.okhttp

class DiskLruCache {
    let fileSystem: FileSystem
    var directory: Directory
    var valueCount: Int64
    var maxSize: Int64
    var size: Int64 = 0
    var initialized: Bool = false
    let lock: Monitor = Monitor()
    var closed: Bool = false

    static let LEGAL_KEY_PATTERN: String = "[a-z0-9_-]{1,120}"
    let lruEntries: HashMap<String, Entry> = HashMap<String, Entry>()
    var journalWriter: Option<Sink> = Option<Sink>.None
    var redundantOpCount: Int64 = 0
    var hasJournalErrors: Bool = false
    var mostRecentTrimFailed: Bool = false
    var mostRecentRebuildFailed: Bool = false
    var nextSequenceNumber = 0

    init(fileSystem: FileSystem, directory: Directory, valueCount: Int64, maxSize: Int64) {
        this.fileSystem = fileSystem
        this.directory = directory
        this.valueCount = valueCount
        this.maxSize = maxSize
    }

    static func create(
        fileSystem: FileSystem,
        directory: Directory,
        valueCount: Int64,
        maxSize: Int64
    ): DiskLruCache {
        if (maxSize <= 0) {
            throw IllegalArgumentException("maxSize <= 0")
        }

        if (valueCount <= 0) {
            throw IllegalArgumentException("valueCount <= 0")
        }

        return DiskLruCache(fileSystem, directory, valueCount, maxSize)
    }

    public func remove(key: String): Bool {
        synchronized(lock) {
            initialize()
            checkNotClosed()
            validateKey(key)

            match (lruEntries.get(key)) {
                case Some(e) =>
                    let removed = removeEntry(e)

                    if (removed && size <= maxSize) {
                        mostRecentTrimFailed = false
                    }

                    return removed
                case None => return false
            }
        }
    }

    public func get(key: String): Option<Snapshot> {
        synchronized(lock) {
            initialize()
            checkNotClosed()
            validateKey(key)
            match (lruEntries.get(key)) {
                case None => return None
                case Some(entry) => if (!entry.readable) {
                    return None
                }
            }

            match (lruEntries[key].snapshot()) {
                case None => return Option<Snapshot>.None
                case Some(v) =>
                    redundantOpCount++
                    let jw = journalWriter.getOrThrow()
                    jw.write(READ.toUtf8Array())
                    jw.write(" ".toUtf8Array())
                    jw.write(key.toUtf8Array())
                    jw.write("\n".toUtf8Array())
                    if (journalRebuildRequired()) {
                        cleanUp()
                    }
                    return v
            }
        }
    }

    public func edit(key: String): Option<Editor> {
        return edit(key, ANY_SEQUENCE_NUMBER)
    }

    func edit(key: String, expectedSequenceNumber: Int64): Option<Editor> {
        synchronized(lock) {
            initialize()
            checkNotClosed()
            validateKey(key)
            var entry: Option<Entry> = lruEntries.get(key)
            if (expectedSequenceNumber != ANY_SEQUENCE_NUMBER && (!has(entry) || entry.getOrThrow().sequenceNumber !=
                expectedSequenceNumber)) {
                return None
            }

            if (has(entry) && has(entry.getOrThrow().currentEditor)) {
                return None
            }

            if (mostRecentTrimFailed || mostRecentRebuildFailed) {
                cleanUp()
                return None
            }
            let jw = journalWriter.getOrThrow()
            jw.write(DIRTY.toUtf8Array())
            jw.write(" ".toUtf8Array())
            jw.write(key.toUtf8Array())
            jw.write("\n".toUtf8Array())
            jw.flush()

            if (hasJournalErrors) {
                return None
            }

            if (!has(entry)) {
                let e = Entry(key, this)
                lruEntries.put(key, e)
                entry = e
            }

            let editor = Editor(entry.getOrThrow(), this)
            entry.getOrThrow().currentEditor = editor
            return editor
        }
    }

    func cleanUp(): Unit {
        synchronized(lock) {
            if (!initialized || closed) {
                return
                // Nothing to do
            }

            try {
                trimToSize()
            } catch (e: Exception) {
                mostRecentTrimFailed = true
            }

            try {
                if (journalRebuildRequired()) {
                    rebuildJournal()
                    redundantOpCount = 0
                }
            } catch (e: IOException) {
                mostRecentRebuildFailed = true
                journalWriter = RealBufferSink(BlackHole())
            }
        }
    }

    func journalRebuildRequired() {
        let redundantOpCompactThreshold = 2000
        return redundantOpCount >= redundantOpCompactThreshold && redundantOpCount >= lruEntries.size
    }

    func removeEntry(entry: Entry): Bool {
        match (entry.currentEditor) {
            case Some(ce) => ce.detach()
            case None => ()
        }

        for (i in 0..valueCount) {
            fileSystem.delete(entry.cleanFiles[i])
            size -= entry.lengths[i]
            entry.lengths[i] = 0
        }

        redundantOpCount++
        let jw = journalWriter.getOrThrow()
        jw.write(REMOVE.toUtf8Array())
        jw.write(" ".toUtf8Array())
        jw.write(entry.key.toUtf8Array())
        jw.write("\n".toUtf8Array())
        lruEntries.remove(entry.key)

        if (journalRebuildRequired()) {
            cleanUp()
        }

        return true
    }

    private func validateKey(_: String): Unit {
        /* let matcher: Matcher = Regex(LEGAL_KEY_PATTERN).matcher(key)
           match (matcher.find()) {
           case None =>
               throw IllegalArgumentException("keys must match regex [a-z0-9_-]{1,120}: ${key}")
           case Some(data) =>
               ()
           }*/
    }

    private func checkNotClosed(): Unit {
        synchronized(lock) {
            if (isClosed()) {
                throw IllegalStateException("cache is closed")
            }
        }
    }

    public func isClosed(): Bool {
        synchronized(lock) {
            return closed
        }
    }

    func trimToSize(): Unit {
        while (size > maxSize) {
            let toEvict: Entry = lruEntries.values().iterator().next().getOrThrow()
            removeEntry(toEvict)
        }

        mostRecentTrimFailed = false
    }

    public func initialize(): Unit {
        synchronized(lock) {
            if (initialized) {
                return
                // Already initialized.
            }

            // If a bkp file exists, use it instead.
            if (fileSystem.exists(JOURNAL_FILE_BACKUP)) {
                if (fileSystem.exists(JOURNAL_FILE_BACKUP)) {
                    fileSystem.delete(JOURNAL_FILE_BACKUP)
                } else {
                    fileSystem.rename(JOURNAL_FILE_BACKUP, JOURNAL_FILE)
                }
            }

            // Prefer to pick up where we left off.
            if (fileSystem.exists(JOURNAL_FILE)) {
                try {
                    readJournal()
                    processJournal()
                    initialized = true
                    return
                } catch (e: FSException | HttpException | EOFException) {}

                try {
                    delete()
                } finally {
                    closed = false
                }
            }

            rebuildJournal()
            initialized = true
        }
    }

    public func delete() {
        fileSystem.deleteContents(directory)
    }

    public func close(): Unit {
        if (closed) {
            return
        }
        if (initialized) {
            for (entry in lruEntries.values() |> collectArray) {
                match (entry.currentEditor) {
                    case None => ()
                    case Some(ce) => ce.abort()
                }
            }

            trimToSize()
            journalWriter.getOrThrow().close()
            journalWriter = None
            fileSystem.close()
        }
        closed = true
    }

    private func processJournal(): Unit {
        fileSystem.delete(JOURNAL_FILE_TEMP)
        let arr = ArrayList<String>()
        for (key in lruEntries.keys()) {
            let entry = lruEntries[key]
            match (entry.currentEditor) {
                case None => for (i in 0..valueCount) {
                    size += entry.lengths[i]
                }
                case Some(_) =>
                    entry.currentEditor = None
                    for (i in 0..valueCount) {
                        fileSystem.delete(entry.cleanFiles[i])
                        fileSystem.delete(entry.dirtyFiles[i])
                    }
                    arr.append(key)
            }
        }
        lruEntries.removeAll(arr)
    }

    private func readJournal() {
        try (source = fileSystem.source(JOURNAL_FILE)) {
            let magic = source.readUtf8Line()
            let version = source.readUtf8Line()
            let valueCountString = source.readUtf8Line()
            let blank = source.readUtf8Line()

            if (!MAGIC.equals(magic) || !VERSION_1.equals(version) || !"${valueCount}".equals(valueCountString) ||
                !"".equals(blank)) {
                throw HttpException("unexpected journal header: [${magic},${version},${valueCountString},${blank}")
            }

            var lineCount = 0
            let content = StringBuilder("${magic}\n${version}\n${valueCountString}\n\n")
            while (true) {
                try {
                    let s = source.readUtf8Line()
                    content.append(s)
                    content.append("\n")
                    readJournalLine(s)
                    lineCount++
                } catch (endOfJournal: EOFException) {
                    break
                }
            }
            redundantOpCount = lineCount - lruEntries.size
            if (!source.exhausted()) {
                rebuildJournal()
            } else {
                journalWriter = newJournalWriter()
            }
        }
    }

    private func newJournalWriter(): RealBufferSink {
        return RealBufferSink(fileSystem.appendingSink(JOURNAL_FILE))
    }

    func rebuildJournal(): Unit {
        match (journalWriter) {
            case Some(rj) => rj.close()
            case None => ()
        }

        synchronized(lock) {
            match (journalWriter) {
                case Some(jw) => jw.close()
                case None => ()
            }

            let writer = RealBufferSink(fileSystem.sink(JOURNAL_FILE_TEMP))

            try {
                writer.write(MAGIC.toUtf8Array())
                writer.write("\n".toUtf8Array())
                writer.write(VERSION_1.toUtf8Array())
                writer.write("\n".toUtf8Array())
                writer.write("${valueCount}".toUtf8Array())
                writer.write("\n".toUtf8Array())
                writer.write("\n".toUtf8Array())
                for (entry in lruEntries.values()) {
                    match (entry.currentEditor) {
                        case Some(_) =>
                            writer.write((DIRTY + " ").toUtf8Array())
                            writer.write(entry.key.toUtf8Array())
                            writer.write("\n".toUtf8Array())
                        case None =>
                            writer.write((CLEAN + " ").toUtf8Array())
                            writer.write(entry.key.toUtf8Array())
                            entry.writeLengths(writer)
                            writer.write("\n".toUtf8Array())
                    }
                }
            } finally {
                writer.close()
            }

            if (fileSystem.exists(JOURNAL_FILE)) {
                fileSystem.rename(JOURNAL_FILE, JOURNAL_FILE_BACKUP)
            }

            fileSystem.rename(JOURNAL_FILE_TEMP, JOURNAL_FILE)
            fileSystem.delete(JOURNAL_FILE_BACKUP)
            journalWriter = newJournalWriter()
            hasJournalErrors = false
            mostRecentRebuildFailed = false
        }
    }

    private func readJournalLine(line: String): Unit {
        let firstSpace = line.indexOf(' ').getOrThrow({=> HttpException("unexpected journal line: ${line}")})
        let keyBegin = firstSpace + 1
        let key: String
        let secondSpace = match (line.indexOf(' ', keyBegin)) {
            case Some(index) =>
                key = line[(keyBegin..index)]
                index
            case None =>
                key = line.substring(keyBegin, line.size - keyBegin)
                if (firstSpace == REMOVE.size && line.startsWith(REMOVE)) {
                    lruEntries.remove(key)
                    return
                }

                -1
        }

        var entry: Entry = match (lruEntries.get(key)) {
            case Some(e) => e
            case None =>
                let e = Entry(key, this)
                lruEntries.put(key, e)
                e
        }
        if (secondSpace != -1 && firstSpace == CLEAN.size && line.startsWith(CLEAN)) {
            let parts: Array<String> = line.substring(secondSpace + 1).split(" ")
            entry.readable = true
            entry.currentEditor = None
            entry.setLengths(parts)
        } else if (secondSpace == -1 && firstSpace == DIRTY.size && line.startsWith(DIRTY)) {
            entry.currentEditor = Editor(entry, this)
        } else if (secondSpace == -1 && firstSpace == READ.size && line.startsWith(READ)) {
            // This work was already done by calling lruEntries.get().
        } else {
            throw HttpException("unexpected journal line: ${line}")
        }
    }

    func flush(): Unit {
        synchronized(lock) {
            if (!initialized) {
                return
            }

            checkNotClosed()
            trimToSize()
            journalWriter.getOrThrow().flush()
        }
    }

    func evictAll() {
        synchronized(lock) {
            initialize()
            let arr: ArrayList<Entry> = ArrayList<Entry>()

            //Copying for safe iteration. resolve ConcurrentModificationException
            for ((_, v) in lruEntries) {
                arr.append(v)
            }

            for (i in 0..arr.size) {
                removeEntry(arr[i])
            }
        }

        mostRecentTrimFailed = false
    }

    func snapshots(): Iterator<Snapshot> {
        synchronized(lock) {
            initialize()
            return SnapshotIterator(this)
        }
    }

    func getSize() {
        synchronized(lock) {
            initialize()
            return size
        }
    }

    func getMaxSize() {
        synchronized(lock) {
            return maxSize
        }
    }
}

class SnapshotIterator <: Iterator<Snapshot> {
    let delegate: Iterator<Entry>
    let diskLruCache: DiskLruCache
    init(diskLruCache: DiskLruCache) {
        this.diskLruCache = diskLruCache
        this.delegate = (diskLruCache.lruEntries.values() |> collectArray).iterator()
    }

    public func next(): Option<Snapshot> {
        synchronized(diskLruCache.lock) {
            if (diskLruCache.closed) {
                return Option<Snapshot>.None
            }

            while (true) {
                let snapshot: Option<Snapshot> = match (delegate.next()) {
                    case None => break
                    case Some(entry) =>
                        if (!entry.readable) {
                            continue
                        }
                        entry.snapshot()
                }

                match (snapshot) {
                    case None => continue
                    case Some(s) => return s
                }
            }
        }
        return Option<Snapshot>.None
    }

    // public func iterator(): Iterator<Snapshot> {
    //     return this
    // }
}

class Editor {
    let entry: Entry
    let written: Option<Array<Bool>>
    private var done: Bool = false
    let diskLruCache: DiskLruCache
    let lock: Monitor = Monitor()

    init(entry: Entry, diskLruCache: DiskLruCache) {
        this.entry = entry
        this.diskLruCache = diskLruCache
        this.written = if (!entry.readable) {
            Array<Bool>(diskLruCache.valueCount, item: false)
        } else {
            Option<Array<Bool>>.None
        }
    }

    func detach(): Unit {
        if (refEq(entry.currentEditor.getOrThrow(), this)) {
            for (i in 0..diskLruCache.valueCount) {
                try {
                    diskLruCache.fileSystem.delete(entry.dirtyFiles[i])
                } catch (e: IOException) {
                    // This file is potentially leaked. Not much we can do about that
                }
            }
            entry.currentEditor = None
        }
    }

    public func newSink(index: Int64): Sink {
        synchronized(diskLruCache.lock) {
            if (done) {
                throw IllegalStateException("has done")
            }

            if (!refEq(entry.currentEditor.getOrThrow(), this)) {
                return BlackHole()
            }

            if (!entry.readable) {
                written.getOrThrow()[index] = true
            }

            let dirtyFile = entry.dirtyFiles[index]
            let sink: Sink
            try {
                sink = diskLruCache.fileSystem.sink(dirtyFile)
            } catch (e: FSException) {
                return BlackHole()
            }

            return FaultHidingSink(sink, this)
        }
    }

    func completeEdit(editor: Editor, success: Bool): Unit {
        synchronized(lock) {
            let entry = editor.entry
            if (!refEq(entry.currentEditor.getOrThrow(), editor)) {
                throw IllegalStateException("editor is others")
            }

            // If this edit is creating the entry for the first time, every index must have a value.
            if (success && !entry.readable) {
                for (i in 0..diskLruCache.valueCount) {
                    if (!editor.written.getOrThrow()[i]) {
                        editor.abort()
                        throw IllegalStateException("Newly created entry didn't create value for index ${i}")
                    }
                    if (!diskLruCache.fileSystem.exists(entry.dirtyFiles[i])) {
                        editor.abort()
                        return ()
                    }
                }
            }

            for (i in 0..diskLruCache.valueCount) {
                let dirty = entry.dirtyFiles[i]
                if (success) {
                    if (diskLruCache.fileSystem.exists(dirty)) {
                        let clean = entry.cleanFiles[i]
                        diskLruCache.fileSystem.rename(dirty, clean)
                        let oldLength = entry.lengths[i]
                        let newLength = diskLruCache.fileSystem.size(clean)
                        entry.lengths[i] = newLength
                        diskLruCache.size = diskLruCache.size - oldLength + newLength
                    }
                } else {
                    diskLruCache.fileSystem.delete(dirty)
                }
            }

            diskLruCache.redundantOpCount++
            entry.currentEditor = None
            let jw = diskLruCache.journalWriter.getOrThrow()
            if (entry.readable || success) {
                entry.readable = true
                jw.write(CLEAN.toUtf8Array())
                jw.write(" ".toUtf8Array())
                jw.write(entry.key.toUtf8Array())
                entry.writeLengths(jw)
                jw.write("\n".toUtf8Array())
                if (success) {
                    entry.sequenceNumber = diskLruCache.nextSequenceNumber
                    diskLruCache.nextSequenceNumber++
                }
            } else {
                diskLruCache.lruEntries.remove(entry.key)
                jw.write(REMOVE.toUtf8Array())
                jw.write(" ".toUtf8Array())
                jw.write(entry.key.toUtf8Array())
                jw.write("\n".toUtf8Array())
            }

            jw.flush()

            if (diskLruCache.size > diskLruCache.maxSize || diskLruCache.journalRebuildRequired()) {
                diskLruCache.cleanUp()
            }
        }
    }

    public func abort(): Unit {
        synchronized(diskLruCache.lock) {
            if (done) {
                throw IllegalStateException("abort has done")
            }

            if (refEq(entry.currentEditor.getOrThrow(), this)) {
                completeEdit(this, false)
            }

            done = true
        }
    }

    public func commit() {
        synchronized(diskLruCache.lock) {
            if (done) {
                throw IllegalStateException("can not commit editor now, because it has been done")
            }

            if (refEq(this, entry.currentEditor.getOrThrow())) {
                completeEdit(this, true)
            }

            done = true
        }
    }
}

class Entry {
    let key: String
    var currentEditor: Option<Editor> = None
    let lengths: Array<Int64>
    let cleanFiles: Array<String>
    let dirtyFiles: Array<String>
    var readable: Bool = false
    var sequenceNumber: Int64 = 0
    let diskLruCache: DiskLruCache

    init(key: String, diskLruCache: DiskLruCache) {
        this.key = key
        this.diskLruCache = diskLruCache
        lengths = Array<Int64>(diskLruCache.valueCount, item: 0)
        cleanFiles = Array<String>(diskLruCache.valueCount, item: "")
        dirtyFiles = Array<String>(diskLruCache.valueCount, item: "")
        var sb = StringBuilder("${key}.")
        let truncateTo = sb.size
        for (i in 0..diskLruCache.valueCount) {
            sb.append(i)
            cleanFiles[i] = "${sb}"
            sb.append(".tmp")
            dirtyFiles[i] = "${sb}"
            sb = StringBuilder("${sb}".substring(0, truncateTo))
        }
    }

    func snapshot(): Option<Snapshot> {
        let cl = lengths.clone()
        let arr: ArrayList<OkBuffer> = ArrayList<OkBuffer>()
        try {
            for (i in 0..diskLruCache.valueCount) {
                arr.append(diskLruCache.fileSystem.source(cleanFiles[i]))
            }
            return Snapshot(key, sequenceNumber, arr.toArray(), cl, diskLruCache)
        } catch (e: FSException) {
            for (i in 0..diskLruCache.valueCount) {
                if (i < arr.size) {
                    Util.closeQuietly(arr[i])
                } else {
                    break
                }
            }

            diskLruCache.removeEntry(this)
        }
        return None
    }

    func setLengths(strings: Array<String>) {
        if (strings.size != diskLruCache.valueCount) {
            throw HttpException("unexpected journal line: ${strings}")
        }

        try {
            for (i in 0..strings.size) {
                lengths[i] = Int64.parse(strings[i])
            }
        } catch (e: Exception) {
            throw HttpException("unexpected journal line: ${strings}")
        }
    }

    func writeLengths(writer: Sink): Unit {
        for (i in 0..lengths.size) {
            writer.write(" ".toUtf8Array())
            writer.write("${lengths[i]}".toUtf8Array())
        }
    }
}

class Snapshot <: Resource {
    private let key: String
    private let sequenceNumber: Int64
    private let sources: Array<OkBuffer>
    private let lengths: Array<Int64>
    private let diskLruCache: DiskLruCache

    init(
        key: String,
        sequenceNumber: Int64,
        sources: Array<OkBuffer>,
        lengths: Array<Int64>,
        diskLruCache: DiskLruCache
    ) {
        this.diskLruCache = diskLruCache
        this.key = key
        this.sequenceNumber = sequenceNumber
        this.sources = sources
        this.lengths = lengths
    }

    public func getSource(index: Int64): OkBuffer {
        return sources[index]
    }

    public func edit(): Option<Editor> {
        return diskLruCache.edit(key, sequenceNumber)
    }

    public func isClosed() {
        return sources.size == 0
    }

    public func close() {
        for (i in 0..sources.size) {
            Util.closeQuietly(sources[i])
        }
    }
}

class FileSystem {
    var directory: Directory
    let closeFuncs = ArrayList<() -> Unit>()

    init(directory: Directory) {
        this.directory = directory
    }

    public func source(name: String): OkBuffer {
        let file = File(directory.info.path.join(name), Open(true, true))
        closeFuncs.append({=> file.close()})
        return OkBuffer(file)
    }

    public func sink(name: String): Sink {
        let file = directory.createFile(name)
        closeFuncs.append({=> file.close()})
        return FileSink(file)
    }

    public func appendingSink(name: String): Sink {
        let file = File(directory.info.path.join(name), Append)
        closeFuncs.append({=> file.close()})
        return FileSink(file)
    }

    func close(): Unit {
        closeFuncs |> forEach {f: () -> Unit => f()}
        closeFuncs.clear()
    }

    public func delete(name: String): Unit {
        if (exists(name)) {
            File.delete(directory.info.path.join(name))
        }
    }

    public func exists(name: String): Bool {
        File.exists(directory.info.path.join(name))
    }

    public func rename(f: String, t: String): Unit {
        File.move(directory.info.path.join(f), directory.info.path.join(t), true)
    }

    public func deleteContents(directory: Directory): Unit {
        deleteRecursive(directory)
    }

    private func deleteRecursive(directory: Directory): Unit {
        for (i in directory) {
            if (i.isFile()) {
                File.delete(i.path)
            } else if (i.isDirectory()) {
                deleteRecursive(Directory(i.path))
            }
        }
    }

    public func size(name: String): Int64 {
        return FileInfo(directory.info.path.join(name)).length
    }
}
