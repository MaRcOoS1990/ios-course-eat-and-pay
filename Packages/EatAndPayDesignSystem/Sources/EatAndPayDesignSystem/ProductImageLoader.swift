import Foundation

public actor ProductImageLoader {
    public typealias DataLoader = @Sendable (URL) async throws -> Data

    public static let shared = ProductImageLoader()

    private let cacheLimit = 100
    private let dataLoader: DataLoader
    private var cache: [URL: Data] = [:]
    private var cachedURLs: [URL] = []
    private var inFlightTasks: [URL: Task<Data, Error>] = [:]

    private init() {
        dataLoader = Self.loadData
    }

    public init(dataLoader: @escaping DataLoader) {
        self.dataLoader = dataLoader
    }

    public func data(for url: URL) async throws -> Data {
        if let data = cache[url] {
            return data
        }

        if let task = inFlightTasks[url] {
            return try await task.value
        }

        let dataLoader = dataLoader
        let task = Task {
            try await dataLoader(url)
        }
        inFlightTasks[url] = task

        do {
            let data = try await task.value
            inFlightTasks[url] = nil
            insert(data, for: url)
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

    public func removeData(for url: URL) {
        cache[url] = nil
        cachedURLs.removeAll { $0 == url }
    }

    public func removeAll() {
        inFlightTasks.values.forEach { $0.cancel() }
        inFlightTasks.removeAll()
        cache.removeAll()
        cachedURLs.removeAll()
    }

    private func insert(_ data: Data, for url: URL) {
        if cache[url] == nil {
            cachedURLs.append(url)
        }
        cache[url] = data

        while cachedURLs.count > cacheLimit {
            let oldestURL = cachedURLs.removeFirst()
            cache[oldestURL] = nil
        }
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

private enum ProductImageLoadingError: Error {
    case invalidResponse
    case emptyData
}
