import Testing
@testable import MiCoder

@Suite("Git refresh logic")
struct GitRefreshLogicTests {

    @Test("Remote git only when local git failed")
    func remoteOnlyOnLocalFailure() {
        #expect(SessionContextLoader.shouldFetchRemoteGit(localChangeCount: 0, localGitFailed: false) == false)
        #expect(SessionContextLoader.shouldFetchRemoteGit(localChangeCount: 5, localGitFailed: false) == false)
        #expect(SessionContextLoader.shouldFetchRemoteGit(localChangeCount: 0, localGitFailed: true) == true)
    }

    @Test("Coalescer reuses in-flight refresh")
    func coalescerReusesInFlight() async {
        let coalescer = GitRefreshCoalescer()
        var callCount = 0

        async let first: Int = coalescer.run(key: "main") {
            callCount += 1
            try? await Task.sleep(nanoseconds: 50_000_000)
            return callCount
        }
        async let second: Int = coalescer.run(key: "main") {
            callCount += 1
            return callCount
        }

        let results = await [first, second]
        #expect(results[0] == results[1])
        #expect(callCount == 1)
    }

    @Test("Resolves session id for git refresh")
    func resolvesSessionID() {
        #expect(GitRefreshScheduler.resolvedSessionID(explicit: "ses_a", selected: "ses_b") == "ses_a")
        #expect(GitRefreshScheduler.resolvedSessionID(explicit: nil, selected: "ses_b") == "ses_b")
        #expect(GitRefreshScheduler.resolvedSessionID(explicit: "", selected: "") == nil)
    }
}
