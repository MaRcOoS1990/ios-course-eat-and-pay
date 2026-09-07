import CryptoKit
import Foundation

public actor ProductImageLoader {
    public typealias DataLoader = @Sendable (URL) async throws -> Data

    public static let shared = ProductImageLoader()

    private static let cacheLimit = 100
    private let dataLoader: DataLoader
    private let diskCache: ProductImageDiskCache?
    private var cache: [URL: Data] = [:]
    private var cachedURLs: [URL] = []
    private var inFlightTasks: [URL: Task<Data, Error>] = [:]

    private init() {
        dataLoader = Self.loadData
        diskCache = Self.defaultDiskCacheDirectory.map {
            ProductImageDiskCache(directoryURL: $0, cacheLimit: Self.cacheLimit)
        }
    }

    public init(
        cacheDirectory: URL? = nil,
        dataLoader: @escaping DataLoader
    ) {
        self.dataLoader = dataLoader
        diskCache = cacheDirectory.map {
            ProductImageDiskCache(directoryURL: $0, cacheLimit: Self.cacheLimit)
        }
    }

    public func data(for url: URL) async throws -> Data {
        if let data = cache[url] {
            return data
        }

        if let task = inFlightTasks[url] {
            return try await task.value
        }

        let dataLoader = dataLoader
        let diskCache = diskCache
        let task = Task {
            if let diskCache,
               let cachedData = await diskCache.data(for: url) {
                return cachedData
            }

            return try await dataLoader(url)
        }
        inFlightTasks[url] = task

        do {
            let data = try await task.value
            inFlightTasks[url] = nil
            insert(data, for: url)

            if let diskCache {
                await diskCache.insert(data, for: url)
            }

            return data
        } catch {
            inFlightTasks[url] = nil
            throw error
        }
    }

    public func prefetch(_ urls: [URL]) async {
        let uniqueURLs = Array(Set(urls))

        await withTaskGroup(of: Void.self) { group in
            var iterator = uniqueURLs.makeIterator()

            for _ in 0..<min(6, uniqueURLs.count) {
                guard let url = iterator.next() else { break }
                group.addTask {
                    _ = try? await self.data(for: url)
                }
            }

            while await group.next() != nil {
                guard !Task.isCancelled else {
                    group.cancelAll()
                    break
                }

                if let url = iterator.next() {
                    group.addTask {
                        _ = try? await self.data(for: url)
                    }
                }
            }
        }
    }

    public func removeData(for url: URL) async {
        cache[url] = nil
        cachedURLs.removeAll { $0 == url }

        if let diskCache {
            await diskCache.removeData(for: url)
        }
    }

    public func removeAll() async {
        inFlightTasks.values.forEach { $0.cancel() }
        inFlightTasks.removeAll()
        cache.removeAll()
        cachedURLs.removeAll()

        if let diskCache {
            await diskCache.removeAll()
        }
    }

    private func insert(_ data: Data, for url: URL) {
        if cache[url] == nil {
            cachedURLs.append(url)
        }
        cache[url] = data

        while cachedURLs.count > Self.cacheLimit {
            let oldestURL = cachedURLs.removeFirst()
            cache[oldestURL] = nil
        }
    }

    private static var defaultDiskCacheDirectory: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("EatAndPayProductImages", isDirectory: true)
    }

    private static func loadData(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw ProductImageLoadingError.invalidResponse
        }

        guard !data.isEmpty else {
            throw ProductImageLoadingError.emptyData
        }

        return data
    }
}

private actor ProductImageDiskCache {
    private let directoryURL: URL
    private let cacheLimit: Int
    private let fileManager = FileManager.default

    init(directoryURL: URL, cacheLimit: Int) {
        self.directoryURL = directoryURL
        self.cacheLimit = cacheLimit
    }

    func data(for url: URL) -> Data? {
        let cachedFileURL = fileURL(for: url)

        guard
            let data = try? Data(contentsOf: cachedFileURL),
            data.isEmpty == false
        else {
            try? fileManager.removeItem(at: cachedFileURL)
            return nil
        }

        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: cachedFileURL.path
        )
        return data
    }

    func insert(_ data: Data, for url: URL) {
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL(for: url), options: .atomic)
            try trimIfNeeded()
        } catch {
            return
        }
    }

    func removeData(for url: URL) {
        try? fileManager.removeItem(at: fileURL(for: url))
    }

    func removeAll() {
        try? fileManager.removeItem(at: directoryURL)
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let fileName = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL
            .appendingPathComponent(fileName)
            .appendingPathExtension("cache")
    }

    private func trimIfNeeded() throws {
        let resourceKeys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .isRegularFileKey
        ]
        let files = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: .skipsHiddenFiles
        )
        let cachedFiles = files.compactMap { url -> (url: URL, date: Date)? in
            guard
                let values = try? url.resourceValues(forKeys: resourceKeys),
                values.isRegularFile == true
            else {
                return nil
            }

            return (url, values.contentModificationDate ?? .distantPast)
        }
        .sorted { $0.date > $1.date }

        for cachedFile in cachedFiles.dropFirst(cacheLimit) {
            try? fileManager.removeItem(at: cachedFile.url)
        }
    }
}

private enum ProductImageLoadingError: Error {
    case invalidResponse
    case emptyData
}
